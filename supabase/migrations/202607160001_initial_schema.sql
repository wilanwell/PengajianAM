begin;

-- =========================================================
-- 1. PRIVATE SCHEMA
-- =========================================================

create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;


-- =========================================================
-- 2. PUBLIC TABLES
-- =========================================================

create table if not exists public.profiles (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  display_name text not null
    check (
      char_length(trim(display_name))
      between 2 and 30
    ),

  semester_label text not null
    default 'Semester 1',

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);


create table if not exists public.topics (
  id text primary key,

  code text not null unique,

  semester smallint not null
    check (semester between 1 and 3),

  title text not null
    check (char_length(trim(title)) >= 2),

  description text not null
    default '',

  question_count integer not null
    default 0
    check (question_count >= 0),

  sort_order integer not null
    default 0
    check (sort_order >= 0),

  is_active boolean not null
    default true,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);


create table if not exists public.questions (
  id text primary key,

  topic_id text not null
    references public.topics(id)
    on delete cascade,

  question_text text not null
    check (
      char_length(trim(question_text)) >= 5
    ),

  options jsonb not null,

  shuffle_options boolean not null
    default true,

  sort_order integer not null
    default 0
    check (sort_order >= 0),

  is_active boolean not null
    default true,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint questions_options_are_array
    check (
      jsonb_typeof(options) = 'array'
    ),

  constraint questions_minimum_options
    check (
      jsonb_array_length(options) >= 2
    )
);


create table if not exists public.user_progress (
  user_id uuid primary key
    references auth.users(id)
    on delete cascade,

  total_xp integer not null
    default 0
    check (total_xp >= 0),

  weekly_xp integer not null
    default 0
    check (weekly_xp >= 0),

  monthly_xp integer not null
    default 0
    check (monthly_xp >= 0),

  completed_quizzes integer not null
    default 0
    check (completed_quizzes >= 0),

  total_correct_answers integer not null
    default 0
    check (total_correct_answers >= 0),

  total_quiz_questions integer not null
    default 0
    check (total_quiz_questions >= 0),

  highest_score numeric(5, 2) not null
    default 0
    check (
      highest_score >= 0
      and highest_score <= 100
    ),

  completed_topics integer not null
    default 0
    check (completed_topics >= 0),

  current_streak_days integer not null
    default 0
    check (current_streak_days >= 0),

  best_streak_days integer not null
    default 0
    check (best_streak_days >= 0),

  weekly_answered_questions integer[] not null
    default array[0, 0, 0, 0, 0, 0, 0],

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint weekly_activity_has_seven_days
    check (
      cardinality(weekly_answered_questions) = 7
    )
);


create table if not exists public.quiz_attempts (
  id uuid primary key
    default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  topic_id text
    references public.topics(id)
    on delete set null,

  topic_code text not null
    default '',

  topic_title text not null
    default 'Topik Pengajian AM',

  mode text not null
    check (
      mode in ('practice', 'exam')
    ),

  question_count integer not null
    check (question_count > 0),

  correct_answers integer not null
    check (correct_answers >= 0),

  answered_questions integer not null
    check (answered_questions >= 0),

  elapsed_seconds integer not null
    default 0
    check (elapsed_seconds >= 0),

  earned_xp integer not null
    default 0
    check (earned_xp >= 0),

  auto_submitted boolean not null
    default false,

  completed_at timestamptz not null
    default now(),

  constraint correct_answers_within_total
    check (
      correct_answers <= question_count
    ),

  constraint answered_questions_within_total
    check (
      answered_questions <= question_count
    ),

  constraint correct_answers_within_answered
    check (
      correct_answers <= answered_questions
    )
);


create table if not exists public.quiz_attempt_items (
  id bigint generated always as identity
    primary key,

  attempt_id uuid not null
    references public.quiz_attempts(id)
    on delete cascade,

  question_id text
    references public.questions(id)
    on delete set null,

  question_order integer not null
    check (question_order > 0),

  question_snapshot jsonb not null,

  selected_option_index integer
    check (
      selected_option_index is null
      or selected_option_index >= 0
    ),

  correct_option_index integer not null
    check (correct_option_index >= 0),

  is_correct boolean not null,

  created_at timestamptz not null
    default now(),

  constraint one_question_order_per_attempt
    unique (attempt_id, question_order)
);


-- =========================================================
-- 3. PRIVATE ANSWER TABLE
-- =========================================================

create table if not exists private.question_answers (
  question_id text primary key
    references public.questions(id)
    on delete cascade,

  correct_option_index integer not null
    check (correct_option_index >= 0),

  explanation text not null
    default '',

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);

revoke all
on table private.question_answers
from public, anon, authenticated;


-- =========================================================
-- 4. INDEXES
-- =========================================================

create index if not exists questions_topic_active_index
  on public.questions (
    topic_id,
    is_active,
    sort_order
  );

create index if not exists quiz_attempts_user_date_index
  on public.quiz_attempts (
    user_id,
    completed_at desc
  );

