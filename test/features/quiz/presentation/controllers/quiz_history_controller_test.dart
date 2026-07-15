import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_state.dart';

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  List<QuizAttempt> attempts = [];
  int saveCallCount = 0;

  @override
  Future<List<QuizAttempt>> loadAttempts() async {
    return List<QuizAttempt>.unmodifiable(attempts);
  }

  @override
  Future<void> saveAttempts(List<QuizAttempt> attempts) async {
    this.attempts = List<QuizAttempt>.from(attempts);

    saveCallCount++;
  }

  @override
  Future<void> clearAttempts() async {
    attempts = [];
  }
}

void main() {
  test('merekod dan memadam sejarah kuiz', () async {
    final repository = _FakeQuizHistoryRepository();

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    var state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, isEmpty);

    final question = QuizQuestion(
      id: 'q1',
      topicId: 'topic-s1-02',
      questionText: 'Apakah maksud negara berdaulat?',
      options: const ['Bebas mentadbir', 'Dikawal kuasa luar'],
      correctOptionIndex: 0,
      explanation: 'Negara berdaulat bebas mentadbir.',
    );

    final result = QuizResult(
      topicId: 'topic-s1-02',
      topicCode: 'S1-02',
      topicTitle: 'Negara Berdaulat',
      mode: QuizMode.practice,
      questions: [question],
      selectedAnswers: const {'q1': 0},
      correctAnswers: 1,
      answeredQuestions: 1,
      elapsedTime: const Duration(seconds: 30),
      autoSubmitted: false,
    );

    await controller.recordAttempt(result: result, earnedXp: 80);

    state = container.read(quizHistoryControllerProvider);

    expect(state.attempts, hasLength(1));

    expect(state.totalEarnedXp, 80);

    expect(state.averageScore, 100);

    expect(repository.saveCallCount, 1);

    final attemptId = state.attempts.first.id;

    await controller.deleteAttempt(attemptId);

    state = container.read(quizHistoryControllerProvider);

    expect(state.attempts, isEmpty);

    expect(repository.attempts, isEmpty);

    expect(repository.saveCallCount, 2);
  });

  test('memadam semua sejarah kuiz', () async {
    final repository = _FakeQuizHistoryRepository();

    final question = QuizQuestion(
      id: 'q1',
      topicId: 'topic-s1-01',
      questionText: 'Soalan ujian',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 0,
      explanation: 'Penerangan ujian',
    );

    final result = QuizResult(
      topicId: 'topic-s1-01',
      topicCode: 'S1-01',
      topicTitle: 'Kemahiran Insaniah',
      mode: QuizMode.practice,
      questions: [question],
      selectedAnswers: const {'q1': 0},
      correctAnswers: 1,
      answeredQuestions: 1,
      elapsedTime: const Duration(seconds: 20),
      autoSubmitted: false,
    );

    repository.attempts = [QuizAttempt.create(result: result, earnedXp: 80)];

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    expect(
      container.read(quizHistoryControllerProvider).attempts,
      hasLength(1),
    );

    await controller.clearHistory();

    final state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, isEmpty);

    expect(repository.attempts, isEmpty);
  });
}
