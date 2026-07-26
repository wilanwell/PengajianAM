begin;

-- =========================================================
-- M08 MISTAKE BOOK: DATABASE SCHEMA
-- =========================================================

/*
 * Business rules:
 *
 * 1. One row represents one user's learning state
 *    for one question.
 * 2. Wrong answers are marked as needs_review.
 * 3. Correct answers from a dedicated Mistake Book
 *    review may mark an item as mastered.
 * 4. A later wrong answer may reopen a mastered item.
 * 5. Review sessions must remain separate from
 *    standard quiz metrics and XP.
 */


-- =========================================================
-- 1. QUIZ SESSION PROVENANCE
-- =========================================================

alter table private.quiz_sessions
add column session_source text
not null
default 'standard';

alter table private.quiz_sessions
add constraint quiz_sessions_session_source_check
check (
  session_source in (
    'standard',
    'mistake_review'
  )
);

create index quiz_sessions_user_source_created_index
on private.quiz_sessions (
  user_id,
  session_source,
  created_at desc
);

comment on column
private.quiz_sessions.session_source
is
  'Identifies whether a session is a standard quiz '
  'or a dedicated Mistake Book review.';


-- =========================================================
-- 2. QUIZ ATTEMPT PROVENANCE
-- =========================================================

alter table public.quiz_attempts
add column session_source text
not null
default 'standard';

alter table public.quiz_attempts
add constraint quiz_attempts_session_source_check
check (
  session_source in (
    'standard',
    'mistake_review'
  )
);

create index quiz_attempts_user_source_date_index
on public.quiz_attempts (
  user_id,
  session_source,
  completed_at desc
);

comment on column
public.quiz_attempts.session_source
is
  'Preserves whether an attempt originated from a '
  'standard quiz or a Mistake Book review.';


-- =========================================================
-- 3. USER QUESTION LEARNING STATE
-- =========================================================

create table public.mistake_book_items (
  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  question_id text not null
    references public.questions(id)
    on delete cascade,

  topic_id text not null
    references public.topics(id)
    on delete cascade,

  status text not null
    default 'needs_review',

  incorrect_count integer not null
    default 1,

  review_count integer not null
    default 0,

  first_incorrect_attempt_id uuid
    references public.quiz_attempts(id)
    on delete set null,

  latest_incorrect_attempt_id uuid
    references public.quiz_attempts(id)
    on delete set null,

  mastered_attempt_id uuid
    references public.quiz_attempts(id)
    on delete set null,

  first_incorrect_at timestamptz not null,

  last_incorrect_at timestamptz not null,

  last_reviewed_at timestamptz,

  mastered_at timestamptz,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  primary key (
    user_id,
    question_id
  ),

  constraint mistake_book_items_status_check
  check (
    status in (
      'needs_review',
      'mastered'
    )
  ),

  constraint mistake_book_items_incorrect_count_check
  check (
    incorrect_count > 0
  ),

  constraint mistake_book_items_review_count_check
  check (
    review_count >= 0
  ),

  constraint mistake_book_items_incorrect_timeline_check
  check (
    last_incorrect_at >= first_incorrect_at
  ),

  constraint mistake_book_items_review_timeline_check
  check (
    last_reviewed_at is null
    or last_reviewed_at >= first_incorrect_at
  ),

  constraint mistake_book_items_review_state_check
  check (
    (
      review_count = 0
      and last_reviewed_at is null
    )
    or
    (
      review_count > 0
      and last_reviewed_at is not null
    )
  ),

  constraint mistake_book_items_mastery_state_check
  check (
    (
      status = 'needs_review'
      and mastered_at is null
    )
    or
    (
      status = 'mastered'
      and mastered_at is not null
      and review_count > 0
    )
  )
);

comment on table public.mistake_book_items
is
  'Server-authoritative per-user learning state '
  'for questions answered incorrectly.';

comment on column
public.mistake_book_items.status
is
  'Current learning state: needs_review or mastered.';

