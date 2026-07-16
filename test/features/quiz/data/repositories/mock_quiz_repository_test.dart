import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/data/repositories/mock_quiz_repository.dart';

void main() {
  const repository = MockQuizRepository();

  test('mengembalikan 10 soalan unik', () async {
    final questions = await repository.getQuestions(
      topicId: 'topic-s1-01',
      limit: 10,
    );

    expect(questions, hasLength(10));

    final questionIds = questions.map((question) => question.id).toSet();

    expect(questionIds, hasLength(10));

    expect(
      questions.every((question) => question.topicId == 'topic-s1-01'),
      isTrue,
    );
  });

  test('mengembalikan 20 soalan tanpa pengulangan', () async {
    final questions = await repository.getQuestions(
      topicId: 'topic-s1-02',
      limit: 20,
    );

    expect(questions, hasLength(20));

    final questionIds = questions.map((question) => question.id).toList();

    expect(questionIds.toSet(), hasLength(20));

    final questionTexts = questions
        .map((question) => question.questionText)
        .toSet();

    expect(questionTexts, hasLength(20));
  });

  test('tidak mengulangi soalan apabila limit melebihi bank', () async {
    final questions = await repository.getQuestions(
      topicId: 'topic-s1-03',
      limit: 30,
    );

    expect(questions, hasLength(20));

    expect(questions.map((question) => question.id).toSet(), hasLength(20));
  });

  test('mengembalikan senarai kosong untuk limit tidak sah', () async {
    final zeroResult = await repository.getQuestions(
      topicId: 'topic-s1-01',
      limit: 0,
    );

    final negativeResult = await repository.getQuestions(
      topicId: 'topic-s1-01',
      limit: -5,
    );

    expect(zeroResult, isEmpty);

    expect(negativeResult, isEmpty);
  });

  test('soalan urutan mengekalkan pilihan jawapan', () async {
    final questions = await repository.getQuestions(
      topicId: 'topic-s1-01',
      limit: 20,
    );

    final sequenceQuestion = questions.firstWhere(
      (question) => question.id == 'mock-20',
    );

    expect(sequenceQuestion.shuffleOptions, isFalse);

    expect(sequenceQuestion.correctOptionIndex, 0);
  });
}