create index if not exists quiz_attempts_topic_index
  on public.quiz_attempts (
    topic_id
  );

create index if not exists quiz_attempt_items_attempt_index
  on public.quiz_attempt_items (
    attempt_id
  );

create index if not exists user_progress_weekly_xp_index
  on public.user_progress (
    weekly_xp desc
  );

create index if not exists user_progress_monthly_xp_index
  on public.user_progress (
    monthly_xp desc
  );


-- =========================================================
-- 5. UPDATED_AT FUNCTION
-- =========================================================

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at = now();

  return new;
end;
$$;


drop trigger if exists profiles_set_updated_at
on public.profiles;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function private.set_updated_at();


drop trigger if exists topics_set_updated_at
on public.topics;

create trigger topics_set_updated_at
before update on public.topics
for each row
execute function private.set_updated_at();


drop trigger if exists questions_set_updated_at
on public.questions;

create trigger questions_set_updated_at
before update on public.questions
for each row
execute function private.set_updated_at();


drop trigger if exists user_progress_set_updated_at
on public.user_progress;

create trigger user_progress_set_updated_at
before update on public.user_progress
for each row
execute function private.set_updated_at();


drop trigger if exists question_answers_set_updated_at
on private.question_answers;

create trigger question_answers_set_updated_at
before update on private.question_answers
for each row
execute function private.set_updated_at();


-- =========================================================
-- 6. VALIDATE CORRECT OPTION INDEX
-- =========================================================

create or replace function private.validate_question_answer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  option_count integer;
begin
  select jsonb_array_length(question.options)
  into option_count
  from public.questions as question
  where question.id = new.question_id;

  if option_count is null then
    raise exception
      'Question % does not exist.',
      new.question_id;
  end if;

  if new.correct_option_index >= option_count then
    raise exception
      'correct_option_index % exceeds option count %.',
      new.correct_option_index,
      option_count;
  end if;

  return new;
end;
$$;


drop trigger if exists validate_question_answer
on private.question_answers;

create trigger validate_question_answer
before insert or update
on private.question_answers
for each row
execute function private.validate_question_answer();


-- =========================================================
-- 7. AUTOMATIC TOPIC QUESTION COUNT
-- =========================================================

create or replace function private.refresh_topic_question_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    update public.topics
    set question_count = (
      select count(*)
      from public.questions
      where topic_id = old.topic_id
        and is_active = true
    )
    where id = old.topic_id;

    return null;
  end if;

  if tg_op = 'INSERT' then
    update public.topics
    set question_count = (
      select count(*)
      from public.questions
      where topic_id = new.topic_id
        and is_active = true
    )
    where id = new.topic_id;

    return null;
  end if;

  if tg_op = 'UPDATE' then
    update public.topics
    set question_count = (
      select count(*)
      from public.questions
      where topic_id = old.topic_id
        and is_active = true
    )
    where id = old.topic_id;

    update public.topics
    set question_count = (
      select count(*)
      from public.questions
      where topic_id = new.topic_id
        and is_active = true
    )
    where id = new.topic_id;

    return null;
  end if;

  return null;
end;
$$;


drop trigger if exists questions_refresh_count_insert
on public.questions;

create trigger questions_refresh_count_insert
after insert on public.questions
for each row
execute function private.refresh_topic_question_count();


drop trigger if exists questions_refresh_count_delete
on public.questions;

create trigger questions_refresh_count_delete
after delete on public.questions
for each row
execute function private.refresh_topic_question_count();


drop trigger if exists questions_refresh_count_update
on public.questions;

create trigger questions_refresh_count_update
after update of topic_id, is_active
on public.questions
for each row
execute function private.refresh_topic_question_count();


-- =========================================================
-- 8. CREATE PROFILE AND PROGRESS AFTER SIGN-UP
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_display_name text;
begin
  resolved_display_name :=
    nullif(
      trim(
        coalesce(
          new.raw_user_meta_data ->> 'display_name',
          ''
        )
      ),
      ''
    );

  if resolved_display_name is null then
    resolved_display_name :=
      nullif(
        split_part(
          coalesce(new.email, ''),
          '@',
          1
        ),
        ''
      );
  end if;

  if resolved_display_name is null
     or char_length(resolved_display_name) < 2 then
    resolved_display_name := 'Pelajar';
  end if;

  resolved_display_name :=
    left(resolved_display_name, 30);

  insert into public.profiles (
    id,
    display_name
  )
  values (
    new.id,
    resolved_display_name
  )
  on conflict (id) do nothing;

  insert into public.user_progress (
    user_id
  )
  values (
    new.id
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;


revoke execute
on function public.handle_new_user()
from public, anon, authenticated;


drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();


-- =========================================================
-- 9. ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table public.profiles
  enable row level security;

alter table public.topics
  enable row level security;

alter table public.questions
  enable row level security;

alter table public.user_progress
  enable row level security;

alter table public.quiz_attempts
  enable row level security;

alter table public.quiz_attempt_items
  enable row level security;


-- =========================================================
-- 10. REVOKE DEFAULT DATA API PRIVILEGES
-- =========================================================

revoke all
on table public.profiles
from anon, authenticated;

revoke all
on table public.topics
from anon, authenticated;

revoke all
on table public.questions
from anon, authenticated;

revoke all
on table public.user_progress
from anon, authenticated;

revoke all
on table public.quiz_attempts
from anon, authenticated;

revoke all
on table public.quiz_attempt_items
from anon, authenticated;


-- =========================================================
-- 11. GRANT MINIMUM REQUIRED PRIVILEGES
-- =========================================================

grant usage
on schema public
to authenticated;

grant select, insert, update
on table public.profiles
to authenticated;

grant select
on table public.topics
to authenticated;

grant select
on table public.questions
to authenticated;

grant select
on table public.user_progress
to authenticated;

grant select
on table public.quiz_attempts
to authenticated;

grant select
on table public.quiz_attempt_items
to authenticated;


-- =========================================================
-- 12. RLS POLICIES: PROFILES
-- =========================================================

drop policy if exists profiles_select_own
on public.profiles;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);


