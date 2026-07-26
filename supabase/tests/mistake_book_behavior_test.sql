\set ON_ERROR_STOP on

begin;

create schema if not exists extensions;

create extension if not exists pgtap
with schema extensions;

set local search_path =
  public,
  extensions;

select plan(18);


-- =========================================================
-- 1. STRUCTURE AND ACCESS CONTROL
-- =========================================================

select has_trigger(
  'public',
  'quiz_attempt_items',
  'quiz_attempt_items_sync_mistake_book',
  'Mistake Book synchronization trigger exists'
);

select ok(
  (
    select relation.relrowsecurity
    from pg_class as relation
    join pg_namespace as namespace
      on namespace.oid =
        relation.relnamespace
    where namespace.nspname =
            'public'
      and relation.relname =
            'mistake_book_items'
  ),
  'Row Level Security is enabled for Mistake Book'
);

select is(
  jsonb_build_object(
    'anonSelect',
    has_table_privilege(
      'anon',
      'public.mistake_book_items',
      'SELECT'
    ),
    'anonInsert',
    has_table_privilege(
      'anon',
      'public.mistake_book_items',
      'INSERT'
    ),
    'anonUpdate',
    has_table_privilege(
      'anon',
      'public.mistake_book_items',
      'UPDATE'
    ),
    'anonDelete',
    has_table_privilege(
      'anon',
      'public.mistake_book_items',
      'DELETE'
    ),
    'authenticatedSelect',
    has_table_privilege(
      'authenticated',
      'public.mistake_book_items',
      'SELECT'
    ),
    'authenticatedInsert',
    has_table_privilege(
      'authenticated',
      'public.mistake_book_items',
      'INSERT'
    ),
    'authenticatedUpdate',
    has_table_privilege(
      'authenticated',
      'public.mistake_book_items',
      'UPDATE'
    ),
    'authenticatedDelete',
    has_table_privilege(
      'authenticated',
      'public.mistake_book_items',
      'DELETE'
    )
  ),
  jsonb_build_object(
    'anonSelect',
    false,
    'anonInsert',
    false,
    'anonUpdate',
    false,
    'anonDelete',
    false,
    'authenticatedSelect',
    false,
    'authenticatedInsert',
    false,
    'authenticatedUpdate',
    false,
    'authenticatedDelete',
    false
  ),
  'Client roles cannot access the Mistake Book table directly'
);

select is(
  jsonb_build_object(
    'authenticatedReadRpc',
    has_function_privilege(
      'authenticated',
      'public.get_my_mistake_book()',
      'EXECUTE'
    ),
    'anonReadRpc',
    has_function_privilege(
      'anon',
      'public.get_my_mistake_book()',
      'EXECUTE'
    ),
    'authenticatedSyncFunction',
    has_function_privilege(
      'authenticated',
      'private.synchronize_mistake_book_item()',
      'EXECUTE'
    ),
    'anonSyncFunction',
    has_function_privilege(
      'anon',
      'private.synchronize_mistake_book_item()',
      'EXECUTE'
    )
  ),
  jsonb_build_object(
    'authenticatedReadRpc',
    true,
    'anonReadRpc',
    false,
    'authenticatedSyncFunction',
    false,
    'anonSyncFunction',
    false
  ),
  'Only authenticated users can execute the public read RPC'
);

set local request.jwt.claim.sub = '';
set local request.jwt.claims = '{}';

select throws_ok(
  $test$
    select public.get_my_mistake_book()
  $test$,
  '42501',
  'Authentication required.',
  'Read RPC rejects a request without an authenticated user'
);


-- =========================================================
-- 2. TEST USERS
-- =========================================================

insert into auth.users (
  id,
  email,
  raw_app_meta_data,
  raw_user_meta_data
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'mistake-book-test-one@example.invalid',
    jsonb_build_object(
      'provider',
      'email',
      'providers',
      jsonb_build_array('email')
    ),
    jsonb_build_object(
      'display_name',
      'Mistake Test One'
    )
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'mistake-book-test-two@example.invalid',
    jsonb_build_object(
      'provider',
      'email',
      'providers',
      jsonb_build_array('email')
    ),
    jsonb_build_object(
      'display_name',
      'Mistake Test Two'
    )
  );


