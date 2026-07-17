import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_history_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

class _FakeQuizRepository implements QuizRepository {
  _FakeQuizRepository({required this.onServerSubmit});

  final void Function() onServerSubmit;

  Map<String, int>? submittedAnswers;

  QuizSessionServerStatus validationStatus = QuizSessionServerStatus.active;

  int validateCallCount = 0;

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
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
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
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) async {
    validateCallCount++;

    final now = DateTime.now();

    if (validationStatus == QuizSessionServerStatus.notFound) {
      return QuizSessionValidation(
        sessionId: sessionId,
        status: validationStatus,
        canResume: false,
        serverTime: now,
      );
    }

    return QuizSessionValidation(
      sessionId: sessionId,
      status: validationStatus,
      canResume: validationStatus == QuizSessionServerStatus.active,
      serverTime: now,
      topicId: 'topic-s1-03',
      mode: QuizMode.practice,
      questionCount: 2,
      createdAt: now.subtract(const Duration(minutes: 5)),
      expiresAt: validationStatus == QuizSessionServerStatus.expired
          ? now.subtract(const Duration(seconds: 1))
          : now.add(const Duration(hours: 1)),
      submittedAt: validationStatus == QuizSessionServerStatus.submitted
          ? now.subtract(const Duration(seconds: 5))
          : null,
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
      completedAt: DateTime(2026, 7, 17, 11),
      result: result,
    );
  }
}

class _FakeUserProgressRepository implements UserProgressRepository {
  _FakeUserProgressRepository({required this.storedProgress});

  UserProgress? storedProgress;

  int loadCallCount = 0;

  @override
  Future<UserProgress?> loadProgress() async {
    loadCallCount++;

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
  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    return QuizHistorySnapshot(
      generatedAt: DateTime(2026, 7, 17, 10),
      totalCount: 0,
      attempts: const [],
    );
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {}

  @override
  Future<int> clearHistory() async {
    return 0;
  }
}

class _FakeQuizDraftRepository implements QuizDraftRepository {
  QuizDraft? storedDraft;

  int loadCallCount = 0;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  String? lastOwnerUserId;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    loadCallCount++;
    lastOwnerUserId = ownerUserId;

