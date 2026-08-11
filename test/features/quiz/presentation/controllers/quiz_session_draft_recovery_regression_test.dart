import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_draft_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';

class _RecoveryQuizRepository implements QuizRepository {
  _RecoveryQuizRepository({required this.validation, this.validationError});

  final QuizSessionValidation validation;
  final Object? validationError;

  int validationCallCount = 0;

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) async {
    validationCallCount++;

    final error = validationError;

    if (error != null) {
      throw error;
    }

    return validation;
  }

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) {
    throw UnsupportedError(
      'startQuiz tidak digunakan dalam draft recovery regression test.',
    );
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    throw UnsupportedError(
      'startMistakeReview tidak digunakan dalam draft recovery regression test.',
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
      'submitQuiz tidak digunakan dalam draft recovery regression test.',
    );
  }
}

class _RecoveryDraftRepository implements QuizDraftRepository {
  _RecoveryDraftRepository({this.storedDraft, this.loadError});

  QuizDraft? storedDraft;
  final Object? loadError;

  int loadCallCount = 0;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    loadCallCount++;

    final error = loadError;

    if (error != null) {
      throw error;
    }

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
    'loadAvailableDraft mengembalikan null tanpa validation apabila tiada draft',
    () async {
      final draftRepository = _RecoveryDraftRepository();

      final quizRepository = _RecoveryQuizRepository(
        validation: _createCompatibleValidation(),
      );

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      final result = await controller.loadAvailableDraft();

      expect(result, isNull);
      expect(draftRepository.loadCallCount, 1);
      expect(draftRepository.deleteCallCount, 0);
      expect(quizRepository.validationCallCount, 0);
    },
  );

  test(
    'kegagalan membaca local draft ditukar kepada QuizDraftFailure',
    () async {
      final draftRepository = _RecoveryDraftRepository(
        loadError: StateError('Local storage sengaja gagal.'),
      );

      final quizRepository = _RecoveryQuizRepository(
        validation: _createCompatibleValidation(),
      );

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await expectLater(
        controller.loadAvailableDraft(),
        throwsA(
          isA<QuizDraftFailure>().having(
            (error) => error.message,
            'message',
            'Draft kuiz tidak dapat dibaca daripada peranti.',
          ),
        ),
      );

      expect(draftRepository.deleteCallCount, 0);
      expect(quizRepository.validationCallCount, 0);
    },
  );

  test('draft incompatible dipadam selepas validation server', () async {
    final originalDraft = _createDraft();

    final draftRepository = _RecoveryDraftRepository(
      storedDraft: originalDraft,
    );

    final quizRepository = _RecoveryQuizRepository(
      validation: _createCompatibleValidation(
        source: QuizSessionSource.mistakeReview,
      ),
    );

    final container = _createContainer(
      quizRepository: quizRepository,
      draftRepository: draftRepository,
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    final result = await controller.loadAvailableDraft();

    expect(result, isNull);
    expect(quizRepository.validationCallCount, 1);
    expect(draftRepository.deleteCallCount, 1);
    expect(draftRepository.storedDraft, isNull);
  });

  test(
    'QuizFailure semasa validation mengekalkan draft dan mesej server',
    () async {
      final originalDraft = _createDraft();

      final draftRepository = _RecoveryDraftRepository(
        storedDraft: originalDraft,
      );

      final quizRepository = _RecoveryQuizRepository(
        validation: _createCompatibleValidation(),
        validationError: const QuizFailure('Tiada sambungan Internet.'),
      );

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await expectLater(
        controller.loadAvailableDraft(),
        throwsA(
          isA<QuizDraftFailure>().having(
            (error) => error.message,
            'message',
            'Tiada sambungan Internet. '
                'Sesi tersimpan anda masih selamat pada peranti.',
          ),
        ),
      );

      expect(draftRepository.storedDraft, same(originalDraft));
      expect(draftRepository.deleteCallCount, 0);
    },
  );

  test(
    'unexpected validation error mengekalkan draft dan menggunakan fallback',
    () async {
      final originalDraft = _createDraft();

      final draftRepository = _RecoveryDraftRepository(
        storedDraft: originalDraft,
      );

      final quizRepository = _RecoveryQuizRepository(
        validation: _createCompatibleValidation(),
        validationError: StateError('Unexpected validation failure.'),
      );

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await expectLater(
        controller.loadAvailableDraft(),
        throwsA(
          isA<QuizDraftFailure>().having(
            (error) => error.message,
            'message',
            'Sesi kuiz tersimpan tidak dapat disahkan sekarang. '
                'Draft anda masih selamat pada peranti.',
          ),
        ),
      );

      expect(draftRepository.storedDraft, same(originalDraft));
      expect(draftRepository.deleteCallCount, 0);
    },
  );

  test(
    'restoreDraft incompatible mengembalikan false dan memadam draft',
    () async {
      final originalDraft = _createDraft();

      final draftRepository = _RecoveryDraftRepository(
        storedDraft: originalDraft,
      );

      final quizRepository = _RecoveryQuizRepository(
        validation: _createCompatibleValidation(questionCount: 3),
      );

      final container = _createContainer(
        quizRepository: quizRepository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      final restored = await controller.restoreDraft(originalDraft);

      expect(restored, isFalse);
      expect(quizRepository.validationCallCount, 1);
      expect(draftRepository.deleteCallCount, 1);
      expect(draftRepository.storedDraft, isNull);
    },
  );
}

ProviderContainer _createContainer({
  required _RecoveryQuizRepository quizRepository,
  required _RecoveryDraftRepository draftRepository,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(quizRepository),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('draft-recovery-test-user'),
    ],
  );
}

QuizDraft _createDraft() {
  final startedAt = DateTime.utc(2026, 8, 11, 10);

  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000003001',
    topicId: 'topic-draft-recovery',
    mode: QuizMode.practice,
    source: QuizSessionSource.standard,
    questionCount: 2,
    questions: _createQuestions(),
    currentQuestionIndex: 1,
    selectedAnswers: const {'recovery-q1': 0},
    flaggedQuestionIds: const {'recovery-q2'},
    startedAt: startedAt,
    sessionExpiresAt: startedAt.add(const Duration(hours: 2)),
    savedAt: startedAt.add(const Duration(minutes: 5)),
  );
}

QuizSessionValidation _createCompatibleValidation({
  QuizSessionSource source = QuizSessionSource.standard,
  int questionCount = 2,
}) {
  final serverTime = DateTime.utc(2026, 8, 11, 10, 10);

  return QuizSessionValidation(
    sessionId: '00000000-0000-0000-0000-000000003001',
    status: QuizSessionServerStatus.active,
    canResume: true,
    serverTime: serverTime,
    topicId: 'topic-draft-recovery',
    mode: QuizMode.practice,
    source: source,
    questionCount: questionCount,
    createdAt: DateTime.utc(2026, 8, 11, 10),
    expiresAt: DateTime.utc(2026, 8, 11, 12),
  );
}

List<QuizSessionQuestion> _createQuestions() {
  return [
    QuizSessionQuestion(
      id: 'recovery-q1',
      topicId: 'topic-draft-recovery',
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'recovery-q2',
      topicId: 'topic-draft-recovery',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
