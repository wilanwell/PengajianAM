begin;

select plan(9);


-- =========================================================
-- 1. FUNCTION AND PRIVILEGE CONTRACT
-- =========================================================

select ok(
  to_regprocedure(
    'public.get_my_mistake_book_topic(text)'
  ) is not null,
  'Mistake Book topic detail RPC exists'
);

select is(
  jsonb_build_object(
    'authenticatedExecute',
    has_function_privilege(
      'authenticated',
      'public.get_my_mistake_book_topic(text)',
      'EXECUTE'
    ),
    'anonExecute',
    has_function_privilege(
      'anon',
      'public.get_my_mistake_book_topic(text)',
      'EXECUTE'
    )
  ),
  jsonb_build_object(
    'authenticatedExecute',
    true,
    'anonExecute',
    false
  ),
  'Only authenticated users can execute the detail RPC'
);

set local request.jwt.claim.sub = '';
set local request.jwt.claims = '{}';

select throws_ok(
  $test$
    select public.get_my_mistake_book_topic(
      'topic-s1-01'
    )
  $test$,
  '42501',
  'Authentication required.',
  'Detail RPC rejects a request without a user'
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
    '33333333-3333-4333-8333-333333333333',
    'mistake-detail-one@example.invalid',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Mistake Detail One"}'::jsonb
  ),
  (
    '44444444-4444-4444-8444-444444444444',
    'mistake-detail-two@example.invalid',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Mistake Detail Two"}'::jsonb
  );


-- =========================================================
-- 3. STANDARD AND REVIEW ATTEMPTS
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
    '30000000-0000-4000-8000-000000000001',
    '33333333-3333-4333-8333-333333333333',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    0,
    1,
    '2026-07-27 01:00:00+00',
    'standard'
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    '33333333-3333-4333-8333-333333333333',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    0,
    1,
    '2026-07-27 02:00:00+00',
    'standard'
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    '33333333-3333-4333-8333-333333333333',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    1,
    1,
    '2026-07-27 03:00:00+00',
    'mistake_review'
  ),
  (
    '40000000-0000-4000-8000-000000000001',
    '44444444-4444-4444-8444-444444444444',
    'topic-s1-01',
    'S1-01',
    'Kemahiran Insaniah',
    'practice',
    1,
    0,
    1,
    '2026-07-27 04:00:00+00',
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
    '30000000-0000-4000-8000-000000000001',
    's1-01-q01',
    1,
    '{
      "id": "s1-01-q01",
      "topicId": "topic-s1-01",
      "questionText": "Historical snapshot question one",
      "options": [
        "Snapshot A",
        "Snapshot B",
        "Snapshot C",
        "Snapshot D"
      ],
      "explanation": "Historical explanation one",
      "shuffleOptions": false
    }'::jsonb,
    0,
    1,
    false
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    's1-01-q02',
    1,
    '{
      "id": "s1-01-q02",
      "topicId": "topic-s1-01",
      "questionText": "Historical snapshot question two",
      "options": [
        "Snapshot W",
        "Snapshot X",
        "Snapshot Y",
        "Snapshot Z"
      ],
      "explanation": "Historical explanation two",
      "shuffleOptions": false
    }'::jsonb,
    2,
    3,
    false
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    's1-01-q01',
    1,
    '{
      "id": "s1-01-q01",
      "topicId": "topic-s1-01",
      "questionText": "Later review snapshot question one",
      "options": [
        "Review A",
        "Review B",
        "Review C",
        "Review D"
      ],
      "explanation": "Later review explanation one",
      "shuffleOptions": false
    }'::jsonb,
    1,
    1,
    true
  ),
  (
    '40000000-0000-4000-8000-000000000001',
    's1-01-q02',
    1,
    '{
      "id": "s1-01-q02",
      "topicId": "topic-s1-01",
      "questionText": "User two historical snapshot",
      "options": [
        "User Two A",
        "User Two B",
        "User Two C",
        "User Two D"
      ],
      "explanation": "User two explanation",
      "shuffleOptions": false
    }'::jsonb,
    0,
    2,
    false
  );


-- =========================================================
-- 4. USER ONE RESPONSE
-- =========================================================

set local request.jwt.claim.sub =
  '33333333-3333-4333-8333-333333333333';

set local request.jwt.claims =
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}';

select throws_ok(
  $test$
    select public.get_my_mistake_book_topic('  ')
  $test$,
  '22023',
  'topic_id is required.',
  'Detail RPC rejects an empty topic identifier'
);

