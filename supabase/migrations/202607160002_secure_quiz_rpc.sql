begin;

-- =========================================================
-- 1. PRIVATE QUIZ SESSION TABLES
-- =========================================================

create table if not exists private.quiz_sessions (
  id uuid primary key
    default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  topic_id text not null
    references public.topics(id)
    on delete cascade,

  mode text not null
    check (
      mode in ('practice', 'exam')
    ),

  question_count integer not null
    check (question_count > 0),

  created_at timestamptz not null
    default now(),

  expires_at timestamptz not null
    default (
      now() + interval '2 hours'
    ),

  submitted_at timestamptz,

  constraint quiz_session_expiry_after_creation
    check (
      expires_at > created_at
    )
);


create table if not exists private.quiz_session_items (
  session_id uuid not null
    references private.quiz_sessions(id)
    on delete cascade,

  question_id text not null
    references public.questions(id)
    on delete cascade,

  question_order integer not null
    check (question_order > 0),

  -- Setiap nilai ialah index pilihan asal.
  -- Kedudukan dalam array ialah kedudukan yang dipaparkan.
  option_order integer[] not null,

  primary key (
    session_id,
    question_id
  ),

  constraint one_question_order_per_session
    unique (
      session_id,
      question_order
    ),

  constraint option_order_has_minimum_two_options
    check (
      cardinality(option_order) >= 2
    )
);


revoke all
on table private.quiz_sessions
from public, anon, authenticated;

revoke all
on table private.quiz_session_items
from public, anon, authenticated;


create index if not exists
quiz_sessions_user_created_index
on private.quiz_sessions (
  user_id,
  created_at desc
);


create index if not exists
quiz_sessions_expiry_index
on private.quiz_sessions (
  expires_at
);


create index if not exists
quiz_session_items_session_order_index
on private.quiz_session_items (
  session_id,
  question_order
);


-- =========================================================
-- 2. BLOCK DIRECT QUESTION-BANK ACCESS
-- =========================================================

-- Topik masih boleh dibaca oleh authenticated users.
-- Question bank pula hanya akan dihantar melalui start_quiz().

drop policy if exists questions_select_active
on public.questions;

revoke select
on table public.questions
from authenticated;


-- =========================================================
-- 3. HELPER: BUILD OPTION ORDER
-- =========================================================

create or replace function private.build_option_order(
  p_option_count integer,
  p_shuffle boolean
)
returns integer[]
language sql
volatile
set search_path = ''
as $$
  select
    case
      when p_option_count < 1 then
        array[]::integer[]

      when p_shuffle then
        array_agg(
          generated.option_index
          order by random()
        )

      else
        array_agg(
          generated.option_index
          order by generated.option_index
        )
    end
  from generate_series(
    0,
    p_option_count - 1
  ) as generated(option_index);
$$;


revoke execute
on function private.build_option_order(
  integer,
  boolean
)
from public, anon, authenticated;


-- =========================================================
-- 4. RPC: START QUIZ
-- =========================================================

