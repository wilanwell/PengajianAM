import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

class _FakeQuizRepository implements QuizRepository {
  Map<String, int>? submittedAnswers;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000001',
      topicId: topicId,
      mode: mode,
      questionCount: 2,
      expiresAt: DateTime(2026, 7, 16, 12),

      // Jangan gunakan const pada senarai ini kerana
      // QuizSessionQuestion memeriksa options.length.
      questions: [
        QuizSessionQuestion(
          id: 'q1',
          topicId: 'topic-s1-02',
          questionText: 'Soalan satu',
          options: const ['Betul', 'Salah'],
          questionOrder: 1,
        ),
        QuizSessionQuestion(
          id: 'q2',
          topicId: 'topic-s1-02',
          questionText: 'Soalan dua',
          options: const ['Salah', 'Betul'],
          questionOrder: 2,
        ),
      ],
    );
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) async {
    submittedAnswers = Map<String, int>.from(selectedAnswers);

    final result = QuizResult(
      topicId: 'topic-s1-02',
      topicCode: 'S1-02',
      topicTitle: 'Negara Berdaulat',
      mode: QuizMode.practice,
      questions: [
        QuizQuestion(
          id: 'q1',
          topicId: 'topic-s1-02',
          questionText: 'Soalan satu',
          options: const ['Betul', 'Salah'],
          correctOptionIndex: 0,
          explanation: 'Jawapan Betul adalah tepat.',
          shuffleOptions: false,
        ),
        QuizQuestion(
          id: 'q2',
          topicId: 'topic-s1-02',
          questionText: 'Soalan dua',
          options: const ['Salah', 'Betul'],
          correctOptionIndex: 1,
          explanation: 'Jawapan Betul adalah tepat.',
          shuffleOptions: false,
        ),
      ],
      selectedAnswers: Map<String, int>.unmodifiable(selectedAnswers),
      correctAnswers: 1,
      answeredQuestions: selectedAnswers.length,
      elapsedTime: elapsedTime,
      autoSubmitted: autoSubmitted,
    );

    return QuizSubmission(
      attemptId: '00000000-0000-0000-0000-000000000002',
      earnedXp: 30,
      completedAt: DateTime(2026, 7, 16, 11),
      result: result,
    );
  }
}

class _FakeUserProgressRepository implements UserProgressRepository {
  UserProgress? storedProgress;

  @override
  Future<UserProgress?> loadProgress() async {
    return storedProgress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    storedProgress = progress;
  }

  @override
  Future<void> clearProgress() async {
    storedProgress = null;
  }
}

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  List<QuizAttempt> attempts = [];

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
  test('memulakan, menghantar dan menyimpan kuiz server', () async {
    final quizRepository = _FakeQuizRepository();

    final progressRepository = _FakeUserProgressRepository();

    final historyRepository = _FakeQuizHistoryRepository();

    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(quizRepository),
        userProgressRepositoryProvider.overrideWithValue(progressRepository),
        quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    var state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.sessionId, '00000000-0000-0000-0000-000000000001');

    expect(state.questions, hasLength(2));

    expect(state.currentQuestion?.id, 'q1');

    // Jawab soalan pertama dengan jawapan betul.
    controller.selectAnswer(0);

    controller.nextQuestion();

    state = container.read(quizSessionControllerProvider);

    expect(state.currentQuestion?.id, 'q2');

    // Jawab soalan kedua dengan jawapan salah.
    controller.selectAnswer(0);

    await controller.submitQuiz();

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.result, isNotNull);

    expect(state.result!.correctAnswers, 1);

    expect(state.result!.answeredQuestions, 2);

    expect(state.result!.totalQuestions, 2);

    expect(quizRepository.submittedAnswers, {'q1': 0, 'q2': 0});

    expect(progressRepository.storedProgress, isNotNull);

    // Nilai awal ialah 1820 XP dan server memberikan 30 XP.
    expect(progressRepository.storedProgress!.totalXp, 1850);

    expect(historyRepository.attempts, hasLength(1));

    expect(
      historyRepository.attempts.first.id,
      '00000000-0000-0000-0000-000000000002',
    );

    expect(historyRepository.attempts.first.earnedXp, 30);

    expect(historyRepository.attempts.first.result.correctAnswers, 1);
  });
}
