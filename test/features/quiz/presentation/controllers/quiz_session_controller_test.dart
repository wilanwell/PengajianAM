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
  _FakeQuizRepository({required this.onServerSubmit});

  final void Function() onServerSubmit;

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
      questions: [
        QuizSessionQuestion(
          id: 'q1',
          topicId: topicId,
          questionText: 'Soalan satu',
          options: const ['Betul', 'Salah'],
          questionOrder: 1,
        ),
        QuizSessionQuestion(
          id: 'q2',
          topicId: topicId,
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

    // Dalam aplikasi sebenar, RPC Supabase
    // mengemas kini public.user_progress.
    // Dalam unit test, callback ini mewakili
    // perubahan progress tersebut.
    onServerSubmit();

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
      earnedXp: 30,
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
  _FakeUserProgressRepository({required this.storedProgress});

  UserProgress? storedProgress;

  int loadCallCount = 0;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<UserProgress?> loadProgress() async {
    loadCallCount++;

    return storedProgress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    storedProgress = progress;
    saveCallCount++;
  }

  @override
  Future<void> clearProgress() async {
    storedProgress = null;
    clearCallCount++;
  }
}

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

UserProgress _createProgressBeforeQuiz() {
  return UserProgress(
    userId: 'current-user',
    displayName: 'PelajarPA',
    email: 'student@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime(2026, 1, 10),
    totalXp: 1820,
    weeklyXp: 1820,
    monthlyXp: 6540,
    completedQuizzes: 8,
    totalCorrectAnswers: 122,
    totalQuizQuestions: 160,
    highestScore: 82,
    completedTopics: 3,
    totalTopics: 7,
    currentStreakDays: 4,
    bestStreakDays: 9,
    weeklyAnsweredQuestions: List<int>.unmodifiable([
      12,
      18,
      8,
      24,
      20,
      30,
      16,
    ]),
  );
}

UserProgress _createProgressAfterQuiz() {
  return UserProgress(
    userId: 'current-user',
    displayName: 'PelajarPA',
    email: 'student@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime(2026, 1, 10),

    // Nilai progress selepas server
    // menyimpan keputusan kuiz.
    totalXp: 1850,
    weeklyXp: 1850,
    monthlyXp: 6570,
    completedQuizzes: 9,
    totalCorrectAnswers: 123,
    totalQuizQuestions: 162,
    highestScore: 82,
    completedTopics: 3,
    totalTopics: 7,
    currentStreakDays: 4,
    bestStreakDays: 9,
    weeklyAnsweredQuestions: List<int>.unmodifiable([
      12,
      18,
      8,
      24,
      20,
      32,
      16,
    ]),
  );
}

void main() {
  test('memulakan, menghantar dan menyimpan kuiz server', () async {
    final progressRepository = _FakeUserProgressRepository(
      storedProgress: _createProgressBeforeQuiz(),
    );

    final historyRepository = _FakeQuizHistoryRepository();

    final quizRepository = _FakeQuizRepository(
      onServerSubmit: () {
        // Dalam aplikasi sebenar, perubahan ini
        // dilakukan oleh RPC Supabase.
        progressRepository.storedProgress = _createProgressAfterQuiz();
      },
    );

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

    // Jawab soalan pertama dengan betul.
    controller.selectAnswer(0);

    controller.nextQuestion();

    state = container.read(quizSessionControllerProvider);

    expect(state.currentQuestion?.id, 'q2');

    // Jawab soalan kedua dengan salah.
    controller.selectAnswer(0);

    await controller.submitQuiz();

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.result, isNotNull);

    expect(state.result!.correctAnswers, 1);

    expect(state.result!.answeredQuestions, 2);

    expect(state.result!.totalQuestions, 2);

    expect(state.result!.earnedXp, 30);

    expect(quizRepository.submittedAnswers, {'q1': 0, 'q2': 0});

    // UserProgressController mengambil semula
    // progress terbaru daripada repository.
    final refreshedProgress = container.read(userProgressControllerProvider);

    expect(progressRepository.storedProgress, isNotNull);

    expect(refreshedProgress.totalXp, 1850);

    expect(refreshedProgress.weeklyXp, 1850);

    expect(refreshedProgress.monthlyXp, 6570);

    expect(refreshedProgress.completedQuizzes, 9);

    expect(refreshedProgress.totalCorrectAnswers, 123);

    expect(refreshedProgress.totalQuizQuestions, 162);

    expect(progressRepository.loadCallCount, 1);

    // Attempt disimpan dalam cache sejarah tempatan.
    expect(historyRepository.attempts, hasLength(1));

    final storedAttempt = historyRepository.attempts.first;

    expect(storedAttempt.id, '00000000-0000-0000-0000-000000000002');

    expect(storedAttempt.earnedXp, 30);

    expect(storedAttempt.result.correctAnswers, 1);

    expect(storedAttempt.result.answeredQuestions, 2);

    expect(storedAttempt.result.earnedXp, 30);

    expect(historyRepository.saveCallCount, 1);
  });
}
