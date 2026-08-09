import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_state.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_topic_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_topic_state.dart';
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
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

class _SubmissionQuizRepository implements QuizRepository {
  QuizSessionSource activeSource = QuizSessionSource.standard;

  QuizFailure? submissionFailure;

  int submitCallCount = 0;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    activeSource = QuizSessionSource.standard;

    return _createSession(topicId: topicId, source: QuizSessionSource.standard);
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) async {
    activeSource = QuizSessionSource.mistakeReview;

    return _createSession(
      topicId: topicId,
      source: QuizSessionSource.mistakeReview,
    );
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) {
    throw UnsupportedError(
      'Validation tidak digunakan dalam submission sync test.',
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
    submitCallCount++;

    final failure = submissionFailure;

    if (failure != null) {
      throw failure;
    }

    return QuizSubmission(
      attemptId: '00000000-0000-0000-0000-000000000802',
      earnedXp: activeSource == QuizSessionSource.standard ? 30 : 0,
      completedAt: DateTime.utc(2026, 8, 9, 6),
      result: _createResult(
        source: activeSource,
        selectedAnswers: selectedAnswers,
        elapsedTime: elapsedTime,
        autoSubmitted: autoSubmitted,
      ),
    );
  }
}

class _SubmissionDraftRepository implements QuizDraftRepository {
  QuizDraft? storedDraft;

  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    return storedDraft;
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    saveCallCount++;
    storedDraft = draft;
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    deleteCallCount++;
    storedDraft = null;
  }
}

class _SubmissionProgressRepository implements UserProgressRepository {
  _SubmissionProgressRepository({this.throwOnLoad = false});

  final bool throwOnLoad;

  int loadCallCount = 0;

  @override
  Future<UserProgress?> loadProgress() async {
    loadCallCount++;

    if (throwOnLoad) {
      throw StateError('Progress refresh sengaja digagalkan.');
    }

    return _createProgress();
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {}

  @override
  Future<void> clearProgress() async {}
}

class _SubmissionHistoryRepository implements QuizHistoryRepository {
  int fetchCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    fetchCallCount++;

