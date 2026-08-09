import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

class _StartQuizRepository implements QuizRepository {
  _StartQuizRepository({this.nextSession, this.startError});

  final QuizSession? nextSession;
  final Object? startError;

  int startQuizCallCount = 0;
  int startMistakeReviewCallCount = 0;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    startQuizCallCount++;

    final error = startError;

    if (error != null) {
      throw error;
    }

    return nextSession ??
        _createSession(
          topicId: topicId,
          mode: mode,
          source: QuizSessionSource.standard,
        );
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) async {
    startMistakeReviewCallCount++;

    final error = startError;

    if (error != null) {
      throw error;
    }

    return nextSession ??
        _createSession(
          topicId: topicId,
          mode: QuizMode.practice,
          source: QuizSessionSource.mistakeReview,
        );
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) {
    throw UnsupportedError(
      'Validation tidak digunakan dalam session-start regression test.',
    );
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required QuizSessionSource sessionSource,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) {
    throw UnsupportedError(
      'Submission tidak digunakan dalam session-start regression test.',
    );
  }
}

class _StartDraftRepository implements QuizDraftRepository {
  _StartDraftRepository({this.storedDraft});

  QuizDraft? storedDraft;

  int loadCallCount = 0;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    loadCallCount++;

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

void main() {
  test(
    'standard Practice session berjaya dan menggantikan draft lama',
    () async {
      final oldDraft = _createOldDraft();

      final repository = _StartQuizRepository(
        nextSession: _createSession(
          topicId: 'topic-new',
          mode: QuizMode.practice,
          source: QuizSessionSource.standard,
          sessionId: '00000000-0000-0000-0000-000000001001',
        ),
      );

      final draftRepository = _StartDraftRepository(storedDraft: oldDraft);

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-new',
        mode: QuizMode.practice,
        questionCount: 10,
      );

      final state = container.read(quizSessionControllerProvider);

      expect(repository.startQuizCallCount, 1);

      expect(state.status, QuizSessionStatus.ready);

      expect(state.sessionId, '00000000-0000-0000-0000-000000001001');

      expect(state.topicId, 'topic-new');

      expect(state.mode, QuizMode.practice);

      expect(state.source, QuizSessionSource.standard);

      expect(state.questions, hasLength(2));

      expect(state.remainingSeconds, isNull);

      /*
       * Sesi server berjaya diwujudkan.
       * Draft lama kini boleh digantikan.
       */
      expect(draftRepository.deleteCallCount, 1);

      expect(draftRepository.saveCallCount, 1);

      expect(draftRepository.storedDraft, isNotNull);

      expect(
        draftRepository.storedDraft?.sessionId,
        '00000000-0000-0000-0000-000000001001',
      );

      expect(draftRepository.storedDraft, isNot(same(oldDraft)));
    },
  );

  test('Mistake Review session mengekalkan source mistakeReview', () async {
    final repository = _StartQuizRepository(
      nextSession: _createSession(
        topicId: 'topic-mistake',
        mode: QuizMode.practice,
        source: QuizSessionSource.mistakeReview,
        sessionId: '00000000-0000-0000-0000-000000001002',
      ),
    );

    final draftRepository = _StartDraftRepository();

    final container = _createContainer(
      repository: repository,
      draftRepository: draftRepository,
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startMistakeReview(
      topicId: 'topic-mistake',
      questionCount: 5,
    );

    final state = container.read(quizSessionControllerProvider);

    expect(repository.startMistakeReviewCallCount, 1);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.mode, QuizMode.practice);

    expect(state.source, QuizSessionSource.mistakeReview);

    expect(
      draftRepository.storedDraft?.source,
      QuizSessionSource.mistakeReview,
    );
  });

  test(
    'empty server questions menghasilkan failure dan mengekalkan draft lama',
    () async {
      final oldDraft = _createOldDraft();

      final repository = _StartQuizRepository(
        nextSession: _createSession(
          topicId: 'topic-empty',
          mode: QuizMode.practice,
          source: QuizSessionSource.standard,
          questions: <QuizSessionQuestion>[],
        ),
      );

      final draftRepository = _StartDraftRepository(storedDraft: oldDraft);

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-empty',
        mode: QuizMode.practice,
        questionCount: 10,
      );

      final state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.failure);

