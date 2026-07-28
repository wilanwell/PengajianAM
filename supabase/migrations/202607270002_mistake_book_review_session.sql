begin;

-- =========================================================
-- M08 MISTAKE BOOK: DEDICATED REVIEW SESSION
-- =========================================================

/*
 * Review sessions are learning-only activities:
 *
 * - they contain only the current user's needs_review items;
 * - correct answers may mark items as mastered;
 * - wrong or unanswered items remain needs_review;
 * - they never award XP or update user_progress;
 * - they are excluded from standard history and analytics.
 */


-- =========================================================
-- 1. START ALL AVAILABLE REVIEWS FOR ONE TOPIC
-- =========================================================

create or replace function
public.start_mistake_review(
  p_topic_id text,
  p_question_count integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_session_id uuid;
  v_created_at timestamptz;
  v_expires_at timestamptz;

  v_available_count integer;
  v_actual_count integer;
  v_question_order integer := 0;

  v_question record;
  v_option_count integer;
  v_option_order integer[];
  v_display_options jsonb;

  v_questions jsonb := '[]'::jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_topic_id is null
     or char_length(trim(p_topic_id)) = 0 then
    raise exception using
      errcode = '22023',
      message = 'topic_id is required.';
  end if;

  if p_question_count is null
     or p_question_count < 1
     or p_question_count > 100 then
    raise exception using
      errcode = '22023',
      message =
        'question_count must be between 1 and 100.';
  end if;

  if not exists (
    select 1
    from public.topics as topic
    where topic.id = p_topic_id
      and topic.is_active = true
  ) then
    raise exception using
      errcode = '22023',
      message =
        'The selected topic is not available.';
  end if;

  select count(*)::integer
  into v_available_count
  from public.mistake_book_items as mistake

  join public.questions as question
    on question.id = mistake.question_id
    and question.topic_id = mistake.topic_id
    and question.is_active = true

  where mistake.user_id = v_user_id
    and mistake.topic_id = p_topic_id
    and mistake.status = 'needs_review'

    and exists (
      select 1
      from private.question_answers as answer
      where answer.question_id = mistake.question_id
    );

  if v_available_count = 0 then
    raise exception using
      errcode = '22023',
      message =
        'No review questions are available for this topic.';
  end if;

  v_actual_count :=
    least(
      p_question_count,
      v_available_count
    );

  v_expires_at :=
    clock_timestamp() + interval '2 hours';

  insert into private.quiz_sessions (
    user_id,
    topic_id,
    mode,
    question_count,
    expires_at,
    session_source
  )
  values (
    v_user_id,
    p_topic_id,
    'practice',
    v_actual_count,
    v_expires_at,
    'mistake_review'
  )
  returning
    id,
    created_at,
    expires_at
  into
    v_session_id,
    v_created_at,
    v_expires_at;

  for v_question in
    select
      question.id,
      question.topic_id,
      question.question_text,
      question.options,
      question.shuffle_options

    from public.mistake_book_items as mistake

    join public.questions as question
      on question.id = mistake.question_id
      and question.topic_id = mistake.topic_id
      and question.is_active = true

    join private.question_answers as answer
      on answer.question_id = mistake.question_id

    where mistake.user_id = v_user_id
      and mistake.topic_id = p_topic_id
      and mistake.status = 'needs_review'

    /*
     * Never-reviewed questions come first. Older reviews
     * then come before more recent ones.
     */
    order by
      mistake.last_reviewed_at asc nulls first,
      mistake.last_incorrect_at desc,
      mistake.question_id

    limit v_actual_count
  loop
    v_question_order :=
      v_question_order + 1;

    v_option_count :=
      jsonb_array_length(
        v_question.options
      );

    v_option_order :=
      private.build_option_order(
        v_option_count,
        v_question.shuffle_options
      );

    insert into private.quiz_session_items (
      session_id,
      question_id,
      question_order,
      option_order
    )
    values (
      v_session_id,
      v_question.id,
      v_question_order,
      v_option_order
    );

    select coalesce(
      jsonb_agg(
        v_question.options
          -> ordered_option.original_index
        order by
          ordered_option.display_position
      ),
      '[]'::jsonb
    )
    into v_display_options
    from unnest(
      v_option_order
    ) with ordinality
      as ordered_option(
        original_index,
        display_position
      );

    v_questions :=
      v_questions ||
      jsonb_build_array(
        jsonb_build_object(
          'id',
          v_question.id,

          'topicId',
          v_question.topic_id,

          'questionText',
          v_question.question_text,

          'options',
          v_display_options,

          'shuffleOptions',
          false,

          'questionOrder',
          v_question_order
        )
      );
  end loop;

  if v_question_order <> v_actual_count then
    raise exception using
      errcode = 'P0001',
      message =
        'The review question set could not be completed.';
  end if;

  return jsonb_build_object(
    'sessionId',
    v_session_id,

    'sessionSource',
    'mistake_review',

    'topicId',
    p_topic_id,

    'mode',
    'practice',

    'questionCount',
    v_actual_count,

    'createdAt',
    v_created_at,

    'expiresAt',
    v_expires_at,

    'hardExpiresAt',
    v_expires_at,

    'examDeadlineAt',
    null,

    'serverTime',
    clock_timestamp(),

    'questions',
    v_questions
  );
end;
$$;

revoke execute
on function public.start_mistake_review(
  text,
  integer
)
from public, anon, authenticated;

grant execute
on function public.start_mistake_review(
  text,
  integer
)
to authenticated;


-- =========================================================
-- 2. SUBMIT A REVIEW WITHOUT XP OR STANDARD PROGRESS
-- =========================================================

create or replace function
public.submit_mistake_review(
  p_session_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_session private.quiz_sessions%rowtype;

  v_server_time timestamptz;
  v_elapsed_seconds integer;

  v_topic_code text;
  v_topic_title text;

  v_attempt_id uuid;
  v_completed_at timestamptz;

  v_item record;
  v_processed_count integer := 0;

  v_selected_display_index integer;
  v_selected_original_index integer;

  v_correct_original_index integer;
  v_correct_display_index integer;

  v_display_options jsonb;
  v_is_correct boolean;

  v_answer_count integer;
  v_distinct_answer_count integer;

  v_answered_count integer := 0;
  v_correct_count integer := 0;

  v_result_questions jsonb := '[]'::jsonb;
  v_selected_answers jsonb := '{}'::jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message = 'session_id is required.';
  end if;

  if p_answers is null
     or jsonb_typeof(p_answers) <> 'array' then
    raise exception using
      errcode = '22023',
      message = 'answers must be a JSON array.';
  end if;

  select *
  into v_session
  from private.quiz_sessions
  where id = p_session_id
  for update;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'Quiz session was not found.';
  end if;

  if v_session.user_id <> v_user_id then
    raise exception using
      errcode = '42501',
      message =
        'This quiz session belongs to another user.';
  end if;

  if v_session.session_source <> 'mistake_review'
     or v_session.mode <> 'practice' then
    raise exception using
      errcode = '22023',
      message =
        'This session is not a Mistake Book review.';
  end if;

  if v_session.submitted_at is not null then
    raise exception using
      errcode = '22023',
      message =
        'This quiz session has already been submitted.';
  end if;

  v_server_time := clock_timestamp();

  if v_session.expires_at <= v_server_time then
    raise exception using
      errcode = '22023',
      message =
        'This quiz session has expired.';
  end if;

  v_elapsed_seconds :=
    least(
      86400,
      greatest(
        0,
        floor(
          extract(
            epoch from
              (
                v_server_time -
                v_session.created_at
              )
          )
        )::integer
      )
    );

  /*
   * Validate the whole answer collection before inserting
   * any attempt data.
   */
  if exists (
    select 1
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where jsonb_typeof(
            submitted_answer.value
          ) <> 'object'

       or not (
         submitted_answer.value
         ? 'question_id'
       )

       or jsonb_typeof(
            submitted_answer.value
              -> 'question_id'
          ) <> 'string'

       or nullif(
            trim(
              submitted_answer.value
                ->> 'question_id'
            ),
            ''
          ) is null

       or (
         submitted_answer.value
           ? 'selected_option_index'

         and jsonb_typeof(
           submitted_answer.value
             -> 'selected_option_index'
         ) not in (
           'number',
           'null'
         )
       )

       or (
         jsonb_typeof(
           submitted_answer.value
             -> 'selected_option_index'
         ) = 'number'

         and (
           submitted_answer.value
             ->> 'selected_option_index'
         ) !~ '^[0-9]+$'
       )
  ) then
    raise exception using
      errcode = '22023',
      message =
        'Invalid answer data.';
  end if;

  select
    count(*)::integer,
    count(
      distinct
      submitted_answer.value
        ->> 'question_id'
    )::integer
  into
    v_answer_count,
    v_distinct_answer_count
  from jsonb_array_elements(
    p_answers
  ) as submitted_answer(value);

  if v_answer_count <>
     v_distinct_answer_count then
    raise exception using
      errcode = '22023',
      message =
        'Duplicate answers for the same question are not allowed.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where not exists (
      select 1
      from private.quiz_session_items as session_item
      where session_item.session_id = p_session_id
        and session_item.question_id =
          submitted_answer.value
            ->> 'question_id'
    )
  ) then
    raise exception using
      errcode = '22023',
      message =
        'An answer refers to a question outside this session.';
  end if;

  select
    topic.code,
    topic.title
  into
    v_topic_code,
    v_topic_title
  from public.topics as topic
  where topic.id = v_session.topic_id;

  insert into public.quiz_attempts (
    user_id,
    topic_id,
    topic_code,
    topic_title,
    mode,
    session_source,
    question_count,
    correct_answers,
    answered_questions,
    elapsed_seconds,
    earned_xp,
    auto_submitted
  )
  values (
    v_user_id,
    v_session.topic_id,
    coalesce(v_topic_code, ''),
    coalesce(
      v_topic_title,
      'Topik Pengajian AM'
    ),
    'practice',
    'mistake_review',
    v_session.question_count,
    0,
    0,
    v_elapsed_seconds,
    0,
    false
  )
  returning
    id,
    completed_at
  into
    v_attempt_id,
    v_completed_at;

  for v_item in
    select
      session_item.question_id,
      session_item.question_order,
      session_item.option_order,

      question.topic_id,
      question.question_text,
      question.options,

      answer.correct_option_index,
      answer.explanation

    from private.quiz_session_items as session_item

    join public.questions as question
      on question.id = session_item.question_id

    join private.question_answers as answer
      on answer.question_id = session_item.question_id

    where session_item.session_id = p_session_id

    order by session_item.question_order
  loop
    v_processed_count :=
      v_processed_count + 1;

    v_selected_display_index := null;
    v_selected_original_index := null;

    select
      (
        submitted_answer.value
          ->> 'selected_option_index'
      )::integer
    into v_selected_display_index
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where submitted_answer.value
            ->> 'question_id'
          = v_item.question_id

      and submitted_answer.value
            ? 'selected_option_index'

      and jsonb_typeof(
        submitted_answer.value
          -> 'selected_option_index'
      ) = 'number'
    limit 1;

    if v_selected_display_index is not null then
      if v_selected_display_index >=
         cardinality(v_item.option_order) then
        raise exception using
          errcode = '22023',
          message =
            'A selected option index is outside the valid range.';
      end if;

      v_selected_original_index :=
        v_item.option_order[
          v_selected_display_index + 1
        ];

      v_answered_count :=
        v_answered_count + 1;

      v_selected_answers :=
        v_selected_answers ||
        jsonb_build_object(
          v_item.question_id,
          v_selected_display_index
        );
    end if;

    v_correct_original_index :=
      v_item.correct_option_index;

    v_correct_display_index :=
      array_position(
        v_item.option_order,
        v_correct_original_index
      ) - 1;

    if v_correct_display_index is null
       or v_correct_display_index < 0 then
      raise exception using
        errcode = 'P0001',
        message =
          'Correct answer mapping could not be resolved.';
    end if;

    v_is_correct :=
      v_selected_original_index is not null
      and v_selected_original_index =
        v_correct_original_index;

    if v_is_correct then
      v_correct_count :=
        v_correct_count + 1;
    end if;

    select coalesce(
      jsonb_agg(
        v_item.options
          -> ordered_option.original_index
        order by
          ordered_option.display_position
      ),
      '[]'::jsonb
    )
    into v_display_options
    from unnest(
      v_item.option_order
    ) with ordinality
      as ordered_option(
        original_index,
        display_position
      );

    /*
     * The existing synchronization trigger reads the
     * attempt's mistake_review source and updates mastery.
     */
    insert into public.quiz_attempt_items (
      attempt_id,
      question_id,
      question_order,
      question_snapshot,
      selected_option_index,
      correct_option_index,
      is_correct
    )
    values (
      v_attempt_id,
      v_item.question_id,
      v_item.question_order,

      jsonb_build_object(
        'id',
        v_item.question_id,

        'topicId',
        v_item.topic_id,

        'questionText',
        v_item.question_text,

        'options',
        v_display_options,

        'explanation',
        v_item.explanation,

        'shuffleOptions',
        false
      ),

      v_selected_display_index,
      v_correct_display_index,
      v_is_correct
    );

    v_result_questions :=
      v_result_questions ||
      jsonb_build_array(
        jsonb_build_object(
          'id',
          v_item.question_id,

          'topicId',
          v_item.topic_id,

          'questionText',
          v_item.question_text,

          'options',
          v_display_options,

          'correctOptionIndex',
          v_correct_display_index,

          'explanation',
          v_item.explanation,

          'shuffleOptions',
          false
        )
      );
  end loop;

  if v_processed_count <>
      v_session.question_count then
    raise exception using
      errcode = 'P0001',
      message =
        'The review question set is incomplete.';
  end if;

  update public.quiz_attempts
  set
    correct_answers =
      v_correct_count,

    answered_questions =
      v_answered_count

  where id = v_attempt_id;

  update private.quiz_sessions
  set submitted_at = v_server_time
  where id = p_session_id;

  return jsonb_build_object(
    'attemptId',
    v_attempt_id,

    'topicId',
    v_session.topic_id,

    'topicCode',
    coalesce(v_topic_code, ''),

    'topicTitle',
    coalesce(
      v_topic_title,
      'Topik Pengajian AM'
    ),

    'mode',
    'practice',

    'sessionSource',
    'mistake_review',

    'questions',
    v_result_questions,

    'selectedAnswers',
    v_selected_answers,

    'correctAnswers',
    v_correct_count,

    'answeredQuestions',
    v_answered_count,

    'questionCount',
    v_session.question_count,

    'elapsedTimeMilliseconds',
    v_elapsed_seconds * 1000,

    'earnedXp',
    0,

    'autoSubmitted',
    false,

    'completedAt',
    v_completed_at
  );