    return QuizHistorySnapshot(
      generatedAt: DateTime.utc(2026, 8, 9, 6),
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

class _CountingMistakeBookController extends MistakeBookController {
  _CountingMistakeBookController(this.onBuild);

  final void Function() onBuild;

  @override
  MistakeBookState build() {
    onBuild();
    return super.build();
  }
}

class _CountingMistakeBookTopicController extends MistakeBookTopicController {
  _CountingMistakeBookTopicController(this.onBuild);

  final void Function() onBuild;

  @override
  MistakeBookTopicState build() {
    onBuild();
    return super.build();
  }
}

void main() {
  test('standard submission menyegerakkan post-success state', () async {
    final quizRepository = _SubmissionQuizRepository();

    final draftRepository = _SubmissionDraftRepository();

    final progressRepository = _SubmissionProgressRepository();

    final historyRepository = _SubmissionHistoryRepository();

    var mistakeBookBuildCount = 0;
    var mistakeTopicBuildCount = 0;

    final container = _createContainer(
      quizRepository: quizRepository,
      draftRepository: draftRepository,
      progressRepository: progressRepository,
      historyRepository: historyRepository,
      onMistakeBookBuild: () {
        mistakeBookBuildCount++;
      },
      onMistakeTopicBuild: () {
        mistakeTopicBuildCount++;
      },
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    /*
       * Instantiate kedua-dua provider dahulu
       * supaya invalidation selepas submission
       * boleh dikesan melalui build count.
       */
    container.read(mistakeBookControllerProvider);

    container.read(mistakeBookTopicControllerProvider);

    expect(mistakeBookBuildCount, 1);

    expect(mistakeTopicBuildCount, 1);

    await controller.startQuiz(
      topicId: 'topic-submit',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    expect(draftRepository.storedDraft, isNotNull);

    controller.selectAnswer(0);

    await controller.submitQuiz();

    /*
       * Read semula provider yang telah
       * di-invalidate oleh submission.
       */
    container.read(mistakeBookControllerProvider);

    container.read(mistakeBookTopicControllerProvider);

    final state = container.read(quizSessionControllerProvider);

    final historyState = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.result, isNotNull);

    expect(quizRepository.submitCallCount, 1);

    expect(draftRepository.storedDraft, isNull);

    expect(progressRepository.loadCallCount, 1);

    expect(historyState.totalCount, 1);

    expect(historyState.attempts, hasLength(1));

    expect(
      historyState.attempts.first.id,
      '00000000-0000-0000-0000-000000000802',
    );

    expect(mistakeBookBuildCount, 2);

    expect(mistakeTopicBuildCount, 2);
  });

  test('kegagalan refresh progress tidak membatalkan server success', () async {
    final quizRepository = _SubmissionQuizRepository();

    final draftRepository = _SubmissionDraftRepository();

    final progressRepository = _SubmissionProgressRepository(throwOnLoad: true);

    final historyRepository = _SubmissionHistoryRepository();

    final container = _createContainer(
      quizRepository: quizRepository,
      draftRepository: draftRepository,
      progressRepository: progressRepository,
      historyRepository: historyRepository,
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-submit',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    controller.selectAnswer(0);

    await controller.submitQuiz();

    final state = container.read(quizSessionControllerProvider);

    final historyState = container.read(quizHistoryControllerProvider);

    expect(quizRepository.submitCallCount, 1);

    expect(progressRepository.loadCallCount, 1);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.errorMessage, isNull);

    expect(draftRepository.storedDraft, isNull);

    /*
       * Progress refresh gagal tetapi
       * synchronization lain masih diteruskan.
       */
    expect(historyState.totalCount, 1);
  });

  test(
    'mistake review tidak merekod progress atau quiz history standard',
    () async {
      final quizRepository = _SubmissionQuizRepository();

      final draftRepository = _SubmissionDraftRepository();

      final progressRepository = _SubmissionProgressRepository();

      final historyRepository = _SubmissionHistoryRepository();

      var mistakeBookBuildCount = 0;
      var mistakeTopicBuildCount = 0;

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
        progressRepository: progressRepository,
        historyRepository: historyRepository,
        onMistakeBookBuild: () {
          mistakeBookBuildCount++;
        },
        onMistakeTopicBuild: () {
          mistakeTopicBuildCount++;
        },
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      container.read(mistakeBookControllerProvider);

      container.read(mistakeBookTopicControllerProvider);

      await controller.startMistakeReview(
        topicId: 'topic-submit',
        questionCount: 2,
      );

      controller.selectAnswer(0);

      await controller.submitQuiz();

      container.read(mistakeBookControllerProvider);

      container.read(mistakeBookTopicControllerProvider);

      final state = container.read(quizSessionControllerProvider);

      final historyState = container.read(quizHistoryControllerProvider);

      expect(state.status, QuizSessionStatus.completed);

      expect(state.source, QuizSessionSource.mistakeReview);

      expect(state.result?.earnedXp, 0);

      expect(draftRepository.storedDraft, isNull);

      expect(progressRepository.loadCallCount, 0);

      expect(historyRepository.fetchCallCount, 0);

      expect(historyState.totalCount, 0);

      expect(historyState.attempts, isEmpty);

      expect(mistakeBookBuildCount, 2);

      expect(mistakeTopicBuildCount, 2);
    },
  );

  test(
    'server submission failure tidak menjalankan success synchronization',
    () async {
      final quizRepository = _SubmissionQuizRepository()
        ..submissionFailure = const QuizFailure('Server submission gagal.');

      final draftRepository = _SubmissionDraftRepository();

      final progressRepository = _SubmissionProgressRepository();

      final historyRepository = _SubmissionHistoryRepository();

      var mistakeBookBuildCount = 0;
      var mistakeTopicBuildCount = 0;

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
        progressRepository: progressRepository,
        historyRepository: historyRepository,
        onMistakeBookBuild: () {
          mistakeBookBuildCount++;
        },
        onMistakeTopicBuild: () {
          mistakeTopicBuildCount++;
        },
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      container.read(mistakeBookControllerProvider);

      container.read(mistakeBookTopicControllerProvider);

      await controller.startQuiz(
        topicId: 'topic-submit',
        mode: QuizMode.practice,
        questionCount: 2,
      );

      controller.selectAnswer(0);

      expect(draftRepository.storedDraft, isNotNull);

      await controller.submitQuiz();

      final state = container.read(quizSessionControllerProvider);

      expect(quizRepository.submitCallCount, 1);

      expect(state.status, QuizSessionStatus.ready);

      expect(state.errorMessage, 'Server submission gagal.');

      expect(draftRepository.storedDraft, isNotNull);

      expect(progressRepository.loadCallCount, 0);

      expect(historyRepository.fetchCallCount, 0);

      /*
       * Success path tidak dicapai,
       * jadi kedua-dua provider tidak
       * sepatutnya di-invalidate.
       */
      expect(mistakeBookBuildCount, 1);

      expect(mistakeTopicBuildCount, 1);
    },
  );
}

ProviderContainer _createContainer({
  required _SubmissionQuizRepository quizRepository,
  required _SubmissionDraftRepository draftRepository,
  required _SubmissionProgressRepository progressRepository,
  required _SubmissionHistoryRepository historyRepository,
  void Function()? onMistakeBookBuild,
  void Function()? onMistakeTopicBuild,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(quizRepository),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('submission-test-user'),
      userProgressRepositoryProvider.overrideWithValue(progressRepository),
      quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
      if (onMistakeBookBuild != null)
        mistakeBookControllerProvider.overrideWith(
          () => _CountingMistakeBookController(onMistakeBookBuild),
        ),
      if (onMistakeTopicBuild != null)
        mistakeBookTopicControllerProvider.overrideWith(
          () => _CountingMistakeBookTopicController(onMistakeTopicBuild),
        ),
    ],
  );
}

QuizSession _createSession({
  required String topicId,
  required QuizSessionSource source,
}) {
  return QuizSession(
    sessionId: source == QuizSessionSource.standard
        ? '00000000-0000-0000-0000-000000000801'
        : '00000000-0000-0000-0000-000000000803',
    topicId: topicId,
    mode: QuizMode.practice,
    source: source,
    questionCount: 2,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    questions: _questions(topicId: topicId),
  );
}

QuizResult _createResult({
  required QuizSessionSource source,
  required Map<String, int> selectedAnswers,
  required Duration elapsedTime,
  required bool autoSubmitted,
}) {
  return QuizResult(
    topicId: 'topic-submit',
    topicCode: 'S1-TEST',
    topicTitle: 'Topik Submission Test',
    mode: QuizMode.practice,
    sessionSource: source,
    questions: [
      QuizQuestion(
        id: 'submit-q1',
        topicId: 'topic-submit',
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        correctOptionIndex: 0,
        explanation: 'Pilihan A tepat.',
        shuffleOptions: false,
      ),
      QuizQuestion(
        id: 'submit-q2',
        topicId: 'topic-submit',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        correctOptionIndex: 1,
        explanation: 'Pilihan B tepat.',
        shuffleOptions: false,
      ),
    ],
    selectedAnswers: Map<String, int>.unmodifiable(selectedAnswers),
    correctAnswers: 1,
    answeredQuestions: selectedAnswers.length,
    earnedXp: source == QuizSessionSource.standard ? 30 : 0,
    elapsedTime: elapsedTime,
    autoSubmitted: autoSubmitted,
  );
}

List<QuizSessionQuestion> _questions({required String topicId}) {
  return [
    QuizSessionQuestion(
      id: 'submit-q1',
      topicId: topicId,
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'submit-q2',
      topicId: topicId,
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}

UserProgress _createProgress() {
  return UserProgress(
    userId: 'submission-test-user',
    displayName: 'Pelajar Test',
    email: 'student@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime.utc(2026, 1, 1),
    totalXp: 100,
    weeklyXp: 100,
    monthlyXp: 100,
    completedQuizzes: 1,
    totalCorrectAnswers: 5,
    totalQuizQuestions: 10,
    highestScore: 50,
    completedTopics: 1,
    totalTopics: 7,
    currentStreakDays: 1,
    bestStreakDays: 1,
    weeklyAnsweredQuestions: List<int>.unmodifiable(const [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]),
  );
}