    return storedDraft;
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    saveCallCount++;
    lastOwnerUserId = ownerUserId;
    storedDraft = draft;
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    deleteCallCount++;
    lastOwnerUserId = ownerUserId;
    storedDraft = null;
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

QuizDraft _createRestorableDraft() {
  final now = DateTime.now();

  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000000900',
    topicId: 'topic-s1-03',
    mode: QuizMode.practice,
    questionCount: 2,
    questions: [
      QuizSessionQuestion(
        id: 'draft-q1',
        topicId: 'topic-s1-03',
        questionText: 'Soalan draft pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 1,
      ),
      QuizSessionQuestion(
        id: 'draft-q2',
        topicId: 'topic-s1-03',
        questionText: 'Soalan draft kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 2,
      ),
    ],
    currentQuestionIndex: 1,
    selectedAnswers: const {'draft-q1': 0},
    flaggedQuestionIds: const {'draft-q2'},
    startedAt: now.subtract(const Duration(minutes: 2)),
    sessionExpiresAt: now.add(const Duration(hours: 1)),
    savedAt: now.subtract(const Duration(seconds: 10)),
  );
}

void main() {
  test('autosave kuiz dan memadam draft selepas submit', () async {
    final progressRepository = _FakeUserProgressRepository(
      storedProgress: _createProgressBeforeQuiz(),
    );

    final historyRepository = _FakeQuizHistoryRepository();

    final draftRepository = _FakeQuizDraftRepository();

    final quizRepository = _FakeQuizRepository(
      onServerSubmit: () {
        progressRepository.storedProgress = _createProgressAfterQuiz();
      },
    );

    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(quizRepository),
        quizDraftRepositoryProvider.overrideWithValue(draftRepository),
        quizDraftOwnerIdProvider.overrideWithValue('current-user'),
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

    var sessionState = container.read(quizSessionControllerProvider);

    expect(sessionState.status, QuizSessionStatus.ready);

    expect(draftRepository.storedDraft, isNotNull);

    expect(draftRepository.saveCallCount, 1);

    expect(draftRepository.storedDraft!.topicId, 'topic-s1-02');

    controller.selectAnswer(0);
    controller.nextQuestion();
    controller.toggleFlagCurrentQuestion();
    controller.selectAnswer(0);

    await controller.submitQuiz();

    sessionState = container.read(quizSessionControllerProvider);

    expect(sessionState.status, QuizSessionStatus.completed);

    expect(sessionState.result, isNotNull);

    expect(sessionState.result!.earnedXp, 30);

    expect(quizRepository.submittedAnswers, {'q1': 0, 'q2': 0});

    expect(draftRepository.saveCallCount, greaterThanOrEqualTo(5));

    expect(draftRepository.storedDraft, isNull);

    expect(draftRepository.deleteCallCount, 2);

    expect(draftRepository.lastOwnerUserId, 'current-user');

    final refreshedProgress = container.read(userProgressControllerProvider);

    expect(refreshedProgress.totalXp, 1850);

    final historyState = container.read(quizHistoryControllerProvider);

    expect(historyState.attempts, hasLength(1));

    expect(
      historyState.attempts.first.id,
      '00000000-0000-0000-0000-000000000002',
    );
  });

  test('memuatkan, memulihkan dan membuang draft aktif', () async {
    final draftRepository = _FakeQuizDraftRepository()
      ..storedDraft = _createRestorableDraft();

    final progressRepository = _FakeUserProgressRepository(
      storedProgress: _createProgressBeforeQuiz(),
    );

    final quizRepository = _FakeQuizRepository(onServerSubmit: () {});

    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(quizRepository),
        quizDraftRepositoryProvider.overrideWithValue(draftRepository),
        quizDraftOwnerIdProvider.overrideWithValue('current-user'),
        userProgressRepositoryProvider.overrideWithValue(progressRepository),
        quizHistoryRepositoryProvider.overrideWithValue(
          _FakeQuizHistoryRepository(),
        ),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    final availableDraft = await controller.loadAvailableDraft();

    expect(availableDraft, isNotNull);

    expect(draftRepository.loadCallCount, 1);

    expect(quizRepository.validateCallCount, 1);

    final restored = await controller.restoreDraft(availableDraft!);

    expect(restored, isTrue);

    /*
       * Draft disemak sekali ketika dimuatkan
       * dan sekali lagi sebelum dipulihkan.
       */
    expect(quizRepository.validateCallCount, 2);

    var sessionState = container.read(quizSessionControllerProvider);

    expect(sessionState.status, QuizSessionStatus.ready);

    expect(sessionState.sessionId, '00000000-0000-0000-0000-000000000900');

    expect(sessionState.topicId, 'topic-s1-03');

    expect(sessionState.currentQuestionIndex, 1);

    expect(sessionState.selectedAnswers, {'draft-q1': 0});

    expect(sessionState.flaggedQuestionIds, {'draft-q2'});

    expect(sessionState.currentQuestion?.id, 'draft-q2');

    await controller.discardDraft();

    sessionState = container.read(quizSessionControllerProvider);

    expect(sessionState.status, QuizSessionStatus.initial);

    expect(draftRepository.storedDraft, isNull);

    expect(draftRepository.deleteCallCount, 1);
  });

  test('memadam draft apabila sesi server telah dihantar', () async {
    final draftRepository = _FakeQuizDraftRepository()
      ..storedDraft = _createRestorableDraft();

    final quizRepository = _FakeQuizRepository(onServerSubmit: () {})
      ..validationStatus = QuizSessionServerStatus.submitted;

    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(quizRepository),
        quizDraftRepositoryProvider.overrideWithValue(draftRepository),
        quizDraftOwnerIdProvider.overrideWithValue('current-user'),
        userProgressRepositoryProvider.overrideWithValue(
          _FakeUserProgressRepository(
            storedProgress: _createProgressBeforeQuiz(),
          ),
        ),
        quizHistoryRepositoryProvider.overrideWithValue(
          _FakeQuizHistoryRepository(),
        ),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    final availableDraft = await controller.loadAvailableDraft();

    expect(availableDraft, isNull);

    expect(quizRepository.validateCallCount, 1);

    expect(draftRepository.storedDraft, isNull);

    expect(draftRepository.deleteCallCount, 1);
  });
}
