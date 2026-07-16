begin;

-- =========================================================
-- 1. GET MY QUIZ HISTORY
-- =========================================================

create or replace function public.get_my_quiz_history(
  p_limit integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_attempts jsonb;
  v_total_count integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_limit is null
     or p_limit < 1
     or p_limit > 100 then
    raise exception using
      errcode = '22023',
      message =
        'limit must be between 1 and 100.';
  end if;

  select count(*)::integer
  into v_total_count
  from public.quiz_attempts as attempt
  where attempt.user_id = v_user_id;

  with selected_attempts as (
    select
      attempt.id,
      attempt.topic_id,
      attempt.topic_code,
      attempt.topic_title,
      attempt.mode,
      attempt.question_count,
      attempt.correct_answers,
      attempt.answered_questions,
      attempt.elapsed_seconds,
      attempt.earned_xp,
      attempt.auto_submitted,
      attempt.completed_at

    from public.quiz_attempts as attempt

    where attempt.user_id = v_user_id

    order by
      attempt.completed_at desc,
      attempt.id desc

    limit p_limit
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'schemaVersion',
        1,

        'id',
        selected_attempt.id,

        'completedAt',
        selected_attempt.completed_at,

        'earnedXp',
        selected_attempt.earned_xp,

        'result',
        jsonb_build_object(
          'topicId',
          selected_attempt.topic_id,

          'topicCode',
          selected_attempt.topic_code,

          'topicTitle',
          selected_attempt.topic_title,

          'mode',
          selected_attempt.mode,

          'questions',
          (
            select coalesce(
              jsonb_agg(
                coalesce(
                  attempt_item.question_snapshot,
                  '{}'::jsonb
                )
                ||
                jsonb_build_object(
                  'correctOptionIndex',
                  attempt_item.correct_option_index,

                  'shuffleOptions',
                  false
                )
                order by
                  attempt_item.question_order
              ),
              '[]'::jsonb
            )

            from public.quiz_attempt_items
              as attempt_item

            where attempt_item.attempt_id =
              selected_attempt.id
          ),

          'selectedAnswers',
          (
            select coalesce(
              jsonb_object_agg(
                attempt_item.question_id,
                to_jsonb(
                  attempt_item.selected_option_index
                )
              )
              filter (
                where attempt_item
                  .selected_option_index
                  is not null
              ),
              '{}'::jsonb
            )

            from public.quiz_attempt_items
              as attempt_item

            where attempt_item.attempt_id =
              selected_attempt.id
          ),

          'correctAnswers',
          selected_attempt.correct_answers,

          'answeredQuestions',
          selected_attempt.answered_questions,

          'earnedXp',
          selected_attempt.earned_xp,

          'elapsedTimeMilliseconds',
          selected_attempt.elapsed_seconds * 1000,

          'autoSubmitted',
          selected_attempt.auto_submitted
        )
      )
      order by
        selected_attempt.completed_at desc,
        selected_attempt.id desc
    ),
    '[]'::jsonb
  )
  into v_attempts
  from selected_attempts as selected_attempt;

  return jsonb_build_object(
    'generatedAt',
    now(),

    'totalCount',
    v_total_count,

    'attempts',
    v_attempts
  );
end;
$$;


revoke execute
on function public.get_my_quiz_history(
  integer
)
from public, anon, authenticated;

grant execute
on function public.get_my_quiz_history(
  integer
)
to authenticated;


-- =========================================================
-- 2. DELETE ONE QUIZ ATTEMPT
-- =========================================================

create or replace function public.delete_my_quiz_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_deleted_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_attempt_id is null then
    raise exception using
      errcode = '22023',
      message = 'attempt_id is required.';
  end if;

  delete from public.quiz_attempts
  where id = p_attempt_id
    and user_id = v_user_id
  returning id
  into v_deleted_id;

  if v_deleted_id is null then
    raise exception using
      errcode = '22023',
      message =
        'Quiz attempt was not found.';
  end if;

  /*
   * quiz_attempt_items dipadam secara automatik
   * melalui ON DELETE CASCADE.
   *
   * Data user_progress tidak ditolak kerana
   * fungsi ini hanya memadam rekod sejarah.
   */
  return jsonb_build_object(
    'deletedAttemptId',
    v_deleted_id
  );
end;
$$;


revoke execute
on function public.delete_my_quiz_attempt(
  uuid
)
from public, anon, authenticated;

grant execute
on function public.delete_my_quiz_attempt(
  uuid
)
to authenticated;


-- =========================================================
-- 3. CLEAR ALL MY QUIZ HISTORY
-- =========================================================

create or replace function public.clear_my_quiz_history()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_deleted_count integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  with deleted_attempts as (
    delete from public.quiz_attempts
    where user_id = v_user_id
    returning id
  )
  select count(*)::integer
  into v_deleted_count
  from deleted_attempts;

  /*
   * Fungsi ini hanya membersihkan sejarah.
   * XP dan statistik dalam user_progress
   * tidak direset.
   */
  return jsonb_build_object(
    'deletedCount',
    v_deleted_count
  );
end;
$$;


revoke execute
on function public.clear_my_quiz_history()
from public, anon, authenticated;

grant execute
on function public.clear_my_quiz_history()
to authenticated;


-- =========================================================
-- 4. GET MY TOPIC ANALYTICS
-- =========================================================

create or replace function public.get_my_topic_analytics()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_performances jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  with topic_performances as (
    select
      attempt.topic_id,
      attempt.topic_code,
      attempt.topic_title,

      count(*)::integer
        as attempt_count,

      coalesce(
        sum(attempt.question_count),
        0
      )::integer
        as total_questions,

      coalesce(
        sum(attempt.correct_answers),
        0
      )::integer
        as total_correct_answers,

      coalesce(
        max(
          case
            when attempt.question_count > 0 then
              round(
                (
                  attempt.correct_answers::numeric
                  /
                  attempt.question_count::numeric
                ) * 100,
                2
              )

            else
              0
          end
        ),
        0
      )::numeric
        as best_score,

      coalesce(
        sum(attempt.earned_xp),
        0
      )::integer
        as total_earned_xp,

      case
        when sum(attempt.question_count) > 0 then
          (
            sum(attempt.correct_answers)::numeric
            /
            sum(attempt.question_count)::numeric
          ) * 100

        else
          0
      end
        as average_score

    from public.quiz_attempts as attempt

    where attempt.user_id = v_user_id

    group by
      attempt.topic_id,
      attempt.topic_code,
      attempt.topic_title
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'topicId',
        performance.topic_id,

        'topicCode',
        performance.topic_code,

        'topicTitle',
        performance.topic_title,

        'attemptCount',
        performance.attempt_count,

        'totalQuestions',
        performance.total_questions,

        'totalCorrectAnswers',
        performance.total_correct_answers,

        'bestScore',
        performance.best_score,

        'totalEarnedXp',
        performance.total_earned_xp
      )
      order by
        performance.average_score desc,
        performance.attempt_count desc,
        performance.topic_title asc
    ),
    '[]'::jsonb
  )
  into v_performances
  from topic_performances as performance;

  return jsonb_build_object(
    'generatedAt',
    now(),

    'performances',
    v_performances
  );
end;
$$;


revoke execute
on function public.get_my_topic_analytics()
from public, anon, authenticated;

grant execute
on function public.get_my_topic_analytics()
to authenticated;


commit;