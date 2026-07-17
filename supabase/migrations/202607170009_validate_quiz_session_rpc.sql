begin;

-- =========================================================
-- CHECK THE CURRENT USER'S SAVED QUIZ SESSION
-- =========================================================

create or replace function public.get_my_quiz_session_status(
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

  /*
   * user_id dimasukkan dalam syarat supaya pengguna
   * tidak dapat menyemak sesi milik akaun lain.
   *
   * Sesi milik pengguna lain dilayan sebagai not_found
   * supaya kewujudannya tidak didedahkan.
   */
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
      now()
    );
  end if;

  if v_session.submitted_at is not null then
    v_status := 'submitted';
    v_can_resume := false;

  elsif v_session.expires_at <= now() then
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

    'questionCount',
    v_session.question_count,

    'status',
    v_status,

    'canResume',
    v_can_resume,

    'createdAt',
    v_session.created_at,

    'expiresAt',
    v_session.expires_at,

    'submittedAt',
    v_session.submitted_at,

    'serverTime',
    now()
  );
end;
$$;


-- =========================================================
-- FUNCTION PERMISSIONS
-- =========================================================

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

commit;