      expect(state.errorMessage, 'Tiada soalan tersedia untuk topik ini.');

      expect(draftRepository.storedDraft, same(oldDraft));

      expect(draftRepository.deleteCallCount, 0);

      expect(draftRepository.saveCallCount, 0);
    },
  );

  test(
    'server source mismatch menghasilkan failure dan mengekalkan draft lama',
    () async {
      final oldDraft = _createOldDraft();

      /*
       * startQuiz() menjangkakan standard,
       * tetapi fake server memulangkan
       * mistakeReview.
       */
      final repository = _StartQuizRepository(
        nextSession: _createSession(
          topicId: 'topic-source',
          mode: QuizMode.practice,
          source: QuizSessionSource.mistakeReview,
        ),
      );

      final draftRepository = _StartDraftRepository(storedDraft: oldDraft);

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-source',
        mode: QuizMode.practice,
        questionCount: 10,
      );

      final state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.failure);

      expect(state.source, QuizSessionSource.standard);

      expect(state.errorMessage, 'Sumber sesi daripada server tidak sepadan.');

      expect(draftRepository.storedDraft, same(oldDraft));

      expect(draftRepository.deleteCallCount, 0);

      expect(draftRepository.saveCallCount, 0);
    },
  );

  test(
    'QuizFailure semasa start mengekalkan mesej server dan draft lama',
    () async {
      final oldDraft = _createOldDraft();

      final repository = _StartQuizRepository(
        startError: const QuizFailure('Server kuiz tidak tersedia.'),
      );

      final draftRepository = _StartDraftRepository(storedDraft: oldDraft);

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-failure',
        mode: QuizMode.practice,
        questionCount: 10,
      );

      final state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.failure);

      expect(state.errorMessage, 'Server kuiz tidak tersedia.');

      expect(draftRepository.storedDraft, same(oldDraft));

      expect(draftRepository.deleteCallCount, 0);

      expect(draftRepository.saveCallCount, 0);
    },
  );

  test(
    'unexpected start error menggunakan fallback message dan mengekalkan draft',
    () async {
      final oldDraft = _createOldDraft();

      final repository = _StartQuizRepository(
        startError: StateError('Unexpected test failure.'),
      );

      final draftRepository = _StartDraftRepository(storedDraft: oldDraft);

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-unexpected',
        mode: QuizMode.practice,
        questionCount: 10,
      );

      final state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.failure);

      expect(
        state.errorMessage,
        'Kuiz tidak dapat dimulakan. Sila cuba semula.',
      );

      expect(draftRepository.storedDraft, same(oldDraft));

      expect(draftRepository.deleteCallCount, 0);

      expect(draftRepository.saveCallCount, 0);
    },
  );
}

ProviderContainer _createContainer({
  required _StartQuizRepository repository,
  required _StartDraftRepository draftRepository,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(repository),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('session-start-test-user'),
    ],
  );
}

QuizSession _createSession({
  required String topicId,
  required QuizMode mode,
  required QuizSessionSource source,
  String sessionId = '00000000-0000-0000-0000-000000001000',
  List<QuizSessionQuestion>? questions,
}) {
  final serverTime = DateTime.utc(2026, 8, 9, 10);

  return QuizSession(
    sessionId: sessionId,
    topicId: topicId,
    mode: mode,
    source: source,
    questionCount: 2,
    createdAt: serverTime,
    serverTime: serverTime,
    expiresAt: serverTime.add(const Duration(hours: 2)),
    questions: questions ?? _questions(topicId),
  );
}

List<QuizSessionQuestion> _questions(String topicId) {
  return [
    QuizSessionQuestion(
      id: 'start-q1',
      topicId: topicId,
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'start-q2',
      topicId: topicId,
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}

QuizDraft _createOldDraft() {
  final startedAt = DateTime.utc(2026, 8, 9, 8);

  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000009999',
    topicId: 'topic-old',
    mode: QuizMode.practice,
    questionCount: 2,
    questions: _questions('topic-old'),
    currentQuestionIndex: 1,
    selectedAnswers: const {'start-q1': 0},
    flaggedQuestionIds: const {'start-q2'},
    startedAt: startedAt,
    sessionExpiresAt: startedAt.add(const Duration(hours: 2)),
    savedAt: startedAt.add(const Duration(minutes: 5)),
  );
}
