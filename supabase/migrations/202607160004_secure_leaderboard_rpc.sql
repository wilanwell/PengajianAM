begin;

-- =========================================================
-- SECURE LEADERBOARD RPC
-- =========================================================

create or replace function public.get_leaderboard(
  p_period text,
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_current_display_name text;
  v_current_xp integer;
  v_current_rank integer;

  v_participant_count integer;
  v_entries jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_period is null
     or p_period not in (
       'weekly',
       'monthly'
     ) then
    raise exception using
      errcode = '22023',
      message =
        'period must be weekly or monthly.';
  end if;

  if p_limit is null
     or p_limit < 3
     or p_limit > 100 then
    raise exception using
      errcode = '22023',
      message =
        'limit must be between 3 and 100.';
  end if;

  select
    profile.display_name
  into
    v_current_display_name
  from public.profiles as profile
  where profile.id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message = 'User profile was not found.';
  end if;

  select
    case
      when p_period = 'weekly' then
        progress.weekly_xp

      else
        progress.monthly_xp
    end
  into
    v_current_xp
  from public.user_progress as progress
  where progress.user_id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message = 'User progress was not found.';
  end if;

  /*
   * Hanya pengguna yang mempunyai XP bagi tempoh
   * tersebut dimasukkan dalam ranking utama.
   *
   * row_number digunakan supaya setiap pengguna
   * mempunyai satu nombor ranking yang unik.
   *
   * Jika XP sama, entry ID yang dianonimkan
   * digunakan sebagai tie-breaker.
   */
  with ranked_entries as (
    select
      progress.user_id,

      md5(
        progress.user_id::text
      ) as entry_id,

      case
        when progress.user_id = v_user_id then
          profile.display_name

        else
          'Pelajar-' ||
          upper(
            substr(
              md5(
                progress.user_id::text
              ),
              1,
              4
            )
          )
      end as nickname,

      case
        when p_period = 'weekly' then
          progress.weekly_xp

        else
          progress.monthly_xp
      end as xp,

      row_number() over (
        order by
          case
            when p_period = 'weekly' then
              progress.weekly_xp

            else
              progress.monthly_xp
          end desc,

          md5(
            progress.user_id::text
          ) asc
      )::integer as rank,

      progress.user_id =
        v_user_id as is_current_user

    from public.user_progress as progress

    join public.profiles as profile
      on profile.id =
        progress.user_id

    where
      case
        when p_period = 'weekly' then
          progress.weekly_xp

        else
          progress.monthly_xp
      end > 0
  ),

  selected_entries as (
    select
      ranked.entry_id,
      ranked.nickname,
      ranked.rank,
      ranked.xp,
      ranked.is_current_user

    from ranked_entries as ranked

    where ranked.rank <= p_limit
       or ranked.is_current_user = true
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'entryId',
        selected.entry_id,

        'nickname',
        selected.nickname,

        'rank',
        selected.rank,

        'xp',
        selected.xp,

        /*
         * Previous rank belum tersedia kerana
         * historical leaderboard snapshots
         * belum dibina.
         */
        'previousRank',
        null,

        'isCurrentUser',
        selected.is_current_user
      )
      order by selected.rank
    ),
    '[]'::jsonb
  )
  into v_entries
  from selected_entries as selected;

  select
    count(*)::integer
  into
    v_participant_count
  from public.user_progress as progress
  where
    case
      when p_period = 'weekly' then
        progress.weekly_xp

      else
        progress.monthly_xp
    end > 0;

  /*
   * Pengguna semasa tetap dipaparkan walaupun
   * masih mempunyai 0 XP.
   */
  if v_current_xp = 0 then
    v_current_rank :=
      v_participant_count + 1;

    v_entries :=
      v_entries ||
      jsonb_build_array(
        jsonb_build_object(
          'entryId',
          md5(
            v_user_id::text
          ),

          'nickname',
          v_current_display_name,

          'rank',
          v_current_rank,

          'xp',
          0,

          'previousRank',
          null,

          'isCurrentUser',
          true
        )
      );

    v_participant_count :=
      v_participant_count + 1;
  end if;

  return jsonb_build_object(
    'period',
    p_period,

    'generatedAt',
    now(),

    'participantCount',
    v_participant_count,

    'entries',
    v_entries
  );
end;
$$;


-- Database functions boleh mempunyai EXECUTE permission
-- secara lalai, jadi permission dibuang terlebih dahulu.

revoke execute
on function public.get_leaderboard(
  text,
  integer
)
from public, anon;

grant execute
on function public.get_leaderboard(
  text,
  integer
)
to authenticated;

commit;