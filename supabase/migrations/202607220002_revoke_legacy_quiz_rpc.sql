begin;

-- =========================================================
-- DISABLE DIRECT ACCESS TO LEGACY QUIZ RPC FUNCTIONS
-- =========================================================

/*
 * Flutter kini menggunakan:
 *
 * - public.start_quiz_v2(...)
 * - public.submit_quiz_attempt_v2(...)
 *
 * RPC lama masih digunakan secara dalaman oleh
 * function v2 sebagai engine pemilihan soalan,
 * scoring dan XP.
 *
 * Oleh sebab function v2 ialah SECURITY DEFINER,
 * ia tetap boleh memanggil function lama menggunakan
 * privilege pemilik function.
 *
 * Pengguna authenticated tidak lagi dibenarkan
 * memanggil function lama secara terus.
 */

revoke execute
on function public.start_quiz(
  text,
  integer,
  text
)
from public, anon, authenticated;

revoke execute
on function public.submit_quiz_attempt(
  uuid,
  jsonb,
  integer,
  boolean
)
from public, anon, authenticated;


-- =========================================================
-- REASSERT ACCESS TO V2 RPC FUNCTIONS
-- =========================================================

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
-- SESSION STATUS REMAINS AUTHENTICATED-ONLY
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