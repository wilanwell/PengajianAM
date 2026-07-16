begin;

-- =========================================================
-- RESET DATA PEMBELAJARAN PENGGUNA SEMASA
-- =========================================================

create or replace function public.reset_my_learning_data()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_default_display_name text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  select
    nullif(
      trim(
        coalesce(
          auth_user.raw_user_meta_data
            ->> 'display_name',
          split_part(
            coalesce(auth_user.email, ''),
            '@',
            1
          )
        )
      ),
      ''
    )
  into v_default_display_name
  from auth.users as auth_user
  where auth_user.id = v_user_id;

  if v_default_display_name is null
     or char_length(v_default_display_name) < 2 then
    v_default_display_name := 'Pelajar';
  end if;

  v_default_display_name :=
    left(v_default_display_name, 30);

  -- Memadam attempt akan turut memadam attempt items
  -- melalui ON DELETE CASCADE.
  delete from public.quiz_attempts
  where user_id = v_user_id;

  -- Padam sesi kuiz yang masih belum selesai.
  delete from private.quiz_sessions
  where user_id = v_user_id;

  insert into public.user_progress (
    user_id,
    total_xp,
    weekly_xp,
    monthly_xp,
    completed_quizzes,
    total_correct_answers,
    total_quiz_questions,
    highest_score,
    completed_topics,
    current_streak_days,
    best_streak_days,
    weekly_answered_questions
  )
  values (
    v_user_id,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    array[0, 0, 0, 0, 0, 0, 0]
  )
  on conflict (user_id)
  do update set
    total_xp = 0,
    weekly_xp = 0,
    monthly_xp = 0,
    completed_quizzes = 0,
    total_correct_answers = 0,
    total_quiz_questions = 0,
    highest_score = 0,
    completed_topics = 0,
    current_streak_days = 0,
    best_streak_days = 0,
    weekly_answered_questions =
      array[0, 0, 0, 0, 0, 0, 0];

  update public.profiles
  set display_name = v_default_display_name
  where id = v_user_id;
end;
$$;

revoke execute
on function public.reset_my_learning_data()
from public, anon;

grant execute
on function public.reset_my_learning_data()
to authenticated;

commit;