drop policy if exists profiles_insert_own
on public.profiles;

create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);


drop policy if exists profiles_update_own
on public.profiles;

create policy profiles_update_own
on public.profiles
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);


-- =========================================================
-- 13. RLS POLICIES: TOPICS
-- =========================================================

drop policy if exists topics_select_active
on public.topics;

create policy topics_select_active
on public.topics
for select
to authenticated
using (
  is_active = true
);


-- =========================================================
-- 14. RLS POLICIES: QUESTIONS
-- =========================================================

drop policy if exists questions_select_active
on public.questions;

create policy questions_select_active
on public.questions
for select
to authenticated
using (
  is_active = true
  and exists (
    select 1
    from public.topics
    where public.topics.id =
      public.questions.topic_id
      and public.topics.is_active = true
  )
);


-- =========================================================
-- 15. RLS POLICIES: USER PROGRESS
-- =========================================================

drop policy if exists user_progress_select_own
on public.user_progress;

create policy user_progress_select_own
on public.user_progress
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);


-- =========================================================
-- 16. RLS POLICIES: QUIZ ATTEMPTS
-- =========================================================

drop policy if exists quiz_attempts_select_own
on public.quiz_attempts;

create policy quiz_attempts_select_own
on public.quiz_attempts
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);


-- =========================================================
-- 17. RLS POLICIES: QUIZ ATTEMPT ITEMS
-- =========================================================

drop policy if exists quiz_attempt_items_select_own
on public.quiz_attempt_items;

create policy quiz_attempt_items_select_own
on public.quiz_attempt_items
for select
to authenticated
using (
  exists (
    select 1
    from public.quiz_attempts
    where public.quiz_attempts.id =
      public.quiz_attempt_items.attempt_id
      and public.quiz_attempts.user_id =
        (select auth.uid())
  )
);


-- =========================================================
-- 18. INITIAL TOPICS
-- =========================================================

insert into public.topics (
  id,
  code,
  semester,
  title,
  description,
  sort_order,
  is_active
)
values
  (
    'topic-s1-01',
    'S1-01',
    1,
    'Kemahiran Insaniah',
    'Kemahiran mencari maklumat, menganalisis data, menyelesaikan masalah dan membuat keputusan.',
    1,
    true
  ),
  (
    'topic-s1-02',
    'S1-02',
    1,
    'Negara Berdaulat',
    'Konsep, ciri dan kepentingan sesebuah negara yang berdaulat.',
    2,
    true
  ),
  (
    'topic-s1-03',
    'S1-03',
    1,
    'Perlembagaan Persekutuan',
    'Pembentukan, keluhuran, pindaan dan peruntukan utama Perlembagaan Persekutuan.',
    3,
    true
  ),
  (
    'topic-s1-04',
    'S1-04',
    1,
    'Perjanjian Malaysia 1963',
    'Latar belakang, kandungan dan kepentingan Perjanjian Malaysia 1963.',
    4,
    true
  ),
  (
    'topic-s1-05',
    'S1-05',
    1,
    'Tadbir Urus Baik',
    'Konsep, prinsip, kepentingan dan cabaran pelaksanaan tadbir urus yang baik.',
    5,
    true
  ),
  (
    'topic-s1-06',
    'S1-06',
    1,
    'Sistem dan Struktur Pemerintahan',
    'Badan perundangan, eksekutif, kehakiman dan struktur pentadbiran Malaysia.',
    6,
    true
  ),
  (
    'topic-s1-07',
    'S1-07',
    1,
    'Kedaulatan Malaysia',
    'Isu, cabaran dan strategi mempertahankan kedaulatan serta perpaduan negara.',
    7,
    true
  )
on conflict (id)
do update set
  code = excluded.code,
  semester = excluded.semester,
  title = excluded.title,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;


commit;