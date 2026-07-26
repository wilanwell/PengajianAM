begin;

-- =========================================================
-- M08 MISTAKE BOOK: READ RPC AND AUTOMATIC SYNCHRONIZATION
-- =========================================================


-- =========================================================
-- 1. AUTOMATIC ITEM SYNCHRONIZATION
-- =========================================================

create or replace function
private.synchronize_mistake_book_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_session_source text;
  v_completed_at timestamptz;
  v_topic_id text;
  v_updated_count integer;
begin
  /*
   * question_id may become null only after a historical
   * question has been deleted through ON DELETE SET NULL.
   *
   * Newly submitted quiz items should always contain
   * a valid question_id.
   */
  if new.question_id is null then
    return new;
  end if;

  select
    attempt.user_id,
    attempt.session_source,
    attempt.completed_at
  into
    v_user_id,
    v_session_source,
    v_completed_at
  from public.quiz_attempts
    as attempt
  where attempt.id = new.attempt_id;

  if not found then
    raise exception using
      errcode = '23503',
      message =
        'The quiz attempt for Mistake Book synchronization '
        'was not found.';
  end if;

  select question.topic_id
  into v_topic_id
  from public.questions
    as question
  where question.id = new.question_id;

  if not found then
    raise exception using
      errcode = '23503',
      message =
        'The question for Mistake Book synchronization '
        'was not found.';
  end if;


  -- =======================================================
  -- STANDARD QUIZ
  -- =======================================================

  /*
   * Only answered and incorrect questions are recorded.
   *
   * Correct answers and unanswered questions from a
   * standard quiz do not create a Mistake Book item.
   */
  if v_session_source = 'standard' then
    if new.selected_option_index is null
       or new.is_correct then
      return new;
    end if;

    insert into public.mistake_book_items
      as current_item (
        user_id,
        question_id,
        topic_id,
        status,
        incorrect_count,
        review_count,
        first_incorrect_attempt_id,
        latest_incorrect_attempt_id,
        mastered_attempt_id,
        first_incorrect_at,
        last_incorrect_at,
        last_reviewed_at,
        mastered_at
      )
    values (
      v_user_id,
      new.question_id,
      v_topic_id,
      'needs_review',
      1,
      0,
      new.attempt_id,
      new.attempt_id,
      null,
      v_completed_at,
      v_completed_at,
      null,
      null
    )
    on conflict (
      user_id,
      question_id
    )
    do update set
      topic_id =
        excluded.topic_id,

      status =
        case
          when current_item.mastered_at is null
               or excluded.last_incorrect_at >=
                  current_item.mastered_at then
            'needs_review'
          else
            current_item.status
        end,

      incorrect_count =
        current_item.incorrect_count + 1,

      latest_incorrect_attempt_id =
        case
          when excluded.last_incorrect_at >=
               current_item.last_incorrect_at then
            excluded.latest_incorrect_attempt_id
          else
            current_item.latest_incorrect_attempt_id
        end,

      mastered_attempt_id =
        case
          when current_item.mastered_at is null
               or excluded.last_incorrect_at >=
                  current_item.mastered_at then
            null
          else
            current_item.mastered_attempt_id
        end,

      last_incorrect_at =
        greatest(
          current_item.last_incorrect_at,
          excluded.last_incorrect_at
        ),

      mastered_at =
        case
          when current_item.mastered_at is null
               or excluded.last_incorrect_at >=
                  current_item.mastered_at then
            null
          else
            current_item.mastered_at
        end;

    return new;
  end if;


  -- =======================================================
  -- MISTAKE BOOK REVIEW
  -- =======================================================

  /*
   * Every presented review question increments review_count.
   *
   * Correct answered questions become mastered.
   * Wrong or unanswered questions remain needs_review.
   *
   * A wrong answered review also increments incorrect_count.
   */
  if v_session_source = 'mistake_review' then
    update public.mistake_book_items
      as current_item
    set
      topic_id =
        v_topic_id,

      status =
        case
          when v_completed_at <
               coalesce(
                 current_item.last_reviewed_at,
                 '-infinity'::timestamptz
               ) then
            current_item.status

          when new.selected_option_index is not null
               and new.is_correct
               and v_completed_at >=
                   current_item.last_incorrect_at then
            'mastered'

          else
            'needs_review'
        end,

      incorrect_count =
        current_item.incorrect_count +
        case
          when new.selected_option_index is not null
               and not new.is_correct then
            1
          else
            0
        end,

      review_count =
        current_item.review_count + 1,

      latest_incorrect_attempt_id =
        case
          when new.selected_option_index is not null
               and not new.is_correct
               and v_completed_at >=
                   current_item.last_incorrect_at then
            new.attempt_id
          else
            current_item.latest_incorrect_attempt_id
        end,

      mastered_attempt_id =
        case
          when v_completed_at <
               coalesce(
                 current_item.last_reviewed_at,
                 '-infinity'::timestamptz
               ) then
            current_item.mastered_attempt_id

          when new.selected_option_index is not null
               and new.is_correct
               and v_completed_at >=
                   current_item.last_incorrect_at then
            new.attempt_id

          else
            null
        end,

      last_incorrect_at =
        case
          when new.selected_option_index is not null
               and not new.is_correct then
            greatest(
              current_item.last_incorrect_at,
              v_completed_at
            )
          else
            current_item.last_incorrect_at
        end,

      last_reviewed_at =
        greatest(
          coalesce(
            current_item.last_reviewed_at,
            v_completed_at
          ),
          v_completed_at
        ),

      mastered_at =
        case
          when v_completed_at <
               coalesce(
                 current_item.last_reviewed_at,
                 '-infinity'::timestamptz
               ) then
            current_item.mastered_at

          when new.selected_option_index is not null
               and new.is_correct
               and v_completed_at >=
                   current_item.last_incorrect_at then
            v_completed_at

          else
            null
        end

    where current_item.user_id =
            v_user_id
      and current_item.question_id =
            new.question_id;

    get diagnostics
      v_updated_count = row_count;

    if v_updated_count <> 1 then
      raise exception using
        errcode = 'P0001',
        message =
          'The Mistake Book review item was not found.';
    end if;

    return new;
  end if;


  -- =======================================================
  -- DEFENSIVE FALLBACK
  -- =======================================================

  raise exception using
    errcode = '23514',
    message =
      'Unsupported quiz session source for '
      'Mistake Book synchronization.';