comment on column
public.mistake_book_items.incorrect_count
is
  'Number of answered attempts in which the user '
  'answered this question incorrectly.';

comment on column
public.mistake_book_items.review_count
is
  'Number of times the question was presented in '
  'a dedicated Mistake Book review session.';


-- =========================================================
-- 4. QUERY AND FOREIGN-KEY INDEXES
-- =========================================================

create index mistake_book_user_status_updated_index
on public.mistake_book_items (
  user_id,
  status,
  updated_at desc
);

create index mistake_book_user_topic_status_index
on public.mistake_book_items (
  user_id,
  topic_id,
  status,
  last_incorrect_at desc
);

create index mistake_book_needs_review_queue_index
on public.mistake_book_items (
  user_id,
  topic_id,
  last_reviewed_at asc nulls first,
  last_incorrect_at desc
)
where status = 'needs_review';

create index mistake_book_question_fk_index
on public.mistake_book_items (
  question_id
);

create index mistake_book_topic_fk_index
on public.mistake_book_items (
  topic_id
);

create index mistake_book_first_attempt_fk_index
on public.mistake_book_items (
  first_incorrect_attempt_id
)
where first_incorrect_attempt_id is not null;

create index mistake_book_latest_attempt_fk_index
on public.mistake_book_items (
  latest_incorrect_attempt_id
)
where latest_incorrect_attempt_id is not null;

create index mistake_book_mastered_attempt_fk_index
on public.mistake_book_items (
  mastered_attempt_id
)
where mastered_attempt_id is not null;


-- =========================================================
-- 5. UPDATED-AT AUTOMATION
-- =========================================================

create trigger mistake_book_items_set_updated_at
before update
on public.mistake_book_items
for each row
execute function private.set_updated_at();


-- =========================================================
-- 6. DEFENCE-IN-DEPTH ACCESS CONTROL
-- =========================================================

alter table public.mistake_book_items
enable row level security;

revoke all
on table public.mistake_book_items
from public, anon, authenticated;

create policy mistake_book_items_select_own
on public.mistake_book_items
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

/*
 * No INSERT, UPDATE or DELETE policy is provided.
 *
 * Future state changes will only be performed by
 * controlled security-definer RPC functions.
 */


-- =========================================================
-- 7. BACKFILL EXISTING WRONG ANSWERS
-- =========================================================

with historical_mistakes as (
  select
    attempt.user_id,
    attempt_item.question_id,
    question.topic_id,

    (
      array_agg(
        attempt.id
        order by
          attempt.completed_at asc,
          attempt_item.id asc
      )
    )[1] as first_attempt_id,

    (
      array_agg(
        attempt.id
        order by
          attempt.completed_at desc,
          attempt_item.id desc
      )
    )[1] as latest_attempt_id,

    count(*)::integer
      as incorrect_count,

    min(attempt.completed_at)
      as first_incorrect_at,

    max(attempt.completed_at)
      as last_incorrect_at

  from public.quiz_attempt_items
    as attempt_item

  join public.quiz_attempts
    as attempt
    on attempt.id =
      attempt_item.attempt_id

  join public.questions
    as question
    on question.id =
      attempt_item.question_id

  where attempt_item.question_id
          is not null
    and attempt_item.selected_option_index
          is not null
    and attempt_item.is_correct = false

  group by
    attempt.user_id,
    attempt_item.question_id,
    question.topic_id
)

insert into public.mistake_book_items (
  user_id,
  question_id,
  topic_id,
  status,
  incorrect_count,
  review_count,
  first_incorrect_attempt_id,
  latest_incorrect_attempt_id,
  first_incorrect_at,
  last_incorrect_at
)
select
  historical.user_id,
  historical.question_id,
  historical.topic_id,
  'needs_review',
  historical.incorrect_count,
  0,
  historical.first_attempt_id,
  historical.latest_attempt_id,
  historical.first_incorrect_at,
  historical.last_incorrect_at
from historical_mistakes
  as historical
on conflict (
  user_id,
  question_id
)
do nothing;

commit;