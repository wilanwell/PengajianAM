begin;


-- =========================================================
-- M08 MISTAKE BOOK: TOPIC DETAIL READ RPC
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

  v_topic_id := nullif(btrim(p_topic_id), '');

  if v_topic_id is null then
    raise exception using
      errcode = '22023',
      message = 'topic_id is required.';
  end if;

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

      'masteredCount',
      count(*) filter (
        where item.status = 'mastered'
      )::integer
    )
  into v_topic
  from public.mistake_book_items as item
  join public.topics as topic
    on topic.id = item.topic_id
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

  select
    coalesce(
      jsonb_agg(
        detail.payload
        order by
          detail.status_order,
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
      question.sort_order as question_sort_order,

      case item.status
        when 'needs_review' then 0
        else 1
      end as status_order,

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
    join public.questions as question
      on question.id = item.question_id

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
      order by attempt_item.question_order
      limit 1
    ) as latest_mistake
      on true

    where item.user_id = v_user_id
      and item.topic_id = v_topic_id
  ) as detail;

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

comment on function
public.get_my_mistake_book_topic(text)
is
  'Returns the authenticated user Mistake Book '
  'items using each latest incorrect attempt snapshot.';

revoke execute
on function public.get_my_mistake_book_topic(text)
from public, anon, authenticated;

grant execute
on function public.get_my_mistake_book_topic(text)
to authenticated;


commit;
