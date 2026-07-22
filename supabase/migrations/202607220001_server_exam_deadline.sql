begin;

-- =========================================================
-- SERVER-AUTHORITATIVE EXAM DEADLINE
-- =========================================================

alter table private.quiz_sessions
add column if not exists
  exam_deadline_at timestamptz;


-- =========================================================
-- BACKFILL EXISTING SESSIONS
-- =========================================================

update private.quiz_sessions
set exam_deadline_at =
  least(
    expires_at,
    created_at +
      make_interval(
        secs => question_count * 90
      )
  )
where mode = 'exam'
  and exam_deadline_at is null;

update private.quiz_sessions
set exam_deadline_at = null
where mode = 'practice'
  and exam_deadline_at is not null;


-- =========================================================
-- DEADLINE CONSTRAINT
-- =========================================================

alter table private.quiz_sessions
drop constraint if exists
  quiz_session_exam_deadline_matches_mode;

alter table private.quiz_sessions
add constraint
  quiz_session_exam_deadline_matches_mode
check (
  (
    mode = 'practice'
    and exam_deadline_at is null
  )
  or
  (
    mode = 'exam'
    and exam_deadline_at is not null
    and exam_deadline_at > created_at
    and exam_deadline_at <= expires_at
  )
);


-- =========================================================
-- AUTOMATIC DEADLINE TRIGGER
-- =========================================================

create or replace function
private.apply_quiz_session_exam_deadline()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.mode = 'exam' then
    /*
     * Setiap soalan menerima 90 saat.
     *
     * Deadline tidak boleh melepasi hard
     * session expiry.
     */
    new.exam_deadline_at :=
      least(
        new.expires_at,
        new.created_at +
          make_interval(
            secs =>
              new.question_count * 90
          )
      );

  else
    new.exam_deadline_at := null;
  end if;

  return new;
end;
$$;

revoke execute
on function
  private.apply_quiz_session_exam_deadline()
from public, anon, authenticated;

drop trigger if exists
  apply_quiz_session_exam_deadline_trigger
on private.quiz_sessions;

create trigger
  apply_quiz_session_exam_deadline_trigger
before insert or update of
  mode,
  question_count,
  created_at,
  expires_at
on private.quiz_sessions
for each row
execute function
  private.apply_quiz_session_exam_deadline();


-- =========================================================
-- INDEX FOR DEADLINE AND CLEANUP OPERATIONS
-- =========================================================

create index if not exists
quiz_sessions_exam_deadline_index
on private.quiz_sessions (
  exam_deadline_at
)
where exam_deadline_at is not null;


-- =========================================================
-- START QUIZ V2
--
-- Wrapper ini menggunakan logic start_quiz lama,
-- kemudian menggantikan expiresAt dengan effective
-- expiry yang datang daripada server.
-- =========================================================

create or replace function public.start_quiz_v2(
  p_topic_id text,
  p_question_count integer,
  p_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_payload jsonb;
  v_session_id uuid;

  v_session private.quiz_sessions%rowtype;

  v_effective_expires_at timestamptz;
  v_server_time timestamptz;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  /*
   * Gunakan logic pemilihan, randomization
   * dan penciptaan session sedia ada.
   *
   * Trigger akan menambah exam_deadline_at
   * semasa row session dimasukkan.
   */
  v_payload :=
    public.start_quiz(
      p_topic_id,
      p_question_count,
      p_mode
    );

  v_session_id :=
    (v_payload ->> 'sessionId')::uuid;

  select *
  into v_session
  from private.quiz_sessions
  where id = v_session_id
    and user_id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'Created quiz session '
        'was not found.';
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

  v_server_time := clock_timestamp();

  /*
   * expiresAt ialah effective expiry:
   *
   * Practice = hard session expiry.
   * Exam     = exam deadline.
   *
   * hardExpiresAt dan examDeadlineAt
   * turut dikembalikan untuk diagnostics
   * dan future client migration.
   */
  return
    (v_payload - 'expiresAt')
    ||
    jsonb_build_object(
      'createdAt',
      v_session.created_at,

      'expiresAt',
      v_effective_expires_at,

      'hardExpiresAt',
      v_session.expires_at,

      'examDeadlineAt',
      v_session.exam_deadline_at,

      'serverTime',
      v_server_time
    );
end;
$$;

revoke execute
on function public.start_quiz_v2(
  text,
  integer,
  text
)
from public, anon, authenticated;

grant execute
on function public.start_quiz_v2(
  text,
  integer,
  text
)
to authenticated;


-- =========================================================
-- SUBMIT QUIZ V2
--
-- Client tidak lagi menentukan:
-- - elapsed time
-- - auto-submitted status
--
-- Kedua-duanya dikira daripada session server.
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
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message =
        'session_id is required.';
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
        'This quiz session belongs '
        'to another user.';
  end if;

  if v_session.submitted_at is not null then
    raise exception using
      errcode = '22023',
      message =
        'This quiz session has already '
        'been submitted.';
  end if;

  v_server_time := clock_timestamp();

  if v_session.mode = 'exam' then
    if v_session.exam_deadline_at is null then
      raise exception using
        errcode = '22023',
        message =
          'Exam session deadline '
          'is not configured.';
    end if;

    /*
     * Beri grace period 30 saat untuk
     * request yang dihantar tepat ketika
     * timer tamat tetapi tiba sedikit lewat
     * kerana latency rangkaian.
     *
     * Selepas grace period, submission
     * ditolak sepenuhnya.
     */
    if v_server_time >
        (
          v_session.exam_deadline_at +
          interval '30 seconds'
        ) then
      raise exception using
        errcode = '22023',
        message =
          'This exam session deadline '
          'has passed.';
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

  /*
   * Elapsed time datang daripada timestamp
   * server dan bukan nilai yang dihantar
   * oleh Flutter.
   */
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

  /*
   * Function lama masih digunakan sebagai
   * engine scoring dan XP.
   *
   * Nilai masa dan auto-submit yang diberikan
   * kepadanya kini telah dikira oleh server.
   */
  return public.submit_quiz_attempt(
    p_session_id,
    p_answers,
    v_elapsed_seconds,
    v_auto_submitted
  );
end;
$$;

revoke execute
on function
public.submit_quiz_attempt_v2(
  uuid,
  jsonb
)
from public, anon, authenticated;

grant execute
on function
public.submit_quiz_attempt_v2(
  uuid,
  jsonb
)
to authenticated;


-- =========================================================
-- SESSION STATUS WITH EFFECTIVE EXAM DEADLINE
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
      message =
        'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message =
        'session_id is required.';
  end if;

  v_server_time := clock_timestamp();

  /*
   * user_id dimasukkan dalam syarat supaya
   * sesi pengguna lain tidak didedahkan.
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

    'questionCount',
    v_session.question_count,

    'status',
    v_status,

    'canResume',
    v_can_resume,

    'createdAt',
    v_session.created_at,

    /*
     * Kekalkan nama expiresAt supaya entity
     * Flutter sedia ada menggunakan effective
     * expiry tanpa perubahan schema model.
     */
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
on function
public.get_my_quiz_session_status(
  uuid
)
from public, anon, authenticated;

grant execute
on function
public.get_my_quiz_session_status(
  uuid
)
to authenticated;


/*
 * RPC legacy belum direvoke dalam migration ini.
 *
 * Ia akan direvoke selepas Flutter berjaya
 * bertukar kepada start_quiz_v2 dan
 * submit_quiz_attempt_v2.
 *
 * Ini mengelakkan app semasa terputus ketika
 * migration dan client update belum lengkap.
 */

commit;