import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_review_coordinator.dart';

void main() {
  const coordinator = QuizReviewCoordinator();

  group('QuizReviewCoordinator', () {
    test('penapis Semua memaparkan '
        'semua indeks soalan', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildResult(),
        filter: QuizReviewFilter.all,
      );

      expect(indexes, [0, 1, 2]);
    });

    test('penapis Betul hanya memaparkan '
        'jawapan yang betul', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildResult(),
        filter: QuizReviewFilter.correct,
      );

      expect(indexes, [0]);
    });

    test('penapis Salah hanya memaparkan '
        'jawapan yang salah', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildResult(),
        filter: QuizReviewFilter.incorrect,
      );

      expect(indexes, [1]);
    });

    test('penapis Tidak Dijawab hanya '
        'memaparkan soalan tanpa jawapan', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildResult(),
        filter: QuizReviewFilter.unanswered,
      );

      expect(indexes, [2]);
    });

    test('mengembalikan senarai kosong '
        'apabila kategori tiada soalan', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildAllCorrectResult(),
        filter: QuizReviewFilter.incorrect,
      );

      expect(indexes, isEmpty);
    });

    test('mengembalikan label bagi '
        'setiap penapis', () {
      expect(coordinator.filterLabel(QuizReviewFilter.all), 'Semua');

      expect(coordinator.filterLabel(QuizReviewFilter.correct), 'Betul');

      expect(coordinator.filterLabel(QuizReviewFilter.incorrect), 'Salah');

      expect(
        coordinator.filterLabel(QuizReviewFilter.unanswered),
        'Tidak Dijawab',
      );
    });

    test('senarai indeks yang dikembalikan '
        'tidak boleh diubah', () {
      final indexes = coordinator.visibleQuestionIndexes(
        result: _buildResult(),
        filter: QuizReviewFilter.all,
      );

      expect(() {
        indexes.add(4);
      }, throwsUnsupportedError);
    });
  });
}

QuizResult _buildResult() {
  return QuizResult(
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questions: _buildQuestions(),
    selectedAnswers: const {'question-1': 0, 'question-2': 0},
    correctAnswers: 1,
    answeredQuestions: 2,
    elapsedTime: const Duration(minutes: 2),
    autoSubmitted: false,
  );
}

QuizResult _buildAllCorrectResult() {
  return QuizResult(
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questions: _buildQuestions(),
    selectedAnswers: const {'question-1': 0, 'question-2': 1, 'question-3': 1},
    correctAnswers: 3,
    answeredQuestions: 3,
    elapsedTime: const Duration(minutes: 2),
    autoSubmitted: false,
  );
}

List<QuizQuestion> _buildQuestions() {
  return [
    QuizQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan pertama?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 0,
      explanation: 'Pilihan A ialah jawapan betul.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan kedua?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Pilihan B ialah jawapan betul.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-3',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan ketiga?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Pilihan B ialah jawapan betul.',
      shuffleOptions: false,
    ),
  ];
}