-- =========================================================
-- 3. FIRST STANDARD QUIZ MISTAKE
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000001',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  0,
  1,
  '2026-07-26 01:00:00+00',
  'standard'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000001',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  0,
  1,
  false
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count,
      'firstAttemptMatches',
      item.first_incorrect_attempt_id =
        '10000000-0000-4000-8000-000000000001',
      'latestAttemptMatches',
      item.latest_incorrect_attempt_id =
        '10000000-0000-4000-8000-000000000001',
      'masteredAttemptIsNull',
      item.mastered_attempt_id is null,
      'firstTimeMatches',
      item.first_incorrect_at =
        '2026-07-26 01:00:00+00',
      'lastTimeMatches',
      item.last_incorrect_at =
        '2026-07-26 01:00:00+00'
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'status',
    'needs_review',
    'incorrectCount',
    1,
    'reviewCount',
    0,
    'firstAttemptMatches',
    true,
    'latestAttemptMatches',
    true,
    'masteredAttemptIsNull',
    true,
    'firstTimeMatches',
    true,
    'lastTimeMatches',
    true
  ),
  'A wrong standard answer creates one needs-review item'
);


-- =========================================================
-- 4. STANDARD CORRECT AND UNANSWERED QUESTIONS
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values
  (
    '10000000-0000-4000-8000-000000000002',
    '11111111-1111-4111-8111-111111111111',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    1,
    1,
    '2026-07-26 01:10:00+00',
    'standard'
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    '11111111-1111-4111-8111-111111111111',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    0,
    0,
    '2026-07-26 01:20:00+00',
    'standard'
  );

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values
  (
    '10000000-0000-4000-8000-000000000002',
    's1-01-q02',
    1,
    jsonb_build_object(
      'id',
      's1-01-q02'
    ),
    2,
    2,
    true
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    's1-01-q03',
    1,
    jsonb_build_object(
      'id',
      's1-01-q03'
    ),
    null,
    1,
    false
  );

select is(
  (
    select count(*)::integer
    from public.mistake_book_items
    where user_id =
            '11111111-1111-4111-8111-111111111111'
      and question_id =
            's1-01-q02'
  ),
  0,
  'A correct standard answer does not create a Mistake Book item'
);

select is(
  (
    select count(*)::integer
    from public.mistake_book_items
    where user_id =
            '11111111-1111-4111-8111-111111111111'
      and question_id =
            's1-01-q03'
  ),
  0,
  'An unanswered standard question does not create a Mistake Book item'
);


-- =========================================================
-- 5. REPEATED STANDARD QUIZ MISTAKE
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000004',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  0,
  1,
  '2026-07-26 02:00:00+00',
  'standard'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000004',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  0,
  1,
  false
);

select is(
  (
    select jsonb_build_object(
      'rowCount',
      count(*),
      'incorrectCount',
      max(item.incorrect_count),
      'reviewCount',
      max(item.review_count),
      'status',
      max(item.status),
      'latestAttemptMatches',
      bool_and(
        item.latest_incorrect_attempt_id =
          '10000000-0000-4000-8000-000000000004'
      ),
      'lastTimeMatches',
      bool_and(
        item.last_incorrect_at =
          '2026-07-26 02:00:00+00'
      )
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'rowCount',
    1,
    'incorrectCount',
    2,
    'reviewCount',
    0,
    'status',
    'needs_review',
    'latestAttemptMatches',
    true,
    'lastTimeMatches',
    true
  ),
  'A repeated mistake increments the existing item'
);


-- =========================================================
-- 6. CORRECT MISTAKE REVIEW
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000005',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  1,
  1,
  '2026-07-26 03:00:00+00',
  'mistake_review'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000005',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  1,
  1,
  true
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count,
      'masteredAttemptMatches',
      item.mastered_attempt_id =
        '10000000-0000-4000-8000-000000000005',
      'lastReviewedMatches',
      item.last_reviewed_at =
        '2026-07-26 03:00:00+00',
      'masteredAtMatches',
      item.mastered_at =
        '2026-07-26 03:00:00+00'
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'status',
    'mastered',
    'incorrectCount',
    2,
    'reviewCount',
    1,
    'masteredAttemptMatches',
    true,
    'lastReviewedMatches',
    true,
    'masteredAtMatches',
    true
  ),
  'A correct review marks the item as mastered'
);


