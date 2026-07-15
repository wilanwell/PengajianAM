import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  _FakeQuizHistoryRepository({required this.attempts});

  List<QuizAttempt> attempts;

  @override
  Future<List<QuizAttempt>> loadAttempts() async {
    return List<QuizAttempt>.unmodifiable(attempts);
  }

  @override
  Future<void> saveAttempts(List<QuizAttempt> attempts) async {
    this.attempts = List<QuizAttempt>.from(attempts);
  }

  @override
  Future<void> clearAttempts() async {
    attempts = [];
  }
}

void main() {
  test('mengira analitik prestasi mengikut topik', () async {
    final firstQuestion = QuizQuestion(
      id: 'q1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: const ['A', 'B'],
      correctOptionIndex: 0,
      explanation: 'Penerangan pertama',
    );

    final secondQuestion = QuizQuestion(
      id: 'q2',
      topicId: 'topic-2',
      questionText: 'Soalan kedua',
      options: const ['A', 'B'],
      correctOptionIndex: 0,
      explanation: 'Penerangan kedua',
    );

    final thirdQuestion = QuizQuestion(
      id: 'q3',
      topicId: 'topic-2',
      questionText: 'Soalan ketiga',
      options: const ['A', 'B'],
      correctOptionIndex: 1,
      explanation: 'Penerangan ketiga',
    );

    final firstResult = QuizResult(
      topicId: 'topic-1',
      topicCode: 'S1-01',
      topicTitle: 'Topik Pertama',
      mode: QuizMode.practice,
      questions: [firstQuestion],
      selectedAnswers: const {'q1': 0},
      correctAnswers: 1,
      answeredQuestions: 1,
      elapsedTime: const Duration(seconds: 20),
      autoSubmitted: false,
    );

    final secondResult = QuizResult(
      topicId: 'topic-2',
      topicCode: 'S1-02',
      topicTitle: 'Topik Kedua',
      mode: QuizMode.practice,
      questions: [secondQuestion, thirdQuestion],
      selectedAnswers: const {'q2': 0, 'q3': 0},
      correctAnswers: 1,
      answeredQuestions: 2,
      elapsedTime: const Duration(seconds: 40),
      autoSubmitted: false,
    );

    final repository = _FakeQuizHistoryRepository(
      attempts: [
        QuizAttempt.create(result: firstResult, earnedXp: 80),
        QuizAttempt.create(result: secondResult, earnedXp: 30),
      ],
    );

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      topicAnalyticsControllerProvider.notifier,
    );

    await controller.loadAnalytics();

    final state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.success);

    expect(state.performances, hasLength(2));

    expect(state.totalAttempts, 2);

    expect(state.totalQuestions, 3);

    expect(state.totalCorrectAnswers, 2);

    expect(state.overallAverageScore, closeTo(66.67, 0.01));

    expect(state.strongestTopic?.topicTitle, 'Topik Pertama');

    expect(state.strongestTopic?.averageScore, 100);

    expect(state.weakestTopic?.topicTitle, 'Topik Kedua');

    expect(state.weakestTopic?.averageScore, 50);
  });
}
