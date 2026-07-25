begin;

-- =========================================================
-- LEADERBOARD PRIVACY AND REAL TIME PERIODS
-- =========================================================

/*
 * Migration ini menyediakan:
 *
 * 1. Explicit leaderboard opt-in / opt-out.
 * 2. Consent timestamp dan policy version.
 * 3. Immutable consent event history.
 * 4. Weekly dan monthly XP berdasarkan
 *    quiz_attempts.completed_at.
 * 5. Period-scoped pseudonymous identifiers.
 * 6. RPC v2 yang menyokong pengguna opt-out.
 *
 * RPC get_leaderboard() lama belum diubah
 * dalam migration ini supaya Flutter lama
 * tidak terputus sebelum client v2 siap.
 */


-- =========================================================
-- 1. PROFILE PRIVACY PREFERENCE
-- =========================================================

alter table public.profiles
add column if not exists
  leaderboard_opt_in boolean
  not null
  default false;

alter table public.profiles
add column if not exists
  leaderboard_consent_at timestamptz;

alter table public.profiles
add column if not exists
  leaderboard_consent_version text;

alter table public.profiles
drop constraint if exists
  profiles_leaderboard_consent_consistency;

alter table public.profiles
add constraint
  profiles_leaderboard_consent_consistency
check (
  (
    leaderboard_opt_in = false
    and leaderboard_consent_at is null
    and leaderboard_consent_version is null
  )
  or
  (
    leaderboard_opt_in = true
    and leaderboard_consent_at is not null
    and leaderboard_consent_version is not null
    and char_length(
      trim(
        leaderboard_consent_version
      )
    ) between 1 and 20
  )
);

create index if not exists
profiles_leaderboard_opt_in_index
on public.profiles (
  id
)
where leaderboard_opt_in = true;


-- =========================================================
-- 2. CONSENT EVENT HISTORY
-- =========================================================

create table if not exists
private.leaderboard_consent_events (
  id bigint generated always as identity
    primary key,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  opted_in boolean not null,

  policy_version text not null
    check (
      char_length(
        trim(policy_version)
      ) between 1 and 20
    ),

  changed_at timestamptz not null
    default clock_timestamp()
);

create index if not exists
leaderboard_consent_events_user_date_index
on private.leaderboard_consent_events (
  user_id,
  changed_at desc
);

revoke all
on table private.leaderboard_consent_events
from public, anon, authenticated;


-- =========================================================
-- 3. INDEX FOR PERIOD-BASED XP
-- =========================================================

create index if not exists
quiz_attempts_completed_user_xp_index
on public.quiz_attempts (
  completed_at,
  user_id
)
include (
  earned_xp
);


-- =========================================================
-- 4. GET MY LEADERBOARD PREFERENCE
-- =========================================================

create or replace function
public.get_my_leaderboard_preference()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_opt_in boolean;
  v_consent_at timestamptz;
  v_consent_version text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  select
    profile.leaderboard_opt_in,
    profile.leaderboard_consent_at,
    profile.leaderboard_consent_version
  into
    v_opt_in,
    v_consent_at,
    v_consent_version
  from public.profiles as profile
  where profile.id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'User profile was not found.';
  end if;

  return jsonb_build_object(
    'optedIn',
    v_opt_in,

    'consentAt',
    v_consent_at,

    'consentVersion',
    v_consent_version,

    'requiredConsentVersion',
    '1.0',

    'serverTime',
    clock_timestamp()
  );
end;
$$;

revoke execute
on function
public.get_my_leaderboard_preference()
from public, anon, authenticated;

grant execute
on function
public.get_my_leaderboard_preference()
to authenticated;


-- =========================================================
-- 5. CHANGE MY LEADERBOARD PARTICIPATION
-- =========================================================

