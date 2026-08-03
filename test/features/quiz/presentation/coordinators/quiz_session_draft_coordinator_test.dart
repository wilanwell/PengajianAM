import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_session_draft_coordinator.dart';

void main() {
  group('isValidationCompatible', () {
    test('menerima validation aktif yang sepadan', () {
      final draft = _createDraft();
      final validation = _createValidation();

      final result = QuizSessionDraftCoordinator.isValidationCompatible(
        draft: draft,
        validation: validation,
      );

      expect(result, isTrue);
    });

    test('menolak validation yang tidak aktif', () {
      final draft = _createDraft();

      final validations = [
        _createValidation(
          status: QuizSessionServerStatus.submitted,
          canResume: false,
        ),
        _createValidation(
          status: QuizSessionServerStatus.expired,
          canResume: false,
        ),
        _createValidation(
          status: QuizSessionServerStatus.notFound,
          canResume: false,
        ),
      ];

      for (final validation in validations) {
        expect(
          QuizSessionDraftCoordinator.isValidationCompatible(
            draft: draft,
            validation: validation,
          ),
          isFalse,
        );
      }
    });

    test('menolak metadata yang tidak sepadan', () {
      final draft = _createDraft();

      final validations = [
        _createValidation(topicId: 'topic-lain'),
        _createValidation(mode: QuizMode.exam),
        _createValidation(source: QuizSessionSource.mistakeReview),
        _createValidation(questionCount: 3),
      ];

      for (final validation in validations) {
        expect(
          QuizSessionDraftCoordinator.isValidationCompatible(
            draft: draft,
            validation: validation,
          ),
          isFalse,
        );
      }
    });
  });

  group('createSnapshot', () {
    test('membina snapshot Practice Mode yang sah', () {
      final startedAt = DateTime(2026, 8, 3, 10);

      final expiresAt = DateTime(2026, 8, 3, 11);

      final savedAt = DateTime(2026, 8, 3, 10, 5);

      final state = _createReadyState(sessionExpiresAt: expiresAt);

      final draft = QuizSessionDraftCoordinator.createSnapshot(
        state: state,
        startedAt: startedAt,
        examDeadlineAt: null,
        savedAt: savedAt,
      );

      expect(draft, isNotNull);

      expect(draft?.sessionId, 'session-1');

      expect(draft?.topicId, 'topic-1');

      expect(draft?.mode, QuizMode.practice);

      expect(draft?.source, QuizSessionSource.standard);

      expect(draft?.questionCount, 2);

      expect(draft?.currentQuestionIndex, 1);

      expect(draft?.selectedAnswers, const {'question-1': 0});

      expect(draft?.flaggedQuestionIds, const {'question-2'});

      expect(draft?.startedAt, startedAt);

      expect(draft?.sessionExpiresAt, expiresAt);

      expect(draft?.savedAt, savedAt);

      expect(draft?.examDeadlineAt, isNull);
    });

    test('membina snapshot Exam Mode dengan deadline', () {
      final startedAt = DateTime(2026, 8, 3, 10);

      final deadlineAt = DateTime(2026, 8, 3, 10, 30);

      final state = _createReadyState(
        mode: QuizMode.exam,
        sessionExpiresAt: DateTime(2026, 8, 3, 11),
      );

      final draft = QuizSessionDraftCoordinator.createSnapshot(
        state: state,
        startedAt: startedAt,
        examDeadlineAt: deadlineAt,
        savedAt: DateTime(2026, 8, 3, 10, 5),
      );

      expect(draft, isNotNull);

      expect(draft?.mode, QuizMode.exam);

      expect(draft?.examDeadlineAt, deadlineAt);
    });

    test('mengembalikan null apabila metadata tidak lengkap', () {
      final startedAt = DateTime(2026, 8, 3, 10);

      final savedAt = DateTime(2026, 8, 3, 10, 5);

      final validState = _createReadyState(
        sessionExpiresAt: DateTime(2026, 8, 3, 11),
      );

      expect(
        QuizSessionDraftCoordinator.createSnapshot(
          state: const QuizSessionState(),
          startedAt: startedAt,
          examDeadlineAt: null,
          savedAt: savedAt,
        ),
        isNull,
      );

      expect(
        QuizSessionDraftCoordinator.createSnapshot(
          state: validState.copyWith(clearSessionId: true),
          startedAt: startedAt,
          examDeadlineAt: null,
          savedAt: savedAt,
        ),
        isNull,
      );

      expect(
        QuizSessionDraftCoordinator.createSnapshot(
          state: validState.copyWith(clearSessionExpiresAt: true),
          startedAt: startedAt,
          examDeadlineAt: null,
          savedAt: savedAt,
        ),
        isNull,
      );

      expect(
        QuizSessionDraftCoordinator.createSnapshot(
          state: validState,
          startedAt: null,
          examDeadlineAt: null,
          savedAt: savedAt,
        ),
        isNull,
      );
    });

    test('mengembalikan null untuk kandungan draft tidak sah', () {
      final invalidState = _createReadyState(
        sessionExpiresAt: DateTime(2026, 8, 3, 11),
      ).copyWith(selectedAnswers: const {'unknown-question': 0});

      final draft = QuizSessionDraftCoordinator.createSnapshot(
        state: invalidState,
        startedAt: DateTime(2026, 8, 3, 10),
        examDeadlineAt: null,
        savedAt: DateTime(2026, 8, 3, 10, 5),
      );

      expect(draft, isNull);
    });

    test('mengembalikan null apabila masa simpan tidak sah', () {
      final state = _createReadyState(
        sessionExpiresAt: DateTime(2026, 8, 3, 11),
      );

      final draft = QuizSessionDraftCoordinator.createSnapshot(
        state: state,
        startedAt: DateTime(2026, 8, 3, 10),
        examDeadlineAt: null,
        savedAt: DateTime(2026, 8, 3, 9, 59),
      );

      expect(draft, isNull);
    });
  });
}

