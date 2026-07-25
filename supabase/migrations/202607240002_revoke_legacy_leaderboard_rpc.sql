begin;

-- =========================================================
-- REVOKE LEGACY LEADERBOARD RPC
-- =========================================================

/*
 * Flutter kini menggunakan:
 *
 * public.get_leaderboard_v2(text, integer)
 *
 * RPC lama tidak menyokong:
 *
 * - leaderboard opt-in / opt-out;
 * - XP mengikut tempoh sebenar;
 * - period-scoped pseudonymous ID;
 * - current-user state bagi pengguna opt-out.
 *
 * Oleh itu, client tidak lagi dibenarkan
 * memanggil RPC lama secara langsung.
 */

revoke execute
on function public.get_leaderboard(
  text,
  integer
)
from public, anon, authenticated;


/*
 * Reassert permission untuk RPC v2 dan
 * preference leaderboard.
 */

revoke execute
on function public.get_leaderboard_v2(
  text,
  integer
)
from public, anon;

grant execute
on function public.get_leaderboard_v2(
  text,
  integer
)
to authenticated;


revoke execute
on function
public.get_my_leaderboard_preference()
from public, anon;

grant execute
on function
public.get_my_leaderboard_preference()
to authenticated;


revoke execute
on function
public.set_my_leaderboard_participation(
  boolean,
  text
)
from public, anon;

grant execute
on function
public.set_my_leaderboard_participation(
  boolean,
  text
)
to authenticated;


revoke execute
on function
public.get_my_period_xp()
from public, anon;

grant execute
on function
public.get_my_period_xp()
to authenticated;

commit;