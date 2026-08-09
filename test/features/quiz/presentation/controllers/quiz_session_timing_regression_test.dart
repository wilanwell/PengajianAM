import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

class _TimingQuizRepository implements QuizRepository {
  _TimingQuizRepository({required this.session, this.validation});

  final QuizSession session;
  final QuizSessionValidation? validation;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    return session;
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    throw UnsupportedError('Mistake review tidak digunakan dalam timing test.');
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) async {
    final result = validation;

    if (result == null) {
      throw UnsupportedError(
        'Validation tidak dikonfigurasi untuk timing test.',
      );
    }

    return result;
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
      'Submission tidak sepatutnya berlaku dalam timing test.',
    );
  }
}

class _TimingDraftRepository implements QuizDraftRepository {
  QuizDraft? storedDraft;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    return storedDraft;
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    storedDraft = draft;
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    storedDraft = null;
  }
}

void main() {
  test('Exam session menggunakan server timing dan server deadline', () async {
    final createdAt = DateTime.utc(2026, 8, 9, 4, 0);

    final serverTime = DateTime.utc(2026, 8, 9, 4, 2);

    final examDeadlineAt = DateTime.utc(2026, 8, 9, 4, 7);

    final draftRepository = _TimingDraftRepository();

    final repository = _TimingQuizRepository(
      session: _createExamSession(
        createdAt: createdAt,
        serverTime: serverTime,
        expiresAt: examDeadlineAt,
        examDeadlineAt: examDeadlineAt,
      ),
    );

    final container = _createContainer(
      repository: repository,
      draftRepository: draftRepository,
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-timing',
      mode: QuizMode.exam,
      questionCount: 2,
    );

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.remainingSeconds, 300);

    expect(state.sessionExpiresAt, examDeadlineAt);

    expect(draftRepository.storedDraft, isNotNull);

    expect(draftRepository.storedDraft?.startedAt, createdAt);

    expect(draftRepository.storedDraft?.examDeadlineAt, examDeadlineAt);
  });

  test('restore Exam draft tidak boleh memanjangkan server expiry', () async {
    final serverTime = DateTime.utc(2026, 8, 9, 5, 0);

    final serverCreatedAt = DateTime.utc(2026, 8, 9, 4, 50);

    final serverExpiresAt = DateTime.utc(2026, 8, 9, 5, 4);

    final draftDeadline = DateTime.utc(2026, 8, 9, 5, 10);

    final draft = _createExamDraft(
      startedAt: DateTime.utc(2026, 8, 9, 4, 45),
      sessionExpiresAt: draftDeadline,
      examDeadlineAt: draftDeadline,
    );

    final validation = QuizSessionValidation(
      sessionId: draft.sessionId,
      status: QuizSessionServerStatus.active,
      canResume: true,
      serverTime: serverTime,
      topicId: draft.topicId,
      mode: draft.mode,
      source: draft.source,
      questionCount: draft.questionCount,
      createdAt: serverCreatedAt,
      expiresAt: serverExpiresAt,
    );

    final repository = _TimingQuizRepository(
      session: _unusedPracticeSession(),
      validation: validation,
    );

    final draftRepository = _TimingDraftRepository()..storedDraft = draft;

    final container = _createContainer(
      repository: repository,
      draftRepository: draftRepository,
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    final restored = await controller.restoreDraft(draft);

    expect(restored, isTrue);

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.remainingSeconds, 240);

    expect(state.sessionExpiresAt, serverExpiresAt);

    expect(state.mode, QuizMode.exam);
  });

  test(
    'restore Exam draft mengekalkan deadline draft yang lebih awal',
    () async {
      final serverTime = DateTime.utc(2026, 8, 9, 6, 0);

      final serverExpiresAt = DateTime.utc(2026, 8, 9, 6, 10);

      final earlierDraftDeadline = DateTime.utc(2026, 8, 9, 6, 3);

      final draft = _createExamDraft(
        startedAt: DateTime.utc(2026, 8, 9, 5, 50),
        sessionExpiresAt: serverExpiresAt,
        examDeadlineAt: earlierDraftDeadline,
      );

      final validation = QuizSessionValidation(
        sessionId: draft.sessionId,
        status: QuizSessionServerStatus.active,
        canResume: true,
        serverTime: serverTime,
        topicId: draft.topicId,
        mode: draft.mode,
        source: draft.source,
        questionCount: draft.questionCount,
        createdAt: DateTime.utc(2026, 8, 9, 5, 52),
        expiresAt: serverExpiresAt,
      );

      final repository = _TimingQuizRepository(
        session: _unusedPracticeSession(),
        validation: validation,
      );

      final draftRepository = _TimingDraftRepository()..storedDraft = draft;

      final container = _createContainer(
        repository: repository,
        draftRepository: draftRepository,
      );

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      final restored = await controller.restoreDraft(draft);

      expect(restored, isTrue);

      final state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.ready);

      expect(state.remainingSeconds, 180);

      expect(state.sessionExpiresAt, serverExpiresAt);
    },
  );
}

ProviderContainer _createContainer({
  required QuizRepository repository,
  required QuizDraftRepository draftRepository,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(repository),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('timing-test-user'),
    ],
  );
}

QuizSession _createExamSession({
  required DateTime createdAt,
  required DateTime serverTime,
  required DateTime expiresAt,
  required DateTime examDeadlineAt,
}) {
  return QuizSession(
    sessionId: '00000000-0000-0000-0000-000000000501',
    topicId: 'topic-timing',
    mode: QuizMode.exam,
    questionCount: 2,
    createdAt: createdAt,
    serverTime: serverTime,
    expiresAt: expiresAt,
    examDeadlineAt: examDeadlineAt,
    questions: _questions(),
  );
}

QuizDraft _createExamDraft({
  required DateTime startedAt,
  required DateTime sessionExpiresAt,
  required DateTime examDeadlineAt,
}) {
  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000000502',
    topicId: 'topic-timing',
    mode: QuizMode.exam,
    questionCount: 2,
    questions: _questions(),
    currentQuestionIndex: 0,
    selectedAnswers: const {},
    flaggedQuestionIds: const {},
    startedAt: startedAt,
    sessionExpiresAt: sessionExpiresAt,
    examDeadlineAt: examDeadlineAt,
    savedAt: startedAt.add(const Duration(minutes: 1)),
  );
}

QuizSession _unusedPracticeSession() {
  final now = DateTime.utc(2026, 8, 9, 1);

  return QuizSession(
    sessionId: '00000000-0000-0000-0000-000000000599',
    topicId: 'unused-topic',
    mode: QuizMode.practice,
    questionCount: 2,
    expiresAt: now.add(const Duration(hours: 1)),
    questions: _questions(topicId: 'unused-topic'),
  );
}

List<QuizSessionQuestion> _questions({String topicId = 'topic-timing'}) {
  return [
    QuizSessionQuestion(
      id: 'timing-q1',
      topicId: topicId,
      questionText: 'Soalan timing pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'timing-q2',
      topicId: topicId,
      questionText: 'Soalan timing kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