-- =========================================================
-- 7. WRONG MISTAKE REVIEW REOPENS THE ITEM
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000006',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  0,
  1,
  '2026-07-26 04:00:00+00',
  'mistake_review'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000006',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  0,
  1,
  false
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count,
      'latestAttemptMatches',
      item.latest_incorrect_attempt_id =
        '10000000-0000-4000-8000-000000000006',
      'masteredAttemptIsNull',
      item.mastered_attempt_id is null,
      'lastIncorrectMatches',
      item.last_incorrect_at =
        '2026-07-26 04:00:00+00',
      'masteredAtIsNull',
      item.mastered_at is null
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'status',
    'needs_review',
    'incorrectCount',
    3,
    'reviewCount',
    2,
    'latestAttemptMatches',
    true,
    'masteredAttemptIsNull',
    true,
    'lastIncorrectMatches',
    true,
    'masteredAtIsNull',
    true
  ),
  'A wrong review reopens the mastered item'
);


-- =========================================================
-- 8. UNANSWERED MISTAKE REVIEW
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000007',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  0,
  0,
  '2026-07-26 05:00:00+00',
  'mistake_review'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000007',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  null,
  1,
  false
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count,
      'latestIncorrectUnchanged',
      item.latest_incorrect_attempt_id =
        '10000000-0000-4000-8000-000000000006',
      'lastIncorrectUnchanged',
      item.last_incorrect_at =
        '2026-07-26 04:00:00+00',
      'lastReviewedMatches',
      item.last_reviewed_at =
        '2026-07-26 05:00:00+00'
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'status',
    'needs_review',
    'incorrectCount',
    3,
    'reviewCount',
    3,
    'latestIncorrectUnchanged',
    true,
    'lastIncorrectUnchanged',
    true,
    'lastReviewedMatches',
    true
  ),
  'An unanswered review increments review count without adding a mistake'
);


-- =========================================================
-- 9. FINAL CORRECT REVIEW
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000008',
  '11111111-1111-4111-8111-111111111111',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  1,
  1,
  '2026-07-26 06:00:00+00',
  'mistake_review'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000008',
  's1-01-q01',
  1,
  jsonb_build_object(
    'id',
    's1-01-q01'
  ),
  1,
  1,
  true
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count,
      'masteredAttemptMatches',
      item.mastered_attempt_id =
        '10000000-0000-4000-8000-000000000008',
      'lastReviewedMatches',
      item.last_reviewed_at =
        '2026-07-26 06:00:00+00',
      'masteredAtMatches',
      item.mastered_at =
        '2026-07-26 06:00:00+00'
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '11111111-1111-4111-8111-111111111111'
      and item.question_id =
            's1-01-q01'
  ),
  jsonb_build_object(
    'status',
    'mastered',
    'incorrectCount',
    3,
    'reviewCount',
    4,
    'masteredAttemptMatches',
    true,
    'lastReviewedMatches',
    true,
    'masteredAtMatches',
    true
  ),
  'A later correct review masters the reopened item again'
);


-- =========================================================
-- 10. SECOND USER FIXTURE
-- =========================================================

insert into public.quiz_attempts (
  id,
  user_id,
  topic_id,
  topic_code,
  topic_title,
  mode,
  question_count,
  correct_answers,
  answered_questions,
  completed_at,
  session_source
)
values (
  '10000000-0000-4000-8000-000000000009',
  '22222222-2222-4222-8222-222222222222',
  'topic-s1-01',
  'S1-01',
  'Kemahiran Insaniah',
  'practice',
  1,
  0,
  1,
  '2026-07-26 07:00:00+00',
  'standard'
);