end;
$$;

revoke execute
on function public.submit_mistake_review(
  uuid,
  jsonb
)
from public, anon, authenticated;

grant execute
on function public.submit_mistake_review(
  uuid,
  jsonb
)
to authenticated;


-- =========================================================
-- 3. STANDARD SUBMISSION REJECTS REVIEW SESSIONS
-- =========================================================

create or replace function
public.submit_quiz_attempt_v2(
  p_session_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_session private.quiz_sessions%rowtype;

  v_server_time timestamptz;
  v_effective_end_at timestamptz;

  v_elapsed_seconds integer;
  v_auto_submitted boolean;
  v_submission jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message = 'session_id is required.';
  end if;

  select *
  into v_session
  from private.quiz_sessions
  where id = p_session_id
  for update;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'Quiz session was not found.';
  end if;

  if v_session.user_id <> v_user_id then
    raise exception using
      errcode = '42501',
      message =
        'This quiz session belongs to another user.';
  end if;

  /*
   * Prevent a review session from reaching the legacy
   * XP/progress engine through the standard endpoint.
   */
  if v_session.session_source <> 'standard' then
    raise exception using
      errcode = '22023',
      message =
        'Mistake Book reviews must use the review endpoint.';
  end if;

  if v_session.submitted_at is not null then
    raise exception using
      errcode = '22023',
      message =
        'This quiz session has already been submitted.';
  end if;

  v_server_time := clock_timestamp();

  if v_session.mode = 'exam' then
    if v_session.exam_deadline_at is null then
      raise exception using
        errcode = '22023',
        message =
          'Exam session deadline is not configured.';
    end if;

    if v_server_time >
        (
          v_session.exam_deadline_at +
          interval '30 seconds'
        ) then
      raise exception using
        errcode = '22023',
        message =
          'This exam session deadline has passed.';
    end if;

    v_effective_end_at :=
      least(
        v_server_time,
        v_session.exam_deadline_at
      );

    v_auto_submitted :=
      v_server_time >=
        v_session.exam_deadline_at;
  else
    if v_server_time >=
        v_session.expires_at then
      raise exception using
        errcode = '22023',
        message =
          'This quiz session has expired.';
    end if;

    v_effective_end_at :=
      v_server_time;

    v_auto_submitted := false;
  end if;

  v_elapsed_seconds :=
    least(
      86400,
      greatest(
        0,
        floor(
          extract(
            epoch from
              (
                v_effective_end_at -
                v_session.created_at
              )
          )
        )::integer
      )
    );

  v_submission :=
    public.submit_quiz_attempt(
      p_session_id,
      p_answers,
      v_elapsed_seconds,
      v_auto_submitted
    );

  return
    v_submission ||
    jsonb_build_object(
      'sessionSource',
      'standard'
    );
end;
$$;

revoke execute
on function public.submit_quiz_attempt_v2(
  uuid,
  jsonb
)
from public, anon, authenticated;

grant execute
on function public.submit_quiz_attempt_v2(
  uuid,
  jsonb
)
to authenticated;


-- =========================================================
-- 4. SESSION VALIDATION PRESERVES THE SESSION SOURCE
-- =========================================================

create or replace function
public.get_my_quiz_session_status(
  p_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_session private.quiz_sessions%rowtype;

  v_status text;
  v_can_resume boolean;

  v_server_time timestamptz;
  v_effective_expires_at timestamptz;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message = 'session_id is required.';
  end if;

  v_server_time := clock_timestamp();

  select *
  into v_session
  from private.quiz_sessions
  where id = p_session_id
    and user_id = v_user_id;

  if not found then
    return jsonb_build_object(
      'sessionId',
      p_session_id,

      'status',
      'not_found',

      'canResume',
      false,

      'serverTime',
      v_server_time
    );
  end if;

  if v_session.mode = 'exam' then
    v_effective_expires_at :=
      coalesce(
        v_session.exam_deadline_at,
        v_session.expires_at
      );
  else
    v_effective_expires_at :=
      v_session.expires_at;
  end if;

  if v_session.submitted_at is not null then
    v_status := 'submitted';
    v_can_resume := false;
  elsif v_effective_expires_at <=
        v_server_time then
    v_status := 'expired';
    v_can_resume := false;
  else
    v_status := 'active';
    v_can_resume := true;
  end if;

  return jsonb_build_object(
    'sessionId',
    v_session.id,

    'topicId',
    v_session.topic_id,

    'mode',
    v_session.mode,

    'sessionSource',
    v_session.session_source,

    'questionCount',
    v_session.question_count,

    'status',
    v_status,

    'canResume',
    v_can_resume,

    'createdAt',
    v_session.created_at,

    'expiresAt',
    v_effective_expires_at,

    'hardExpiresAt',
    v_session.expires_at,

    'examDeadlineAt',
    v_session.exam_deadline_at,

    'submittedAt',
    v_session.submitted_at,

    'serverTime',
    v_server_time
  );
end;
$$;

revoke execute
on function public.get_my_quiz_session_status(
  uuid
)
from public, anon, authenticated;

grant execute
on function public.get_my_quiz_session_status(
  uuid
)
to authenticated;


-- =========================================================
-- 5. STANDARD HISTORY EXCLUDES LEARNING-ONLY REVIEWS
-- =========================================================

create or replace function
public.get_my_quiz_history(
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
  where attempt.user_id = v_user_id
    and attempt.session_source = 'standard';

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
      and attempt.session_source = 'standard'

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

          'sessionSource',
          'standard',

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

            from public.quiz_attempt_items as attempt_item

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

            from public.quiz_attempt_items as attempt_item

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
-- 6. STANDARD TOPIC ANALYTICS EXCLUDE REVIEWS
-- =========================================================

create or replace function
public.get_my_topic_analytics()
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
            else 0
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
        else 0
      end
        as average_score

    from public.quiz_attempts as attempt

    where attempt.user_id = v_user_id
      and attempt.session_source = 'standard'

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


-- =========================================================
-- 7. STANDARD TOPIC PROGRESS EXCLUDES REVIEWS
-- =========================================================

create or replace function
public.get_my_topics_with_progress()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_topics jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  with user_topic_progress as (
    select
      attempt.topic_id,

      count(
        distinct item.question_id
      ) filter (
        where item.question_id is not null
          and item.selected_option_index is not null
      )::integer
        as completed_question_count,

      max(
        attempt.completed_at
      )
        as last_attempt_at

    from public.quiz_attempts as attempt

    left join public.quiz_attempt_items as item
      on item.attempt_id = attempt.id

    where attempt.user_id = v_user_id
      and attempt.topic_id is not null
      and attempt.session_source = 'standard'

    group by attempt.topic_id
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id',
        topic.id,

        'code',
        topic.code,

        'semester',
        topic.semester,

        'title',
        topic.title,

        'description',
        topic.description,

        'questionCount',
        topic.question_count,

        'sortOrder',
        topic.sort_order,

        'completedQuestionCount',
        least(
          topic.question_count,
          coalesce(
            progress.completed_question_count,
            0
          )
        ),

        'lastAttemptAt',
        progress.last_attempt_at
      )
      order by
        topic.sort_order asc,
        topic.code asc
    ),
    '[]'::jsonb
  )
  into v_topics

  from public.topics as topic

  left join user_topic_progress as progress
    on progress.topic_id = topic.id

  where topic.is_active = true;

  return jsonb_build_object(
    'generatedAt',
    now(),

    'topics',
    v_topics
  );
end;
$$;

revoke execute
on function public.get_my_topics_with_progress()
from public, anon, authenticated;

grant execute
on function public.get_my_topics_with_progress()
to authenticated;


-- =========================================================
-- 8. KEEP LEGACY MUTATING RPCS PRIVATE
-- =========================================================

revoke execute
on function public.submit_quiz_attempt(
  uuid,
  jsonb,
  integer,
  boolean
)
from public, anon, authenticated;

commit;
