import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_state.dart';
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
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_draft_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_failure.dart';
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

  QuizSessionSource validationSource = QuizSessionSource.standard;
  QuizSessionSource activeSource = QuizSessionSource.standard;

  QuizFailure? validationFailure;
  QuizFailure? startFailure;

  int validateCallCount = 0;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    activeSource = QuizSessionSource.standard;

    final failure = startFailure;

    if (failure != null) {
      throw failure;
    }

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
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) async {
    final failure = startFailure;

    if (failure != null) {
      throw failure;
    }

    activeSource = QuizSessionSource.mistakeReview;

    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000003',
      topicId: topicId,
      mode: QuizMode.practice,
      source: QuizSessionSource.mistakeReview,
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

    final failure = validationFailure;

    if (failure != null) {
      throw failure;
    }

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
      source: validationSource,
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
    required QuizSessionSource sessionSource,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) async {
    expect(sessionSource, activeSource);

    submittedAnswers = Map<String, int>.from(selectedAnswers);

    onServerSubmit();

    final result = QuizResult(
      topicId: 'topic-s1-02',
      topicCode: 'S1-02',
      topicTitle: 'Negara Berdaulat',
      mode: QuizMode.practice,
      sessionSource: activeSource,
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
      earnedXp: activeSource == QuizSessionSource.mistakeReview ? 0 : 30,
      elapsedTime: elapsedTime,
      autoSubmitted: autoSubmitted,
    );

    return QuizSubmission(
      attemptId: '00000000-0000-0000-0000-000000000002',
      earnedXp: activeSource == QuizSessionSource.mistakeReview ? 0 : 30,
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
  int fetchCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    fetchCallCount++;

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

class _CountingMistakeBookController extends MistakeBookController {
  _CountingMistakeBookController({required this.onBuild});

  final void Function() onBuild;

  @override
  MistakeBookState build() {
    onBuild();
    return super.build();
  }
}

void main() {
  test('autosave kuiz dan memadam draft selepas submit', () async {
    final progressRepository = _FakeUserProgressRepository(
      storedProgress: _createProgressBeforeQuiz(),
    );

    final draftRepository = _FakeQuizDraftRepository();

    final quizRepository = _FakeQuizRepository(
      onServerSubmit: () {
        progressRepository.storedProgress = _createProgressAfterQuiz();
      },
    );

    var mistakeBookBuildCount = 0;

    final container = ProviderContainer(
      overrides: [
        mistakeBookControllerProvider.overrideWith(
          () => _CountingMistakeBookController(
            onBuild: () {
              mistakeBookBuildCount++;
            },
          ),
        ),
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

    container.read(mistakeBookControllerProvider);
    expect(mistakeBookBuildCount, 1);

    await controller.startQuiz(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    var state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(draftRepository.storedDraft, isNotNull);

    controller.selectAnswer(0);
    controller.nextQuestion();
    controller.selectAnswer(0);

    await controller.submitQuiz();

    container.read(mistakeBookControllerProvider);

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(mistakeBookBuildCount, 2);

    expect(draftRepository.storedDraft, isNull);

    expect(quizRepository.submittedAnswers, {'q1': 0, 'q2': 0});
  });

  test('latihan semula tidak merekod XP atau sejarah kuiz standard', () async {
    final progressRepository = _FakeUserProgressRepository(
      storedProgress: _createProgressBeforeQuiz(),
    );
    final historyRepository = _FakeQuizHistoryRepository();
    final draftRepository = _FakeQuizDraftRepository();
    final quizRepository = _FakeQuizRepository(onServerSubmit: () {});

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

    await controller.startMistakeReview(
      topicId: 'topic-s1-02',
      questionCount: 2,
    );

    var state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);
    expect(state.source, QuizSessionSource.mistakeReview);
    expect(
      draftRepository.storedDraft?.source,
      QuizSessionSource.mistakeReview,
    );

    controller.selectAnswer(0);
    controller.nextQuestion();
    controller.selectAnswer(0);

    await controller.submitQuiz();

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);
    expect(state.result?.sessionSource, QuizSessionSource.mistakeReview);
    expect(state.result?.earnedXp, 0);
    expect(progressRepository.loadCallCount, 0);
    expect(historyRepository.fetchCallCount, 0);
    expect(draftRepository.storedDraft, isNull);
  });

  test('memuatkan dan memulihkan draft aktif', () async {
    final draftRepository = _FakeQuizDraftRepository()
      ..storedDraft = _createRestorableDraft();

    final quizRepository = _FakeQuizRepository(onServerSubmit: () {});

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

    expect(availableDraft, isNotNull);

    final restored = await controller.restoreDraft(availableDraft!);

    expect(restored, isTrue);

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.currentQuestionIndex, 1);

    expect(state.selectedAnswers, {'draft-q1': 0});

    expect(state.flaggedQuestionIds, {'draft-q2'});
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

    expect(draftRepository.storedDraft, isNull);

    expect(draftRepository.deleteCallCount, 1);
  });

  test('mengekalkan draft apabila pengesahan server gagal', () async {
    final originalDraft = _createRestorableDraft();

    final draftRepository = _FakeQuizDraftRepository()
      ..storedDraft = originalDraft;

    final quizRepository = _FakeQuizRepository(onServerSubmit: () {})
      ..validationFailure = const QuizFailure('Tiada sambungan Internet.');

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

    await expectLater(
      controller.loadAvailableDraft(),
      throwsA(isA<QuizDraftFailure>()),
    );

    expect(draftRepository.storedDraft, same(originalDraft));

    expect(draftRepository.deleteCallCount, 0);
  });

  test('mengekalkan draft lama apabila kuiz baharu gagal dimulakan', () async {
    final originalDraft = _createRestorableDraft();

    final draftRepository = _FakeQuizDraftRepository()
      ..storedDraft = originalDraft;

    final quizRepository = _FakeQuizRepository(onServerSubmit: () {})
      ..startFailure = const QuizFailure('Kuiz tidak dapat dimulakan.');

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

    await controller.startQuiz(
      topicId: 'topic-s1-05',
      mode: QuizMode.practice,
      questionCount: 10,
    );

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.failure);

    expect(draftRepository.storedDraft, same(originalDraft));

    expect(draftRepository.deleteCallCount, 0);
  });
}