QuizDraft _createDraft() {
  final startedAt = DateTime(2026, 8, 3, 10);

  return QuizDraft(
    sessionId: 'session-1',
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questionCount: 2,
    questions: _createQuestions(),
    currentQuestionIndex: 1,
    selectedAnswers: const {'question-1': 0},
    flaggedQuestionIds: const {'question-2'},
    startedAt: startedAt,
    sessionExpiresAt: DateTime(2026, 8, 3, 11),
    savedAt: DateTime(2026, 8, 3, 10, 5),
  );
}

QuizSessionValidation _createValidation({
  QuizSessionServerStatus status = QuizSessionServerStatus.active,
  bool canResume = true,
  String? topicId = 'topic-1',
  QuizMode? mode = QuizMode.practice,
  QuizSessionSource? source = QuizSessionSource.standard,
  int? questionCount = 2,
}) {
  return QuizSessionValidation(
    sessionId: 'session-1',
    status: status,
    canResume: canResume,
    serverTime: DateTime(2026, 8, 3, 10, 5),
    topicId: topicId,
    mode: mode,
    source: source,
    questionCount: questionCount,
    createdAt: DateTime(2026, 8, 3, 10),
    expiresAt: DateTime(2026, 8, 3, 11),
  );
}

QuizSessionState _createReadyState({
  QuizMode mode = QuizMode.practice,
  QuizSessionSource source = QuizSessionSource.standard,
  required DateTime sessionExpiresAt,
}) {
  return QuizSessionState(
    status: QuizSessionStatus.ready,
    sessionId: 'session-1',
    topicId: 'topic-1',
    mode: mode,
    source: source,
    requestedQuestionCount: 2,
    questions: _createQuestions(),
    currentQuestionIndex: 1,
    selectedAnswers: const {'question-1': 0},
    flaggedQuestionIds: const {'question-2'},
    sessionExpiresAt: sessionExpiresAt,
  );
}

List<QuizSessionQuestion> _createQuestions() {
  return [
    QuizSessionQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
