begin;

-- Hentikan migration jika data consent berubah menjadi tidak sah
-- selepas audit terakhir. Tiada consent akan diubah secara automatik.
do $$
begin
  if exists (
    select 1
    from public.profiles
    where
      leaderboard_opt_in is null

      or (
        leaderboard_opt_in is true
        and (
          leaderboard_consent_at is null
          or leaderboard_consent_version is distinct from '1.0'
        )
      )

      or (
        leaderboard_opt_in is false
        and (
          leaderboard_consent_at is not null
          or leaderboard_consent_version is not null
        )
      )
  ) then
    raise exception
      'Leaderboard consent data is invalid. Migration cancelled without changing data.';
  end if;
end;
$$;

alter table public.profiles
  drop constraint profiles_leaderboard_consent_consistency;

alter table public.profiles
  add constraint profiles_leaderboard_consent_consistency
  check (
    (
      leaderboard_opt_in is false
      and leaderboard_consent_at is null
      and leaderboard_consent_version is null
    )
    or
    (
      leaderboard_opt_in is true
      and leaderboard_consent_at is not null
      and leaderboard_consent_version is not distinct from '1.0'
    )
  );

comment on constraint profiles_leaderboard_consent_consistency
  on public.profiles
  is
    'Opted-in profiles must have consent timestamp and current consent version 1.0. Opted-out profiles must not retain active consent metadata.';

commit;