end;
$$;


revoke execute
on function private.synchronize_mistake_book_item()
from public, anon, authenticated;


comment on function
private.synchronize_mistake_book_item()
is
  'Synchronizes one inserted quiz attempt item with '
  'the corresponding server-authoritative Mistake Book state.';


-- =========================================================
-- 2. SYNCHRONIZATION TRIGGER
-- =========================================================

drop trigger if exists
quiz_attempt_items_sync_mistake_book
on public.quiz_attempt_items;


create trigger
quiz_attempt_items_sync_mistake_book
after insert
on public.quiz_attempt_items
for each row
execute function
private.synchronize_mistake_book_item();


comment on trigger
quiz_attempt_items_sync_mistake_book
on public.quiz_attempt_items
is
  'Automatically records standard quiz mistakes and '
  'updates learning state after Mistake Book reviews.';


-- =========================================================
-- 3. AUTHENTICATED MISTAKE BOOK SUMMARY RPC
-- =========================================================

create or replace function
public.get_my_mistake_book()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_needs_review_count integer;
  v_mastered_count integer;

  v_topics jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;


  -- =======================================================
  -- OVERALL COUNTS
  -- =======================================================

  select
    (
      count(*)
      filter (
        where item.status = 'needs_review'
      )
    )::integer,

    (
      count(*)
      filter (
        where item.status = 'mastered'
      )
    )::integer

  into
    v_needs_review_count,
    v_mastered_count

  from public.mistake_book_items
    as item

  where item.user_id =
          v_user_id;


  -- =======================================================
  -- TOPIC SUMMARIES
  -- =======================================================

  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'topicId',
          topic_summary.topic_id,

          'topicCode',
          topic_summary.topic_code,

          'topicTitle',
          topic_summary.topic_title,

          'semester',
          topic_summary.semester,

          'sortOrder',
          topic_summary.sort_order,

          'needsReviewCount',
          topic_summary.needs_review_count,

          'masteredCount',
          topic_summary.mastered_count,

          'lastMistakeAt',
          topic_summary.last_mistake_at
        )
        order by
          topic_summary.semester,
          topic_summary.sort_order,
          topic_summary.topic_code
      ),
      '[]'::jsonb
    )

  into v_topics

  from (
    select
      topic.id
        as topic_id,

      topic.code
        as topic_code,

      topic.title
        as topic_title,

      topic.semester
        as semester,

      topic.sort_order
        as sort_order,

      (
        count(*)
        filter (
          where item.status =
                  'needs_review'
        )
      )::integer
        as needs_review_count,

      (
        count(*)
        filter (
          where item.status =
                  'mastered'
        )
      )::integer
        as mastered_count,

      max(item.last_incorrect_at)
        as last_mistake_at

    from public.mistake_book_items
      as item

    join public.topics
      as topic
      on topic.id =
        item.topic_id

    where item.user_id =
            v_user_id

    group by
      topic.id,
      topic.code,
      topic.title,
      topic.semester,
      topic.sort_order
  ) as topic_summary;


  -- =======================================================
  -- RESPONSE
  -- =======================================================

  return jsonb_build_object(
    'generatedAt',
    now(),

    'needsReviewCount',
    v_needs_review_count,

    'masteredCount',
    v_mastered_count,

    'topics',
    v_topics
  );
end;
$$;


revoke execute
on function public.get_my_mistake_book()
from public, anon, authenticated;


grant execute
on function public.get_my_mistake_book()
to authenticated;


comment on function
public.get_my_mistake_book()
is
  'Returns the authenticated user Mistake Book counts '
  'and topic summaries without exposing other users data.';


commit;