select is(
  (
    select jsonb_build_object(
      'topicId',
      response.payload
        -> 'topic'
        ->> 'topicId',
      'topicCode',
      response.payload
        -> 'topic'
        ->> 'topicCode',
      'needsReviewCount',
      (
        response.payload
          -> 'topic'
          ->> 'needsReviewCount'
      )::integer,
      'masteredCount',
      (
        response.payload
          -> 'topic'
          ->> 'masteredCount'
      )::integer,
      'itemCount',
      jsonb_array_length(
        response.payload -> 'items'
      )
    )
    from (
      select public.get_my_mistake_book_topic(
        'topic-s1-01'
      ) as payload
    ) as response
  ),
  jsonb_build_object(
    'topicId',
    'topic-s1-01',
    'topicCode',
    'S1-01',
    'needsReviewCount',
    1,
    'masteredCount',
    1,
    'itemCount',
    2
  ),
  'Detail RPC returns user one topic counts'
);

select is(
  (
    select jsonb_build_object(
      'firstQuestionId',
      response.payload
        -> 'items'
        -> 0
        ->> 'questionId',
      'firstStatus',
      response.payload
        -> 'items'
        -> 0
        ->> 'status',
      'firstSelectedIndex',
      (
        response.payload
          -> 'items'
          -> 0
          ->> 'selectedOptionIndex'
      )::integer,
      'firstCorrectIndex',
      (
        response.payload
          -> 'items'
          -> 0
          ->> 'correctOptionIndex'
      )::integer,
      'firstQuestionText',
      response.payload
        -> 'items'
        -> 0
        ->> 'questionText',
      'firstOptions',
      response.payload
        -> 'items'
        -> 0
        -> 'options',
      'firstExplanation',
      response.payload
        -> 'items'
        -> 0
        ->> 'explanation',
      'secondQuestionId',
      response.payload
        -> 'items'
        -> 1
        ->> 'questionId',
      'secondStatus',
      response.payload
        -> 'items'
        -> 1
        ->> 'status',
      'secondQuestionText',
      response.payload
        -> 'items'
        -> 1
        ->> 'questionText'
    )
    from (
      select public.get_my_mistake_book_topic(
        'topic-s1-01'
      ) as payload
    ) as response
  ),
  jsonb_build_object(
    'firstQuestionId',
    's1-01-q02',
    'firstStatus',
    'needs_review',
    'firstSelectedIndex',
    2,
    'firstCorrectIndex',
    3,
    'firstQuestionText',
    'Historical snapshot question two',
    'firstOptions',
    '[
      "Snapshot W",
      "Snapshot X",
      "Snapshot Y",
      "Snapshot Z"
    ]'::jsonb,
    'firstExplanation',
    'Historical explanation two',
    'secondQuestionId',
    's1-01-q01',
    'secondStatus',
    'mastered',
    'secondQuestionText',
    'Historical snapshot question one'
  ),
  'Needs-review items precede mastered items with detail'
);

select ok(
  (
    select
      response.payload
        -> 'items'
        -> 1
        ->> 'questionText' =
          'Historical snapshot question one'
      and response.payload
        -> 'items'
        -> 1
        ->> 'questionText' <>
          question.question_text
    from (
      select public.get_my_mistake_book_topic(
        'topic-s1-01'
      ) as payload
    ) as response
    join public.questions as question
      on question.id = 's1-01-q01'
  ),
  'Detail uses the historical incorrect-attempt snapshot'
);


-- =========================================================
-- 5. USER ISOLATION
-- =========================================================

set local request.jwt.claim.sub =
  '44444444-4444-4444-8444-444444444444';

set local request.jwt.claims =
  '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}';

select is(
  (
    select jsonb_build_object(
      'needsReviewCount',
      (
        response.payload
          -> 'topic'
          ->> 'needsReviewCount'
      )::integer,
      'masteredCount',
      (
        response.payload
          -> 'topic'
          ->> 'masteredCount'
      )::integer,
      'itemCount',
      jsonb_array_length(
        response.payload -> 'items'
      ),
      'questionId',
      response.payload
        -> 'items'
        -> 0
        ->> 'questionId',
      'questionText',
      response.payload
        -> 'items'
        -> 0
        ->> 'questionText'
    )
    from (
      select public.get_my_mistake_book_topic(
        'topic-s1-01'
      ) as payload
    ) as response
  ),
  jsonb_build_object(
    'needsReviewCount',
    1,
    'masteredCount',
    0,
    'itemCount',
    1,
    'questionId',
    's1-01-q02',
    'questionText',
    'User two historical snapshot'
  ),
  'Detail RPC returns only the authenticated user items'
);

select throws_ok(
  $test$
    select public.get_my_mistake_book_topic(
      'topic-not-in-user-book'
    )
  $test$,
  '22023',
  'Mistake Book topic was not found.',
  'Unavailable topics do not disclose another user data'
);


select * from finish();

rollback;
