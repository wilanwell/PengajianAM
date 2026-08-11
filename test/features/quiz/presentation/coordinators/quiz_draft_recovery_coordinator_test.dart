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
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_draft_recovery_coordinator.dart';

class _FakeQuizRepository implements QuizRepository {
  _FakeQuizRepository({required this.validation, this.validationError});

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
      'startQuiz tidak digunakan dalam recovery coordinator test.',
    );
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    throw UnsupportedError(
      'startMistakeReview tidak digunakan dalam recovery coordinator test.',
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
      'submitQuiz tidak digunakan dalam recovery coordinator test.',
    );
  }
}

class _FakeDraftRepository implements QuizDraftRepository {
  _FakeDraftRepository({this.storedDraft, this.loadError});

  QuizDraft? storedDraft;
  Object? loadError;

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
  group('QuizDraftRecoveryCoordinator.loadAvailableDraft', () {
    test(
      'mengembalikan null tanpa validation apabila tiada local draft',
      () async {
        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(),
        );

        final draftRepository = _FakeDraftRepository();

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        final result = await coordinator.loadAvailableDraft(
          ownerUserId: 'user-1',
        );

        expect(result, isNull);
        expect(draftRepository.loadCallCount, 1);
        expect(draftRepository.deleteCallCount, 0);
        expect(quizRepository.validationCallCount, 0);
      },
    );

    test('mengembalikan draft apabila validation compatible', () async {
      final draft = _createDraft();

      final quizRepository = _FakeQuizRepository(
        validation: _compatibleValidation(),
      );

      final draftRepository = _FakeDraftRepository(storedDraft: draft);

      final coordinator = QuizDraftRecoveryCoordinator(
        quizRepository,
        draftRepository,
      );

      final result = await coordinator.loadAvailableDraft(
        ownerUserId: 'user-1',
      );

      expect(result, same(draft));
      expect(quizRepository.validationCallCount, 1);
      expect(draftRepository.deleteCallCount, 0);
      expect(draftRepository.storedDraft, same(draft));
    });

    test(
      'QuizDraftFailure daripada local repository diteruskan tanpa diubah',
      () async {
        const originalFailure = QuizDraftFailure('Local draft rosak.');

        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(),
        );

        final draftRepository = _FakeDraftRepository(
          loadError: originalFailure,
        );

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        await expectLater(
          coordinator.loadAvailableDraft(ownerUserId: 'user-1'),
          throwsA(same(originalFailure)),
        );

        expect(quizRepository.validationCallCount, 0);
        expect(draftRepository.deleteCallCount, 0);
      },
    );