insert into public.quiz_attempt_items (
  attempt_id,
  question_id,
  question_order,
  question_snapshot,
  selected_option_index,
  correct_option_index,
  is_correct
)
values (
  '10000000-0000-4000-8000-000000000009',
  's1-01-q02',
  1,
  jsonb_build_object(
    'id',
    's1-01-q02'
  ),
  0,
  2,
  false
);

select is(
  (
    select jsonb_build_object(
      'status',
      item.status,
      'incorrectCount',
      item.incorrect_count,
      'reviewCount',
      item.review_count
    )
    from public.mistake_book_items
      as item
    where item.user_id =
            '22222222-2222-4222-8222-222222222222'
      and item.question_id =
            's1-01-q02'
  ),
  jsonb_build_object(
    'status',
    'needs_review',
    'incorrectCount',
    1,
    'reviewCount',
    0
  ),
  'The second user receives an independent Mistake Book item'
);


-- =========================================================
-- 11. RPC USER ISOLATION
-- =========================================================

set local request.jwt.claim.sub =
  '11111111-1111-4111-8111-111111111111';

set local request.jwt.claims =
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

select is(
  (
    select jsonb_build_object(
      'needsReviewCount',
      (response.payload ->>
        'needsReviewCount')::integer,
      'masteredCount',
      (response.payload ->>
        'masteredCount')::integer
    )
    from (
      select public.get_my_mistake_book()
        as payload
    ) as response
  ),
  jsonb_build_object(
    'needsReviewCount',
    0,
    'masteredCount',
    1
  ),
  'User one RPC returns only user one overall counts'
);

select is(
  (
    select jsonb_build_object(
      'topicCount',
      jsonb_array_length(
        response.payload -> 'topics'
      ),
      'topicId',
      response.payload
        -> 'topics'
        -> 0
        ->> 'topicId',
      'topicCode',
      response.payload
        -> 'topics'
        -> 0
        ->> 'topicCode',
      'needsReviewCount',
      (
        response.payload
          -> 'topics'
          -> 0
          ->> 'needsReviewCount'
      )::integer,
      'masteredCount',
      (
        response.payload
          -> 'topics'
          -> 0
          ->> 'masteredCount'
      )::integer
    )
    from (
      select public.get_my_mistake_book()
        as payload
    ) as response
  ),
  jsonb_build_object(
    'topicCount',
    1,
    'topicId',
    'topic-s1-01',
    'topicCode',
    'S1-01',
    'needsReviewCount',
    0,
    'masteredCount',
    1
  ),
  'User one RPC topic summary excludes user two state'
);

set local request.jwt.claim.sub =
  '22222222-2222-4222-8222-222222222222';

set local request.jwt.claims =
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';

select is(
  (
    select jsonb_build_object(
      'needsReviewCount',
      (response.payload ->>
        'needsReviewCount')::integer,
      'masteredCount',
      (response.payload ->>
        'masteredCount')::integer
    )
    from (
      select public.get_my_mistake_book()
        as payload
    ) as response
  ),
  jsonb_build_object(
    'needsReviewCount',
    1,
    'masteredCount',
    0
  ),
  'User two RPC returns only user two overall counts'
);

select is(
  (
    select jsonb_build_object(
      'topicCount',
      jsonb_array_length(
        response.payload -> 'topics'
      ),
      'topicId',
      response.payload
        -> 'topics'
        -> 0
        ->> 'topicId',
      'topicCode',
      response.payload
        -> 'topics'
        -> 0
        ->> 'topicCode',
      'needsReviewCount',
      (
        response.payload
          -> 'topics'
          -> 0
          ->> 'needsReviewCount'
      )::integer,
      'masteredCount',
      (
        response.payload
          -> 'topics'
          -> 0
          ->> 'masteredCount'
      )::integer
    )
    from (
      select public.get_my_mistake_book()
        as payload
    ) as response
  ),
  jsonb_build_object(
    'topicCount',
    1,
    'topicId',
    'topic-s1-01',
    'topicCode',
    'S1-01',
    'needsReviewCount',
    1,
    'masteredCount',
    0
  ),
  'User two RPC topic summary excludes user one state'
);


-- =========================================================
-- 12. FINISH AND REMOVE ALL TEST DATA
-- =========================================================

select *
from finish();

rollback;
