begin;

-- =========================================================
-- MISTAKE BOOK: REVIEWABILITY CONSISTENCY
-- =========================================================

/*
 * Rekod sejarah Mistake Book kekal kelihatan walaupun
 * sesuatu topik atau soalan telah dinyahaktifkan.
 *
 * Hanya soalan yang memenuhi semua syarat berikut boleh
 * dimasukkan ke dalam sesi latihan semula:
 *
 * 1. Status Mistake Book ialah needs_review.
 * 2. Topik masih aktif.
 * 3. Soalan masih aktif.
 * 4. Rekod jawapan betul masih tersedia.
 */


-- =========================================================
-- 1. MISTAKE BOOK SUMMARY RPC
-- =========================================================

create or replace function public.get_my_mistake_book()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_needs_review_count integer;
  v_reviewable_count integer;
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
    count(*) filter (
      where item.status = 'needs_review'
    )::integer,

    count(*) filter (
      where item.status = 'needs_review'
        and topic.is_active = true
        and question.is_active = true
        and answer.question_id is not null
    )::integer,

    count(*) filter (
      where item.status = 'mastered'
    )::integer

  into
    v_needs_review_count,
    v_reviewable_count,
    v_mastered_count

  from public.mistake_book_items as item

  join public.topics as topic
    on topic.id = item.topic_id

  join public.questions as question
    on question.id = item.question_id
   and question.topic_id = item.topic_id

  left join private.question_answers as answer
    on answer.question_id = item.question_id

  where item.user_id = v_user_id;


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

          'reviewableCount',
          topic_summary.reviewable_count,

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
      topic.id as topic_id,
      topic.code as topic_code,
      topic.title as topic_title,
      topic.semester as semester,
      topic.sort_order as sort_order,

      count(*) filter (
        where item.status = 'needs_review'
      )::integer as needs_review_count,

      count(*) filter (
        where item.status = 'needs_review'
          and topic.is_active = true
          and question.is_active = true
          and answer.question_id is not null
      )::integer as reviewable_count,

      count(*) filter (
        where item.status = 'mastered'
      )::integer as mastered_count,

      max(item.last_incorrect_at) as last_mistake_at

    from public.mistake_book_items as item

    join public.topics as topic
      on topic.id = item.topic_id

    join public.questions as question
      on question.id = item.question_id
     and question.topic_id = item.topic_id

    left join private.question_answers as answer
      on answer.question_id = item.question_id

    where item.user_id = v_user_id

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

    'reviewableCount',
    v_reviewable_count,

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


comment on function public.get_my_mistake_book()
is
  'Returns the authenticated user Mistake Book summary '
  'and separates historical needs-review records from '
  'questions currently available for review.';


-- =========================================================
-- 2. MISTAKE BOOK TOPIC DETAIL RPC
-- =========================================================

create or replace function public.get_my_mistake_book_topic(
  p_topic_id text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_topic_id text;

  v_topic jsonb;
  v_items jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  v_topic_id := nullif(
    btrim(p_topic_id),
    ''
  );

  if v_topic_id is null then
    raise exception using
      errcode = '22023',
      message = 'topic_id is required.';
  end if;


  -- =======================================================
  -- TOPIC INFORMATION AND COUNTS
  -- =======================================================

  select
    jsonb_build_object(
      'topicId',
      topic.id,

      'topicCode',
      topic.code,

      'topicTitle',
      topic.title,

      'semester',
      topic.semester,

      'sortOrder',
      topic.sort_order,

      'needsReviewCount',
      count(*) filter (
        where item.status = 'needs_review'
      )::integer,

      'reviewableCount',
      count(*) filter (
        where item.status = 'needs_review'
          and topic.is_active = true
          and question.is_active = true
          and answer.question_id is not null
      )::integer,

      'masteredCount',
      count(*) filter (
        where item.status = 'mastered'
      )::integer
    )

  into v_topic

  from public.mistake_book_items as item

  join public.topics as topic
    on topic.id = item.topic_id

  join public.questions as question
    on question.id = item.question_id
   and question.topic_id = item.topic_id

  left join private.question_answers as answer
    on answer.question_id = item.question_id

  where item.user_id = v_user_id
    and item.topic_id = v_topic_id

  group by
    topic.id,
    topic.code,
    topic.title,
    topic.semester,
    topic.sort_order;


  if v_topic is null then
    raise exception using
      errcode = '22023',
      message = 'Mistake Book topic was not found.';
  end if;


  -- =======================================================
  -- MISTAKE BOOK ITEMS
  -- =======================================================

  select
    coalesce(
      jsonb_agg(
        detail.payload
        order by
          detail.status_order,
          detail.reviewability_order,
          detail.last_incorrect_at desc,
          detail.question_sort_order,
          detail.question_id
      ),
      '[]'::jsonb
    )

  into v_items

  from (
    select
      item.question_id,
      item.last_incorrect_at,

      question.sort_order
        as question_sort_order,

      case item.status
        when 'needs_review' then 0
        else 1
      end as status_order,

      case
        when item.status = 'needs_review'
         and topic.is_active = true
         and question.is_active = true
         and answer.question_id is not null
        then 0
        else 1
      end as reviewability_order,

      jsonb_build_object(
        'questionId',
        item.question_id,

        'questionText',
        latest_mistake.question_snapshot
          ->> 'questionText',

        'options',
        latest_mistake.question_snapshot
          -> 'options',

        'selectedOptionIndex',
        latest_mistake.selected_option_index,

        'correctOptionIndex',
        latest_mistake.correct_option_index,

        'explanation',
        latest_mistake.question_snapshot
          ->> 'explanation',

        'status',
        item.status,

        'isReviewable',
        (
          item.status = 'needs_review'
          and topic.is_active = true
          and question.is_active = true
          and answer.question_id is not null
        ),

        'incorrectCount',
        item.incorrect_count,

        'reviewCount',
        item.review_count,

        'firstIncorrectAt',
        item.first_incorrect_at,

        'lastIncorrectAt',
        item.last_incorrect_at,

        'lastReviewedAt',
        item.last_reviewed_at,

        'masteredAt',
        item.mastered_at
      ) as payload

    from public.mistake_book_items as item

    join public.topics as topic
      on topic.id = item.topic_id

    join public.questions as question
      on question.id = item.question_id
     and question.topic_id = item.topic_id

    left join private.question_answers as answer
      on answer.question_id = item.question_id

    join lateral (
      select
        attempt_item.question_snapshot,
        attempt_item.selected_option_index,
        attempt_item.correct_option_index

      from public.quiz_attempt_items as attempt_item

      where attempt_item.attempt_id =
              item.latest_incorrect_attempt_id
        and attempt_item.question_id =
              item.question_id
        and attempt_item.selected_option_index
              is not null
        and not attempt_item.is_correct

      order by
        attempt_item.question_order

      limit 1
    ) as latest_mistake
      on true

    where item.user_id = v_user_id
      and item.topic_id = v_topic_id
  ) as detail;


  -- =======================================================
  -- RESPONSE
  -- =======================================================

  return jsonb_build_object(
    'generatedAt',
    now(),

    'topic',
    v_topic,

    'items',
    v_items
  );
end;
$$;


revoke execute
on function public.get_my_mistake_book_topic(text)
from public, anon, authenticated;


grant execute
on function public.get_my_mistake_book_topic(text)
to authenticated;


comment on function public.get_my_mistake_book_topic(text)
is
  'Returns historical Mistake Book items and identifies '
  'which needs-review questions are currently available '
  'for a dedicated review session.';


commit;