    test(
      'unexpected local read error dipetakan kepada QuizDraftFailure',
      () async {
        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(),
        );

        final draftRepository = _FakeDraftRepository(
          loadError: StateError('Storage gagal.'),
        );

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        await expectLater(
          coordinator.loadAvailableDraft(ownerUserId: 'user-1'),
          throwsA(
            isA<QuizDraftFailure>().having(
              (error) => error.message,
              'message',
              'Draft kuiz tidak dapat dibaca daripada peranti.',
            ),
          ),
        );

        expect(quizRepository.validationCallCount, 0);
        expect(draftRepository.deleteCallCount, 0);
      },
    );
  });

  group('QuizDraftRecoveryCoordinator.validateResumableDraft', () {
    test('mengembalikan validation apabila draft compatible', () async {
      final draft = _createDraft();

      final validation = _compatibleValidation();

      final quizRepository = _FakeQuizRepository(validation: validation);

      final draftRepository = _FakeDraftRepository(storedDraft: draft);

      final coordinator = QuizDraftRecoveryCoordinator(
        quizRepository,
        draftRepository,
      );

      final result = await coordinator.validateResumableDraft(
        ownerUserId: 'user-1',
        draft: draft,
      );

      expect(result, same(validation));
      expect(quizRepository.validationCallCount, 1);
      expect(draftRepository.deleteCallCount, 0);
      expect(draftRepository.storedDraft, same(draft));
    });

    test(
      'memadam draft dan mengembalikan null apabila validation incompatible',
      () async {
        final draft = _createDraft();

        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(questionCount: 3),
        );

        final draftRepository = _FakeDraftRepository(storedDraft: draft);

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        final result = await coordinator.validateResumableDraft(
          ownerUserId: 'user-1',
          draft: draft,
        );

        expect(result, isNull);
        expect(quizRepository.validationCallCount, 1);
        expect(draftRepository.deleteCallCount, 1);
        expect(draftRepository.storedDraft, isNull);
      },
    );

    test(
      'QuizFailure validation mengekalkan draft dan mesej asal server',
      () async {
        final draft = _createDraft();

        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(),
          validationError: const QuizFailure('Tiada sambungan Internet.'),
        );

        final draftRepository = _FakeDraftRepository(storedDraft: draft);

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        await expectLater(
          coordinator.validateResumableDraft(
            ownerUserId: 'user-1',
            draft: draft,
          ),
          throwsA(
            isA<QuizDraftFailure>().having(
              (error) => error.message,
              'message',
              'Tiada sambungan Internet. '
                  'Sesi tersimpan anda masih selamat pada peranti.',
            ),
          ),
        );

        expect(draftRepository.deleteCallCount, 0);
        expect(draftRepository.storedDraft, same(draft));
      },
    );

    test(
      'unexpected validation error mengekalkan draft dan menggunakan fallback',
      () async {
        final draft = _createDraft();

        final quizRepository = _FakeQuizRepository(
          validation: _compatibleValidation(),
          validationError: StateError('Unexpected validation failure.'),
        );

        final draftRepository = _FakeDraftRepository(storedDraft: draft);

        final coordinator = QuizDraftRecoveryCoordinator(
          quizRepository,
          draftRepository,
        );

        await expectLater(
          coordinator.validateResumableDraft(
            ownerUserId: 'user-1',
            draft: draft,
          ),
          throwsA(
            isA<QuizDraftFailure>().having(
              (error) => error.message,
              'message',
              'Sesi kuiz tersimpan tidak dapat disahkan sekarang. '
                  'Draft anda masih selamat pada peranti.',
            ),
          ),
        );

        expect(draftRepository.deleteCallCount, 0);
        expect(draftRepository.storedDraft, same(draft));
      },
    );
  });
}

QuizDraft _createDraft() {
  final startedAt = DateTime.utc(2026, 8, 11, 10);

  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000004001',
    topicId: 'topic-draft-recovery',
    mode: QuizMode.practice,
    source: QuizSessionSource.standard,
    questionCount: 2,
    questions: _questions(),
    currentQuestionIndex: 1,
    selectedAnswers: const {'recovery-unit-q1': 0},
    flaggedQuestionIds: const {'recovery-unit-q2'},
    startedAt: startedAt,
    sessionExpiresAt: startedAt.add(const Duration(hours: 2)),
    savedAt: startedAt.add(const Duration(minutes: 5)),
  );
}

QuizSessionValidation _compatibleValidation({int questionCount = 2}) {
  final serverTime = DateTime.utc(2026, 8, 11, 10, 10);

  return QuizSessionValidation(
    sessionId: '00000000-0000-0000-0000-000000004001',
    status: QuizSessionServerStatus.active,
    canResume: true,
    serverTime: serverTime,
    topicId: 'topic-draft-recovery',
    mode: QuizMode.practice,
    source: QuizSessionSource.standard,
    questionCount: questionCount,
    createdAt: DateTime.utc(2026, 8, 11, 10),
    expiresAt: DateTime.utc(2026, 8, 11, 12),
  );
}

List<QuizSessionQuestion> _questions() {
  return [
    QuizSessionQuestion(
      id: 'recovery-unit-q1',
      topicId: 'topic-draft-recovery',
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'recovery-unit-q2',
      topicId: 'topic-draft-recovery',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