create or replace function
public.set_my_leaderboard_participation(
  p_opt_in boolean,
  p_consent_version text default '1.0'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_normalized_version text;
  v_changed_at timestamptz;

  v_consent_at timestamptz;
  v_stored_version text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  if p_opt_in is null then
    raise exception using
      errcode = '22023',
      message =
        'opt_in is required.';
  end if;

  v_normalized_version :=
    nullif(
      trim(
        coalesce(
          p_consent_version,
          ''
        )
      ),
      ''
    );

  if v_normalized_version is null
     or char_length(
       v_normalized_version
     ) > 20 then
    raise exception using
      errcode = '22023',
      message =
        'consent_version is invalid.';
  end if;

  v_changed_at := clock_timestamp();

  if p_opt_in then
    v_consent_at := v_changed_at;
    v_stored_version :=
      v_normalized_version;

  else
    v_consent_at := null;
    v_stored_version := null;
  end if;

  update public.profiles
  set
    leaderboard_opt_in =
      p_opt_in,

    leaderboard_consent_at =
      v_consent_at,

    leaderboard_consent_version =
      v_stored_version
  where id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'User profile was not found.';
  end if;

  insert into
  private.leaderboard_consent_events (
    user_id,
    opted_in,
    policy_version,
    changed_at
  )
  values (
    v_user_id,
    p_opt_in,
    v_normalized_version,
    v_changed_at
  );

  return jsonb_build_object(
    'optedIn',
    p_opt_in,

    'consentAt',
    v_consent_at,

    'consentVersion',
    v_stored_version,

    'requiredConsentVersion',
    '1.0',

    'changedAt',
    v_changed_at,

    'serverTime',
    clock_timestamp()
  );
end;
$$;

revoke execute
on function
public.set_my_leaderboard_participation(
  boolean,
  text
)
from public, anon, authenticated;

grant execute
on function
public.set_my_leaderboard_participation(
  boolean,
  text
)
to authenticated;


-- =========================================================
-- 6. GET MY REAL WEEKLY AND MONTHLY XP
-- =========================================================

create or replace function
public.get_my_period_xp()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_server_time timestamptz;
  v_local_time timestamp without time zone;

  v_week_local_start
    timestamp without time zone;

  v_week_local_end
    timestamp without time zone;

  v_month_local_start
    timestamp without time zone;

  v_month_local_end
    timestamp without time zone;

  v_week_start timestamptz;
  v_week_end timestamptz;

  v_month_start timestamptz;
  v_month_end timestamptz;

  v_weekly_xp integer;
  v_monthly_xp integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  v_server_time := clock_timestamp();

  v_local_time :=
    v_server_time
      at time zone
      'Asia/Kuala_Lumpur';

  /*
   * date_trunc('week') bermula pada Isnin.
   */
  v_week_local_start :=
    date_trunc(
      'week',
      v_local_time
    );

  v_week_local_end :=
    v_week_local_start +
    interval '1 week';

  v_month_local_start :=
    date_trunc(
      'month',
      v_local_time
    );

  v_month_local_end :=
    v_month_local_start +
    interval '1 month';

  v_week_start :=
    v_week_local_start
      at time zone
      'Asia/Kuala_Lumpur';

  v_week_end :=
    v_week_local_end
      at time zone
      'Asia/Kuala_Lumpur';

  v_month_start :=
    v_month_local_start
      at time zone
      'Asia/Kuala_Lumpur';

  v_month_end :=
    v_month_local_end
      at time zone
      'Asia/Kuala_Lumpur';

  select
    coalesce(
      sum(
        attempt.earned_xp
      ) filter (
        where
          attempt.completed_at >=
            v_week_start
          and
          attempt.completed_at <
            v_week_end
      ),
      0
    )::integer,

    coalesce(
      sum(
        attempt.earned_xp
      ) filter (
        where
          attempt.completed_at >=
            v_month_start
          and
          attempt.completed_at <
            v_month_end
      ),
      0
    )::integer
  into
    v_weekly_xp,
    v_monthly_xp
  from public.quiz_attempts
    as attempt
  where attempt.user_id = v_user_id;

  return jsonb_build_object(
    'weeklyXp',
    v_weekly_xp,

    'monthlyXp',
    v_monthly_xp,

    'weekStartsAt',
    v_week_start,

    'weekEndsAt',
    v_week_end,

    'monthStartsAt',
    v_month_start,

    'monthEndsAt',
    v_month_end,

    'timezone',
    'Asia/Kuala_Lumpur',

    'serverTime',
    v_server_time
  );
end;
$$;

revoke execute
on function
public.get_my_period_xp()
from public, anon, authenticated;

grant execute
on function
public.get_my_period_xp()
to authenticated;


-- =========================================================
-- 7. LEADERBOARD V2
-- =========================================================

create or replace function
public.get_leaderboard_v2(
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
  v_is_participating boolean;
  v_current_user_xp integer;

  v_server_time timestamptz;
  v_local_time timestamp without time zone;

  v_local_period_start
    timestamp without time zone;

  v_local_period_end
    timestamp without time zone;

  v_period_start timestamptz;
  v_period_end timestamptz;

  v_participant_count integer;
  v_entries jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message =
        'Authentication required.';
  end if;

  if p_period is null
     or p_period not in (
       'weekly',
       'monthly'
     ) then
    raise exception using
      errcode = '22023',
      message =
        'period must be weekly '
        'or monthly.';
  end if;

  if p_limit is null
     or p_limit < 3
     or p_limit > 100 then
    raise exception using
      errcode = '22023',
      message =
        'limit must be between '
        '3 and 100.';
  end if;

  select
    profile.display_name,
    profile.leaderboard_opt_in
  into
    v_current_display_name,
    v_is_participating
  from public.profiles as profile
  where profile.id = v_user_id;

  if not found then
    raise exception using
      errcode = '22023',
      message =
        'User profile was not found.';
  end if;

  v_server_time := clock_timestamp();

  v_local_time :=
    v_server_time
      at time zone
      'Asia/Kuala_Lumpur';

  if p_period = 'weekly' then
    v_local_period_start :=
      date_trunc(
        'week',
        v_local_time
      );

    v_local_period_end :=
      v_local_period_start +
      interval '1 week';

  else
    v_local_period_start :=
      date_trunc(
        'month',
        v_local_time
      );

    v_local_period_end :=
      v_local_period_start +
      interval '1 month';
  end if;

  v_period_start :=
    v_local_period_start
      at time zone
      'Asia/Kuala_Lumpur';

  v_period_end :=
    v_local_period_end
      at time zone
      'Asia/Kuala_Lumpur';

  select
    coalesce(
      sum(
        attempt.earned_xp
      ),
      0
    )::integer
  into
    v_current_user_xp
  from public.quiz_attempts
    as attempt
  where attempt.user_id =
          v_user_id
    and attempt.completed_at >=
          v_period_start
    and attempt.completed_at <
          v_period_end;

  /*
   * Semua pengguna yang memilih opt-in
   * dianggap peserta, termasuk pengguna
   * yang masih mempunyai 0 XP.
   */
  select count(*)::integer
  into v_participant_count
  from public.profiles as profile
  where profile.leaderboard_opt_in =
          true;

  with participant_xp as (
    select
      profile.id as user_id,

      profile.display_name,

      coalesce(
        sum(
          attempt.earned_xp
        ),
        0
      )::integer as xp,

      md5(
        profile.id::text
        || ':'
        || p_period
        || ':'
        || v_period_start::text
      ) as period_entry_id

    from public.profiles as profile

    left join public.quiz_attempts
      as attempt
      on attempt.user_id =
           profile.id
     and attempt.completed_at >=
           v_period_start
     and attempt.completed_at <
           v_period_end

    where profile.leaderboard_opt_in =
            true

    group by
      profile.id,
      profile.display_name
  ),

  ranked_entries as (
    select
      participant.user_id,

      participant.display_name,

      participant.xp,

      participant.period_entry_id,

      row_number() over (
        order by
          participant.xp desc,
          participant.period_entry_id asc
      )::integer as rank,

      participant.user_id =
        v_user_id as is_current_user

    from participant_xp as participant
  ),

  selected_entries as (
    select
      ranked.user_id,
      ranked.display_name,
      ranked.xp,
      ranked.period_entry_id,
      ranked.rank,
      ranked.is_current_user

    from ranked_entries as ranked

    where ranked.rank <= p_limit
       or ranked.is_current_user = true
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'entryId',
        selected.period_entry_id,

        'nickname',
        case
          when selected.is_current_user then
            selected.display_name

          else
            'Pelajar-'
            ||
            upper(
              substr(
                selected.period_entry_id,
                1,
                4
              )
            )
        end,

        'rank',
        selected.rank,

        'xp',
        selected.xp,

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

  return jsonb_build_object(
    'period',
    p_period,

    'periodStartsAt',
    v_period_start,

    'periodEndsAt',
    v_period_end,

    'timezone',
    'Asia/Kuala_Lumpur',

    'generatedAt',
    v_server_time,

    'isParticipating',
    v_is_participating,

    'currentUserXp',
    v_current_user_xp,

    'participantCount',
    v_participant_count,

    'entries',
    v_entries
  );
end;
$$;

revoke execute
on function
public.get_leaderboard_v2(
  text,
  integer
)
from public, anon, authenticated;

grant execute
on function
public.get_leaderboard_v2(
  text,
  integer
)
to authenticated;


/*
 * get_leaderboard() lama masih aktif
 * sementara Flutter dikemas kini.
 */

commit;