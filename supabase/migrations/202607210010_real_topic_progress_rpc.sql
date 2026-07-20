-- =========================================================
-- REAL TOPIC PROGRESS
-- =========================================================
--
-- completedQuestionCount dikira berdasarkan question_id unik
-- yang benar-benar pernah dijawab oleh pengguna.
--
-- Percubaan kuiz berulang tidak akan menyebabkan progress
-- melebihi jumlah soalan topik.
-- =========================================================

create or replace function public.get_my_topics_with_progress()
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