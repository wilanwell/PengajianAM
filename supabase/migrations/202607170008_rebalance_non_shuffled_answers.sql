begin;

-- =========================================================
-- SEIMBANGKAN KEDUDUKAN JAWAPAN
-- BAGI SOALAN shuffle_options = false
--
-- Sasaran:
-- A = 7
-- B = 7
-- C = 7
-- D = 6
--
-- Pilihan jawapan betul ditukar kedudukan melalui
-- proses swap. Teks jawapan betul tidak berubah.
-- =========================================================

create temporary table
  target_answer_positions (
    question_id text primary key,

    target_index integer not null
      check (
        target_index between 0 and 3
      ),

    original_correct_text text
  )
on commit drop;


insert into target_answer_positions (
  question_id,
  target_index
)
values
  ('s1-01-q04', 0),
  ('s1-01-q12', 1),
  ('s1-01-q15', 2),

  ('s1-02-q20', 3),

  ('s1-03-q04', 0),
  ('s1-03-q17', 1),
  ('s1-03-q20', 2),

  ('s1-04-q04', 3),
  ('s1-04-q08', 0),
  ('s1-04-q11', 1),
  ('s1-04-q20', 2),

  ('s1-05-q03', 3),
  ('s1-05-q06', 0),
  ('s1-05-q10', 1),
  ('s1-05-q13', 2),
  ('s1-05-q20', 3),

  ('s1-06-q02', 0),
  ('s1-06-q08', 1),
  ('s1-06-q12', 2),
  ('s1-06-q18', 3),
  ('s1-06-q20', 0),

  ('s1-07-q02', 1),
  ('s1-07-q05', 2),
  ('s1-07-q13', 3),
  ('s1-07-q17', 0),
  ('s1-07-q19', 1),
  ('s1-07-q20', 2);


-- Simpan teks jawapan betul sebelum kedudukan diubah.

update target_answer_positions
set original_correct_text =
  question.options
    ->> answer.correct_option_index

from public.questions as question

join private.question_answers as answer
  on answer.question_id = question.id

where question.id =
  target_answer_positions.question_id;


do $$
declare
  target_record record;

  current_options jsonb;
  current_correct_index integer;
  current_shuffle_options boolean;

  correct_option_value jsonb;
  target_option_value jsonb;
begin
  for target_record in
    select
      question_id,
      target_index,
      original_correct_text

    from target_answer_positions

    order by question_id
  loop
    select
      question.options,
      question.shuffle_options,
      answer.correct_option_index

    into
      current_options,
      current_shuffle_options,
      current_correct_index

    from public.questions as question

    join private.question_answers as answer
      on answer.question_id = question.id

    where question.id =
      target_record.question_id;

    if not found then
      raise exception
        'Question or answer not found: %',
        target_record.question_id;
    end if;

    if current_shuffle_options then
      raise exception
        'Question must use shuffle_options=false: %',
        target_record.question_id;
    end if;

    if jsonb_array_length(
      current_options
    ) <> 4 then
      raise exception
        'Question does not have four options: %',
        target_record.question_id;
    end if;

    if current_correct_index <>
       target_record.target_index then
      correct_option_value :=
        current_options
          -> current_correct_index;

      target_option_value :=
        current_options
          -> target_record.target_index;

      current_options := jsonb_set(
        current_options,

        array[
          current_correct_index::text
        ],

        target_option_value,

        false
      );

      current_options := jsonb_set(
        current_options,

        array[
          target_record.target_index::text
        ],

        correct_option_value,

        false
      );

      update public.questions
      set options = current_options
      where id =
        target_record.question_id;

      update private.question_answers
      set correct_option_index =
        target_record.target_index
      where question_id =
        target_record.question_id;
    end if;
  end loop;


  -- Pastikan teks jawapan betul tidak berubah.

  if exists (
    select 1

    from target_answer_positions as target

    join public.questions as question
      on question.id =
        target.question_id

    join private.question_answers as answer
      on answer.question_id =
        question.id

    where
      answer.correct_option_index <>
        target.target_index

      or question.options
          ->> answer.correct_option_index
         is distinct from
         target.original_correct_text
  ) then
    raise exception
      'Answer rebalancing verification failed.';
  end if;
end;
$$;

commit;