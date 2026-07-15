import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/services/quiz_randomizer.dart';

void main() {
  test('seed sama menghasilkan susunan yang sama', () {
    const randomizer = QuizRandomizer();

    final questions = [
      QuizQuestion(
        id: 'q1',
        topicId: 'topic-1',
        questionText: 'Soalan pertama',
        options: const ['Jawapan A', 'Jawapan B', 'Jawapan C', 'Jawapan D'],
        correctOptionIndex: 2,
        explanation: 'Jawapan C ialah jawapan betul.',
      ),
      QuizQuestion(
        id: 'q2',
        topicId: 'topic-1',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        correctOptionIndex: 1,
        explanation: 'Pilihan B ialah jawapan betul.',
      ),
      QuizQuestion(
        id: 'q3',
        topicId: 'topic-1',
        questionText: 'Soalan ketiga',
        options: const ['Satu', 'Dua', 'Tiga', 'Empat'],
        correctOptionIndex: 3,
        explanation: 'Empat ialah jawapan betul.',
      ),
    ];

    final firstResult = randomizer.randomize(questions: questions, seed: 2026);

    final secondResult = randomizer.randomize(questions: questions, seed: 2026);

    expect(
      firstResult.map((question) => question.id),
      orderedEquals(secondResult.map((question) => question.id)),
    );

    for (var index = 0; index < firstResult.length; index++) {
      expect(
        firstResult[index].options,
        orderedEquals(secondResult[index].options),
      );

      expect(
        firstResult[index].correctOptionIndex,
        secondResult[index].correctOptionIndex,
      );
    }
  });

  test('jawapan betul kekal betul selepas pilihan diacak', () {
    const randomizer = QuizRandomizer();

    final originalQuestion = QuizQuestion(
      id: 'q1',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan yang betul?',
      options: const ['Salah satu', 'Jawapan betul', 'Salah dua', 'Salah tiga'],
      correctOptionIndex: 1,
      explanation: 'Jawapan betul ialah pilihan yang tepat.',
    );

    final randomized = randomizer.randomize(
      questions: [originalQuestion],
      seed: 12345,
      shuffleQuestionOrder: false,
    );

    final randomizedQuestion = randomized.single;

    expect(
      randomizedQuestion.correctAnswerText,
      originalQuestion.correctAnswerText,
    );

    expect(
      randomizedQuestion.isCorrect(randomizedQuestion.correctOptionIndex),
      isTrue,
    );
  });

  test('tidak mengacak pilihan apabila shuffleOptions false', () {
    const randomizer = QuizRandomizer();

    final question = QuizQuestion(
      id: 'q-sequence',
      topicId: 'topic-1',
      questionText: 'Pilih susunan proses yang tepat.',
      options: const [
        'I, II, III, IV',
        'II, I, III, IV',
        'III, II, I, IV',
        'IV, III, II, I',
      ],
      correctOptionIndex: 0,
      explanation: 'Urutan yang betul ialah I, II, III, IV.',
      shuffleOptions: false,
    );

    final randomized = randomizer.randomize(
      questions: [question],
      seed: 9876,
      shuffleQuestionOrder: false,
    );

    expect(randomized.single.options, orderedEquals(question.options));

    expect(randomized.single.correctOptionIndex, question.correctOptionIndex);
  });
}
