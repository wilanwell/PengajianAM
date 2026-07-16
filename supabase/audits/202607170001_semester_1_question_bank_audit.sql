-- =========================================================
-- SEMESTER 1 QUESTION BANK QUALITY AUDIT
--
-- Fail ini hanya membaca data.
-- Tiada rekod akan diubah atau dipadamkan.
-- =========================================================


-- =========================================================
-- 1. JUMLAH SOALAN DAN JAWAPAN MENGIKUT TOPIK
-- =========================================================

select
  topic.code,
  topic.title,

  count(question.id)
    filter (
      where question.is_active = true
    ) as active_question_count,

  count(answer.question_id)
    filter (
      where question.is_active = true
    ) as answer_count

from public.topics as topic

left join public.questions as question
  on question.topic_id = topic.id

left join private.question_answers as answer
  on answer.question_id = question.id

where topic.semester = 1

group by
  topic.id,
  topic.code,
  topic.title,
  topic.sort_order

order by topic.sort_order;


-- =========================================================
-- 2. SEMAKAN INTEGRITI KESELURUHAN
-- =========================================================

select
  count(*) as active_question_count,

  count(*) filter (
    where answer.question_id is null
  ) as missing_answer_count,

  count(*) filter (
    where jsonb_array_length(
      question.options
    ) <> 4
  ) as invalid_option_count,

  count(*) filter (
    where answer.correct_option_index < 0
       or answer.correct_option_index >=
          jsonb_array_length(
            question.options
          )
  ) as invalid_answer_index_count,

  count(*) filter (
    where nullif(
      trim(answer.explanation),
      ''
    ) is null
  ) as missing_explanation_count

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

left join private.question_answers as answer
  on answer.question_id = question.id

where topic.semester = 1
  and question.is_active = true;


-- =========================================================
-- 3. AGIHAN JAWAPAN TERSIMPAN MENGIKUT TOPIK
-- =========================================================

select
  topic.code,

  chr(
    65 + answer.correct_option_index
  ) as answer_letter,

  count(*) as answer_count,

  round(
    count(*)::numeric
    /
    sum(count(*)) over (
      partition by topic.id
    )
    * 100,
    2
  ) as percentage

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

join private.question_answers as answer
  on answer.question_id = question.id

where topic.semester = 1
  and question.is_active = true

group by
  topic.id,
  topic.code,
  topic.sort_order,
  answer.correct_option_index

order by
  topic.sort_order,
  answer.correct_option_index;


-- =========================================================
-- 4. AGIHAN JAWAPAN BAGI SOALAN YANG TIDAK DIACAK
-- =========================================================

select
  chr(
    65 + answer.correct_option_index
  ) as answer_letter,

  count(*) as answer_count,

  round(
    count(*)::numeric
    /
    sum(count(*)) over ()
    * 100,
    2
  ) as percentage

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

join private.question_answers as answer
  on answer.question_id = question.id

where topic.semester = 1
  and question.is_active = true
  and question.shuffle_options = false

group by answer.correct_option_index

order by answer.correct_option_index;


-- =========================================================
-- 5. SOALAN I–IV YANG TERSALAH DITETAPKAN UNTUK DIACAK
-- =========================================================

select
  topic.code,
  question.id,
  question.question_text,
  question.shuffle_options

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

where topic.semester = 1
  and question.is_active = true
  and question.shuffle_options = true
  and question.question_text ~
      E'\\nI[[:space:]]'
  and question.question_text ~
      E'\\nII[[:space:]]'
  and question.question_text ~
      E'\\nIII[[:space:]]'
  and question.question_text ~
      E'\\nIV[[:space:]]'

order by
  topic.sort_order,
  question.sort_order;


-- =========================================================
-- 6. SOALAN URUTAN YANG TERSALAH DITETAPKAN UNTUK DIACAK
-- =========================================================

select
  topic.code,
  question.id,
  question.question_text,
  question.shuffle_options

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

where topic.semester = 1
  and question.is_active = true
  and question.shuffle_options = true
  and lower(question.question_text)
      like '%urutan%'

order by
  topic.sort_order,
  question.sort_order;