create or replace function public.start_quiz(
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
  v_session_id uuid;
  v_expires_at timestamptz;

  v_available_count integer;
  v_question_order integer := 0;

  v_question record;
  v_option_count integer;
  v_option_order integer[];
  v_display_options jsonb;

  v_questions jsonb := '[]'::jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_topic_id is null
     or char_length(trim(p_topic_id)) = 0 then
    raise exception using
      errcode = '22023',
      message = 'topic_id is required.';
  end if;

  if p_question_count not in (10, 20) then
    raise exception using
      errcode = '22023',
      message = 'question_count must be 10 or 20.';
  end if;

  if p_mode not in ('practice', 'exam') then
    raise exception using
      errcode = '22023',
      message = 'mode must be practice or exam.';
  end if;

  if not exists (
    select 1
    from public.topics as topic
    where topic.id = p_topic_id
      and topic.is_active = true
  ) then
    raise exception using
      errcode = '22023',
      message = 'The selected topic is not available.';
  end if;

  select count(*)::integer
  into v_available_count
  from public.questions as question
  where question.topic_id = p_topic_id
    and question.is_active = true
    and exists (
      select 1
      from private.question_answers as answer
      where answer.question_id = question.id
    );

  if v_available_count < p_question_count then
    raise exception using
      errcode = '22023',
      message =
        'Not enough unique questions are available for this topic.';
  end if;

  v_expires_at :=
    now() + interval '2 hours';

  insert into private.quiz_sessions (
    user_id,
    topic_id,
    mode,
    question_count,
    expires_at
  )
  values (
    v_user_id,
    p_topic_id,
    p_mode,
    p_question_count,
    v_expires_at
  )
  returning id
  into v_session_id;

  for v_question in
    select
      question.id,
      question.topic_id,
      question.question_text,
      question.options,
      question.shuffle_options
    from public.questions as question
    where question.topic_id = p_topic_id
      and question.is_active = true
      and exists (
        select 1
        from private.question_answers as answer
        where answer.question_id = question.id
      )
    order by random()
    limit p_question_count
  loop
    v_question_order :=
      v_question_order + 1;

    v_option_count :=
      jsonb_array_length(
        v_question.options
      );

    v_option_order :=
      private.build_option_order(
        v_option_count,
        v_question.shuffle_options
      );

    insert into private.quiz_session_items (
      session_id,
      question_id,
      question_order,
      option_order
    )
    values (
      v_session_id,
      v_question.id,
      v_question_order,
      v_option_order
    );

    select coalesce(
      jsonb_agg(
        v_question.options
          -> ordered_option.original_index
        order by
          ordered_option.display_position
      ),
      '[]'::jsonb
    )
    into v_display_options
    from unnest(
      v_option_order
    ) with ordinality
      as ordered_option(
        original_index,
        display_position
      );

    v_questions :=
      v_questions ||
      jsonb_build_array(
        jsonb_build_object(
          'id',
          v_question.id,

          'topicId',
          v_question.topic_id,

          'questionText',
          v_question.question_text,

          'options',
          v_display_options,

          -- Pilihan sudah diacak oleh server.
          'shuffleOptions',
          false,

          'questionOrder',
          v_question_order
        )
      );
  end loop;

  return jsonb_build_object(
    'sessionId',
    v_session_id,

    'topicId',
    p_topic_id,

    'mode',
    p_mode,

    'questionCount',
    p_question_count,

    'expiresAt',
    v_expires_at,

    'questions',
    v_questions
  );
end;
$$;


revoke execute
on function public.start_quiz(
  text,
  integer,
  text
)
from public, anon;

grant execute
on function public.start_quiz(
  text,
  integer,
  text
)
to authenticated;


-- =========================================================
-- 5. RPC: SUBMIT QUIZ
-- =========================================================

create or replace function public.submit_quiz_attempt(
  p_session_id uuid,
  p_answers jsonb,
  p_elapsed_seconds integer,
  p_auto_submitted boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_session private.quiz_sessions%rowtype;

  v_topic_code text;
  v_topic_title text;

  v_attempt_id uuid;
  v_completed_at timestamptz;

  v_item record;

  v_selected_display_index integer;
  v_selected_original_index integer;

  v_correct_original_index integer;
  v_correct_display_index integer;

  v_display_options jsonb;
  v_is_correct boolean;

  v_answer_count integer;
  v_distinct_answer_count integer;

  v_answered_count integer := 0;
  v_correct_count integer := 0;
  v_earned_xp integer := 0;

  v_percentage numeric(5, 2) := 0;
  v_day_index integer;

  v_result_questions jsonb := '[]'::jsonb;
  v_selected_answers jsonb := '{}'::jsonb;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication required.';
  end if;

  if p_session_id is null then
    raise exception using
      errcode = '22023',
      message = 'session_id is required.';
  end if;

  if p_answers is null
     or jsonb_typeof(p_answers) <> 'array' then
    raise exception using
      errcode = '22023',
      message = 'answers must be a JSON array.';
  end if;

  if p_elapsed_seconds is null
     or p_elapsed_seconds < 0
     or p_elapsed_seconds > 86400 then
    raise exception using
      errcode = '22023',
      message =
        'elapsed_seconds must be between 0 and 86400.';
  end if;

  select *
  into v_session
  from private.quiz_sessions
  where id = p_session_id
  for update;

  if not found then
    raise exception using
      errcode = '22023',
      message = 'Quiz session was not found.';
  end if;

  if v_session.user_id <> v_user_id then
    raise exception using
      errcode = '42501',
      message =
        'This quiz session belongs to another user.';
  end if;

  if v_session.submitted_at is not null then
    raise exception using
      errcode = '22023',
      message =
        'This quiz session has already been submitted.';
  end if;

  if v_session.expires_at < now() then
    raise exception using
      errcode = '22023',
      message = 'This quiz session has expired.';
  end if;

  -- Every item must be an object containing question_id.
  if exists (
    select 1
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where jsonb_typeof(
            submitted_answer.value
          ) <> 'object'

       or not (
         submitted_answer.value
         ? 'question_id'
       )

       or jsonb_typeof(
            submitted_answer.value
              -> 'question_id'
          ) <> 'string'

       or nullif(
            trim(
              submitted_answer.value
                ->> 'question_id'
            ),
            ''
          ) is null

       or (
         submitted_answer.value
           ? 'selected_option_index'

         and jsonb_typeof(
           submitted_answer.value
             -> 'selected_option_index'
         ) not in (
           'number',
           'null'
         )
       )

       or (
         jsonb_typeof(
           submitted_answer.value
             -> 'selected_option_index'
         ) = 'number'

         and (
           submitted_answer.value
             ->> 'selected_option_index'
         ) !~ '^[0-9]+$'
       )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid answer data.';
  end if;

  select
    count(*)::integer,
    count(
      distinct
      submitted_answer.value
        ->> 'question_id'
    )::integer
  into
    v_answer_count,
    v_distinct_answer_count
  from jsonb_array_elements(
    p_answers
  ) as submitted_answer(value);

  if v_answer_count <>
     v_distinct_answer_count then
    raise exception using
      errcode = '22023',
      message =
        'Duplicate answers for the same question are not allowed.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where not exists (
      select 1
      from private.quiz_session_items
        as session_item
      where session_item.session_id =
        p_session_id
        and session_item.question_id =
          submitted_answer.value
            ->> 'question_id'
    )
  ) then
    raise exception using
      errcode = '22023',
      message =
        'An answer refers to a question outside this session.';
  end if;

  select
    topic.code,
    topic.title
  into
    v_topic_code,
    v_topic_title
  from public.topics as topic
  where topic.id = v_session.topic_id;

  insert into public.quiz_attempts (
    user_id,
    topic_id,
    topic_code,
    topic_title,
    mode,
    question_count,
    correct_answers,
    answered_questions,
    elapsed_seconds,
    earned_xp,
    auto_submitted
  )
  values (
    v_user_id,
    v_session.topic_id,
    coalesce(v_topic_code, ''),
    coalesce(
      v_topic_title,
      'Topik Pengajian AM'
    ),
    v_session.mode,
    v_session.question_count,
    0,
    0,
    p_elapsed_seconds,
    0,
    p_auto_submitted
  )
  returning
    id,
    completed_at
  into
    v_attempt_id,
    v_completed_at;

  for v_item in
    select
      session_item.question_id,
      session_item.question_order,
      session_item.option_order,

      question.topic_id,
      question.question_text,
      question.options,

      answer.correct_option_index,
      answer.explanation

    from private.quiz_session_items
      as session_item

    join public.questions as question
      on question.id =
        session_item.question_id

    join private.question_answers as answer
      on answer.question_id =
        session_item.question_id

    where session_item.session_id =
      p_session_id

    order by session_item.question_order
  loop
    v_selected_display_index := null;
    v_selected_original_index := null;

    select
      (
        submitted_answer.value
          ->> 'selected_option_index'
      )::integer
    into v_selected_display_index
    from jsonb_array_elements(
      p_answers
    ) as submitted_answer(value)
    where submitted_answer.value
            ->> 'question_id'
          = v_item.question_id

      and submitted_answer.value
            ? 'selected_option_index'

      and jsonb_typeof(
        submitted_answer.value
          -> 'selected_option_index'
      ) = 'number'
    limit 1;

    if v_selected_display_index is not null then
      if v_selected_display_index >=
         cardinality(v_item.option_order) then
        raise exception using
          errcode = '22023',
          message =
            'A selected option index is outside the valid range.';
      end if;

      v_selected_original_index :=
        v_item.option_order[
          v_selected_display_index + 1
        ];

      v_answered_count :=
        v_answered_count + 1;

      v_selected_answers :=
        v_selected_answers ||
        jsonb_build_object(
          v_item.question_id,
          v_selected_display_index
        );
    end if;

    v_correct_original_index :=
      v_item.correct_option_index;

    v_correct_display_index :=
      array_position(
        v_item.option_order,
        v_correct_original_index
      ) - 1;

    if v_correct_display_index < 0 then
      raise exception using
        errcode = '22023',
        message =
          'Correct answer mapping could not be resolved.';
    end if;

    v_is_correct :=
      v_selected_original_index is not null
      and v_selected_original_index =
        v_correct_original_index;

    if v_is_correct then
      v_correct_count :=
        v_correct_count + 1;
    end if;

    select coalesce(
      jsonb_agg(
        v_item.options
          -> ordered_option.original_index
        order by
          ordered_option.display_position
      ),
      '[]'::jsonb
    )
    into v_display_options
    from unnest(
      v_item.option_order
    ) with ordinality
      as ordered_option(
        original_index,
        display_position
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
      v_attempt_id,
      v_item.question_id,
      v_item.question_order,

      jsonb_build_object(
        'id',
        v_item.question_id,

        'topicId',
        v_item.topic_id,

        'questionText',
        v_item.question_text,

        'options',
        v_display_options,

        'explanation',
        v_item.explanation,

        'shuffleOptions',
        false
      ),

      v_selected_display_index,
      v_correct_display_index,
      v_is_correct
    );

    v_result_questions :=
      v_result_questions ||
      jsonb_build_array(
        jsonb_build_object(
          'id',
          v_item.question_id,

          'topicId',
          v_item.topic_id,

          'questionText',
          v_item.question_text,

          'options',
          v_display_options,

          'correctOptionIndex',
          v_correct_display_index,

          'explanation',
          v_item.explanation,

          'shuffleOptions',
          false
        )
      );
  end loop;

  if v_session.question_count > 0 then
    v_percentage :=
      round(
        (
          v_correct_count::numeric /
          v_session.question_count::numeric
        ) * 100,
        2
      );
  end if;

  v_earned_xp :=
    v_correct_count * 10;

  if v_answered_count =
     v_session.question_count then
    v_earned_xp :=
      v_earned_xp + 20;
  end if;

  if v_correct_count =
     v_session.question_count then
    v_earned_xp :=
      v_earned_xp + 50;
  end if;

  update public.quiz_attempts
  set
    correct_answers =
      v_correct_count,

    answered_questions =
      v_answered_count,

    earned_xp =
      v_earned_xp

  where id = v_attempt_id;

  insert into public.user_progress (
    user_id
  )
  values (
    v_user_id
  )
  on conflict (
    user_id
  ) do nothing;

  v_day_index :=
    extract(
      isodow from now()
    )::integer;

  update public.user_progress
  set
    total_xp =
      total_xp + v_earned_xp,

    weekly_xp =
      weekly_xp + v_earned_xp,

    monthly_xp =
      monthly_xp + v_earned_xp,

    completed_quizzes =
      completed_quizzes + 1,

    total_correct_answers =
      total_correct_answers +
      v_correct_count,

    total_quiz_questions =
      total_quiz_questions +
      v_session.question_count,

    highest_score =
      greatest(
        highest_score,
        v_percentage
      ),

    weekly_answered_questions[
      v_day_index
    ] =
      weekly_answered_questions[
        v_day_index
      ] + v_answered_count

  where user_id = v_user_id;

  update private.quiz_sessions
  set submitted_at = now()
  where id = p_session_id;

  return jsonb_build_object(
    'attemptId',
    v_attempt_id,

    'topicId',
    v_session.topic_id,

    'topicCode',
    coalesce(v_topic_code, ''),

    'topicTitle',
    coalesce(
      v_topic_title,
      'Topik Pengajian AM'
    ),

    'mode',
    v_session.mode,

    'questions',
    v_result_questions,

    'selectedAnswers',
    v_selected_answers,

    'correctAnswers',
    v_correct_count,

    'answeredQuestions',
    v_answered_count,

    'questionCount',
    v_session.question_count,

    'elapsedTimeMilliseconds',
    p_elapsed_seconds * 1000,

    'earnedXp',
    v_earned_xp,

    'autoSubmitted',
    p_auto_submitted,

    'completedAt',
    v_completed_at
  );
end;
$$;


revoke execute
on function public.submit_quiz_attempt(
  uuid,
  jsonb,
  integer,
  boolean
)
from public, anon;

grant execute
on function public.submit_quiz_attempt(
  uuid,
  jsonb,
  integer,
  boolean
)
to authenticated;


-- =========================================================
-- 6. SEED: 20 QUESTIONS FOR S1-02 NEGARA BERDAULAT
-- =========================================================

insert into public.questions (
  id,
  topic_id,
  question_text,
  options,
  shuffle_options,
  sort_order,
  is_active
)
values
  (
    's1-02-q01',
    'topic-s1-02',
    'Apakah maksud paling tepat bagi kedaulatan sesebuah negara?',
    jsonb_build_array(
      'Bilangan penduduk yang sangat ramai',
      'Kuasa tertinggi untuk mentadbir negara',
      'Keluasan wilayah yang besar',
      'Kekayaan sumber semula jadi'
    ),
    true,
    1,
    true
  ),
  (
    's1-02-q02',
    'topic-s1-02',
    'Antara berikut, yang manakah merupakan unsur asas sesebuah negara?',
    jsonb_build_array(
      'Penduduk, wilayah, kerajaan dan kedaulatan',
      'Bahasa, agama, mata wang dan teknologi',
      'Bandar, pelabuhan, industri dan sekolah',
      'Parti politik, media, syarikat dan kesatuan'
    ),
    true,
    2,
    true
  ),
  (
    's1-02-q03',
    'topic-s1-02',
    'Apakah yang dimaksudkan dengan kedaulatan dalaman?',
    jsonb_build_array(
      'Pengiktirafan oleh organisasi antarabangsa',
      'Kebebasan menjalin hubungan diplomatik',
      'Kuasa kerajaan terhadap penduduk dan wilayahnya',
      'Keupayaan mengeksport barangan ke luar negara'
    ),
    true,
    3,
    true
  ),
  (
    's1-02-q04',
    'topic-s1-02',
    'Apakah ciri utama kedaulatan luaran?',
    jsonb_build_array(
      'Kerajaan mengawal semua syarikat swasta',
      'Negara bebas daripada penguasaan kuasa asing',
      'Penduduk menggunakan satu bahasa sahaja',
      'Semua keputusan dibuat oleh kerajaan tempatan'
    ),
    true,
    4,
    true
  ),
  (
    's1-02-q05',
    'topic-s1-02',
    'Mengapakah keutuhan wilayah penting kepada negara berdaulat?',
    jsonb_build_array(
      'Memastikan sempadan dan wilayah negara dilindungi',
      'Menghapuskan hubungan dengan negara lain',
      'Membolehkan kerajaan mengabaikan undang-undang',
      'Mengurangkan penyertaan rakyat'
    ),
    true,
    5,
    true
  ),
  (
    's1-02-q06',
    'topic-s1-02',
    'Apakah peranan Perlembagaan dalam negara berdaulat?',
    jsonb_build_array(
      'Menggantikan semua institusi kerajaan',
      'Memberikan kuasa tanpa had kepada pemerintah',
      'Menjadi asas pemerintahan dan pembahagian kuasa',
      'Menghapuskan hak rakyat'
    ),
    true,
    6,
    true
  ),
  (
    's1-02-q07',
    'topic-s1-02',
    'Apakah maksud prinsip kedaulatan undang-undang?',
    jsonb_build_array(
      'Undang-undang hanya terpakai kepada rakyat biasa',
      'Semua pihak tertakluk kepada undang-undang',
      'Pemimpin boleh mengetepikan undang-undang',
      'Mahkamah tertakluk kepada parti politik'
    ),
    true,
    7,
    true
  ),
  (
    's1-02-q08',
    'topic-s1-02',
    'Apakah yang menyumbang kepada legitimasi sesebuah kerajaan?',
    jsonb_build_array(
      'Penggunaan kekerasan tanpa batas',
      'Penghapusan pilihan raya',
      'Kawalan mutlak terhadap media',
      'Penerimaan rakyat dan pemerintahan yang sah'
    ),
    true,
    8,
    true
  ),
  (
    's1-02-q09',
    'topic-s1-02',
    'Bagaimanakah perpaduan rakyat membantu mempertahankan kedaulatan?',
    jsonb_build_array(
      'Mengurangkan kerjasama antara masyarakat',
      'Meningkatkan persaingan yang tidak terkawal',
      'Mengukuhkan kestabilan dan ketahanan negara',
      'Menghapuskan kepelbagaian budaya'
    ),
    true,
    9,
    true
  ),
  (
    's1-02-q10',
    'topic-s1-02',
    'Apakah tujuan utama kawalan sempadan negara?',
    jsonb_build_array(
      'Melindungi wilayah dan mengawal pergerakan rentas sempadan',
      'Menghentikan semua hubungan antarabangsa',
      'Menghapuskan perdagangan luar',
      'Menggantikan fungsi kerajaan negeri'
    ),
    true,
    10,
    true
  ),
  (
    's1-02-q11',
    'topic-s1-02',
    'Apakah kepentingan hubungan diplomatik kepada negara berdaulat?',
    jsonb_build_array(
      'Membolehkan negara menyerahkan kuasa pentadbiran',
      'Membina kerjasama dan mewakili kepentingan negara',
      'Menghapuskan undang-undang negara',
      'Mengurangkan pengiktirafan antarabangsa'
    ),
    true,
    11,
    true
  ),
  (
    's1-02-q12',
    'topic-s1-02',
    'Apakah peranan utama angkatan pertahanan dalam menjaga kedaulatan?',
    jsonb_build_array(
      'Mengurus semua syarikat swasta',
      'Menggubal semua undang-undang',
      'Mengendalikan sistem pendidikan',
      'Melindungi negara daripada ancaman keselamatan'
    ),
    true,
    12,
    true
  ),
  (
    's1-02-q13',
    'topic-s1-02',
    'Bagaimanakah ketahanan ekonomi menyokong kedaulatan negara?',
    jsonb_build_array(
      'Menjadikan negara bergantung sepenuhnya kepada pihak luar',
      'Mengurangkan keupayaan menyediakan perkhidmatan',
      'Mengurangkan kerentanan terhadap tekanan ekonomi luar',
      'Menghapuskan semua aktiviti import'
    ),
    true,
    13,
    true
  ),
  (
    's1-02-q14',
    'topic-s1-02',
    'Yang manakah merupakan ancaman terhadap kedaulatan digital negara?',
    jsonb_build_array(
      'Serangan siber terhadap sistem kritikal',
      'Peningkatan literasi digital',
      'Penggunaan teknologi dalam pendidikan',
      'Pembangunan perkhidmatan dalam talian'
    ),
    true,
    14,
    true
  ),
  (
    's1-02-q15',
    'topic-s1-02',
    'Apakah kesan campur tangan asing terhadap sesebuah negara?',
    jsonb_build_array(
      'Mengukuhkan kebebasan membuat keputusan',
      'Menjejaskan kebebasan negara menentukan dasar sendiri',
      'Meningkatkan kedaulatan dalaman secara automatik',
      'Menghapuskan semua ancaman keselamatan'
    ),
    true,
    15,
    true
  ),
  (
    's1-02-q16',
    'topic-s1-02',
    'Apakah tanggungjawab rakyat dalam mempertahankan kedaulatan?',
    jsonb_build_array(
      'Mengabaikan undang-undang negara',
      'Menyebarkan maklumat yang belum disahkan',
      'Mematuhi undang-undang dan menjaga kepentingan negara',
      'Mengelakkan semua aktiviti kemasyarakatan'
    ),
    true,
    16,
    true
  ),
  (
    's1-02-q17',
    'topic-s1-02',
    'Mengapakah pengiktirafan antarabangsa penting kepada sesebuah negara?',
    jsonb_build_array(
      'Membolehkan negara menyerahkan wilayahnya',
      'Menghapuskan keperluan pentadbiran',
      'Membatalkan semua undang-undang tempatan',
      'Membolehkan negara menjalinkan hubungan rasmi dengan negara lain'
    ),
    true,
    17,
    true
  ),
  (
    's1-02-q18',
    'topic-s1-02',
    'Apakah kepentingan kerajaan yang stabil kepada negara berdaulat?',
    jsonb_build_array(
      'Memastikan pentadbiran dan dasar dapat dilaksanakan',
      'Menghapuskan proses semak dan imbang',
      'Mengehadkan semua hak rakyat',
      'Menggantikan fungsi Perlembagaan'
    ),
    true,
    18,
    true
  ),
  (
    's1-02-q19',
    'topic-s1-02',
    'Bagaimanakah penyertaan rakyat menyokong pemerintahan negara?',
    jsonb_build_array(
      'Membolehkan semua undang-undang diabaikan',
      'Memberikan legitimasi dan maklum balas kepada kerajaan',
      'Menghapuskan tanggungjawab pemerintah',
      'Menggantikan semua institusi negara'
    ),
    true,
    19,
    true
  ),
  (
    's1-02-q20',
    'topic-s1-02',
    'Pilih urutan tindakan yang paling sesuai apabila negara menghadapi ancaman keselamatan.',
    jsonb_build_array(
      'Kenal pasti ancaman, nilai risiko, ambil tindakan, pantau keadaan',
      'Ambil tindakan, abaikan risiko, kenal pasti ancaman, tamatkan pemantauan',
      'Pantau keadaan, tamatkan tindakan, nilai risiko, kenal pasti ancaman',
      'Abaikan ancaman, hentikan pemantauan, ambil tindakan, nilai risiko'
    ),
    false,
    20,
    true
  )
on conflict (id)
do update set
  topic_id =
    excluded.topic_id,

  question_text =
    excluded.question_text,

  options =
    excluded.options,

  shuffle_options =
    excluded.shuffle_options,

  sort_order =
    excluded.sort_order,

  is_active =
    excluded.is_active;


insert into private.question_answers (
  question_id,
  correct_option_index,
  explanation
)
values
  (
    's1-02-q01',
    1,
    'Kedaulatan ialah kuasa tertinggi sesebuah negara untuk mengurus dan mentadbir urusannya.'
  ),
  (
    's1-02-q02',
    0,
    'Unsur asas negara ialah penduduk, wilayah, kerajaan dan kedaulatan.'
  ),
  (
    's1-02-q03',
    2,
    'Kedaulatan dalaman merujuk kepada kuasa kerajaan terhadap penduduk dan wilayahnya.'
  ),
  (
    's1-02-q04',
    1,
    'Kedaulatan luaran bermaksud negara bebas daripada penguasaan atau kawalan kuasa asing.'
  ),
  (
    's1-02-q05',
    0,
    'Keutuhan wilayah memastikan sempadan dan kawasan di bawah kuasa negara terus dilindungi.'
  ),
  (
    's1-02-q06',
    2,
    'Perlembagaan menetapkan asas pemerintahan, pembahagian kuasa dan peraturan utama negara.'
  ),
  (
    's1-02-q07',
    1,
    'Kedaulatan undang-undang bermaksud semua pihak, termasuk pemerintah, tertakluk kepada undang-undang.'
  ),
  (
    's1-02-q08',
    3,
    'Kerajaan yang sah dan diterima rakyat mempunyai legitimasi untuk mentadbir.'
  ),
  (
    's1-02-q09',
    2,
    'Perpaduan membantu mewujudkan kestabilan dan meningkatkan ketahanan negara.'
  ),
  (
    's1-02-q10',
    0,
    'Kawalan sempadan melindungi wilayah serta mengurus pergerakan manusia dan barangan.'
  ),
  (
    's1-02-q11',
    1,
    'Hubungan diplomatik membolehkan negara bekerjasama dan mempertahankan kepentingannya.'
  ),
  (
    's1-02-q12',
    3,
    'Angkatan pertahanan bertanggungjawab melindungi negara daripada ancaman keselamatan.'
  ),
  (
    's1-02-q13',
    2,
    'Ekonomi yang berdaya tahan mengurangkan kesan tekanan atau gangguan ekonomi dari luar.'
  ),
  (
    's1-02-q14',
    0,
    'Serangan siber terhadap sistem kritikal boleh menjejaskan keselamatan dan fungsi negara.'
  ),
  (
    's1-02-q15',
    1,
    'Campur tangan asing boleh mengehadkan kebebasan negara menentukan dasar sendiri.'
  ),
  (
    's1-02-q16',
    2,
    'Rakyat membantu mempertahankan kedaulatan dengan mematuhi undang-undang dan menjaga kepentingan negara.'
  ),
  (
    's1-02-q17',
    3,
    'Pengiktirafan antarabangsa membolehkan hubungan rasmi dan kerjasama dengan negara lain.'
  ),
  (
    's1-02-q18',
    0,
    'Kerajaan yang stabil membolehkan pentadbiran dan dasar dilaksanakan secara berterusan.'
  ),
  (
    's1-02-q19',
    1,
    'Penyertaan rakyat memberikan legitimasi serta maklum balas kepada proses pemerintahan.'
  ),
  (
    's1-02-q20',
    0,
    'Tindakan yang teratur bermula dengan mengenal pasti ancaman, menilai risiko, bertindak dan memantau keadaan.'
  )
on conflict (question_id)
do update set
  correct_option_index =
    excluded.correct_option_index,

  explanation =
    excluded.explanation;


commit;