-- =========================================================
-- 7. SOALAN BERULANG SECARA TEPAT
-- =========================================================

with normalized_questions as (
  select
    question.id,
    topic.code,

    lower(
      regexp_replace(
        trim(question.question_text),
        '[[:space:]]+',
        ' ',
        'g'
      )
    ) as normalized_text

  from public.questions as question

  join public.topics as topic
    on topic.id = question.topic_id

  where topic.semester = 1
    and question.is_active = true
)

select
  normalized_text,
  count(*) as duplicate_count,
  string_agg(
    code || ':' || id,
    ', '
    order by code, id
  ) as question_ids

from normalized_questions

group by normalized_text

having count(*) > 1

order by duplicate_count desc;


-- =========================================================
-- 8. PILIHAN JAWAPAN BERULANG DALAM SOALAN YANG SAMA
-- =========================================================

with normalized_options as (
  select
    topic.code,
    question.id,

    lower(
      regexp_replace(
        trim(option_value),
        '[[:space:]]+',
        ' ',
        'g'
      )
    ) as normalized_option

  from public.questions as question

  join public.topics as topic
    on topic.id = question.topic_id

  cross join lateral
    jsonb_array_elements_text(
      question.options
    ) as option_value

  where topic.semester = 1
    and question.is_active = true
)

select
  code,
  id,
  normalized_option,
  count(*) as duplicate_count

from normalized_options

group by
  code,
  id,
  normalized_option

having count(*) > 1

order by code, id;


-- =========================================================
-- 9. JAWAPAN BETUL JAUH LEBIH PANJANG DARIPADA DISTRACTOR
-- =========================================================

with option_statistics as (
  select
    topic.code,
    topic.sort_order as topic_order,

    question.id,
    question.sort_order,

    answer.correct_option_index,

    length(
      question.options
        ->> answer.correct_option_index
    ) as correct_answer_length,

    (
      select avg(
        length(option_value)
      )
      from jsonb_array_elements_text(
        question.options
      ) as option_value
    ) as average_option_length

  from public.questions as question

  join public.topics as topic
    on topic.id = question.topic_id

  join private.question_answers as answer
    on answer.question_id = question.id

  where topic.semester = 1
    and question.is_active = true
)

select
  code,
  id,
  correct_answer_length,
  round(
    average_option_length,
    2
  ) as average_option_length,

  round(
    correct_answer_length -
    average_option_length,
    2
  ) as length_difference

from option_statistics

where correct_answer_length -
      average_option_length >= 25

order by
  length_difference desc,
  topic_order,
  sort_order;


-- =========================================================
-- 10. PERBEZAAN PANJANG PILIHAN YANG TERLALU BESAR
-- =========================================================

with option_lengths as (
  select
    topic.code,
    topic.sort_order as topic_order,

    question.id,
    question.sort_order,

    min(
      length(option_value)
    ) as shortest_option,

    max(
      length(option_value)
    ) as longest_option

  from public.questions as question

  join public.topics as topic
    on topic.id = question.topic_id

  cross join lateral
    jsonb_array_elements_text(
      question.options
    ) as option_value

  where topic.semester = 1
    and question.is_active = true

  group by
    topic.code,
    topic.sort_order,
    question.id,
    question.sort_order
)

select
  code,
  id,
  shortest_option,
  longest_option,
  longest_option - shortest_option
    as length_difference

from option_lengths

where longest_option -
      shortest_option >= 60

order by
  length_difference desc,
  topic_order,
  sort_order;


-- =========================================================
-- 11. SENARAI LENGKAP UNTUK SEMAKAN MANUSIA
-- =========================================================

select
  topic.code,
  topic.title,
  question.id,
  question.sort_order,
  question.question_text,
  question.options,

  chr(
    65 + answer.correct_option_index
  ) as correct_answer_letter,

  question.options
    ->> answer.correct_option_index
    as correct_answer_text,

  answer.explanation,
  question.shuffle_options

from public.questions as question

join public.topics as topic
  on topic.id = question.topic_id

join private.question_answers as answer
  on answer.question_id = question.id

where topic.semester = 1
  and question.is_active = true

order by
  topic.sort_order,
  question.sort_order;