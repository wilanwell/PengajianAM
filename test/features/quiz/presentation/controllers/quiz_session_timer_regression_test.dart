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

class _TimerQuizRepository implements QuizRepository {
  _TimerQuizRepository({required this.remainingSeconds});

  final int remainingSeconds;

  int submitCallCount = 0;
  bool? lastAutoSubmitted;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    final serverTime = DateTime.now();

    final deadline = serverTime.add(Duration(seconds: remainingSeconds));

    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000701',
      topicId: topicId,
      mode: QuizMode.exam,
      source: QuizSessionSource.standard,
      questionCount: 2,
      createdAt: serverTime,
      serverTime: serverTime,
      expiresAt: deadline,
      examDeadlineAt: deadline,
      questions: _questions(topicId: topicId),
    );
  }

  @override
  Future<QuizSession> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    throw UnsupportedError('Mistake review tidak digunakan dalam timer test.');
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) {
    throw UnsupportedError('Validation tidak digunakan dalam timer test.');
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
    lastAutoSubmitted = autoSubmitted;

    throw const QuizFailure('Submission sengaja digagalkan untuk timer test.');
  }
}

class _TimerDraftRepository implements QuizDraftRepository {
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
  test('Exam countdown berkurang selepas satu saat', () async {
    final repository = _TimerQuizRepository(remainingSeconds: 3);

    final container = _createContainer(repository: repository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-timer',
      mode: QuizMode.exam,
      questionCount: 2,
    );

    final initialState = container.read(quizSessionControllerProvider);

    expect(initialState.status, QuizSessionStatus.ready);

    expect(initialState.remainingSeconds, 3);

    await Future<void>.delayed(const Duration(milliseconds: 1150));

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.remainingSeconds, 2);

    expect(repository.submitCallCount, 0);
  });

  test('timer expiry mencetuskan auto submission', () async {
    final repository = _TimerQuizRepository(remainingSeconds: 1);

    final container = _createContainer(repository: repository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-timer',
      mode: QuizMode.exam,
      questionCount: 2,
    );

    expect(container.read(quizSessionControllerProvider).remainingSeconds, 1);

    await Future<void>.delayed(const Duration(milliseconds: 1300));

    final state = container.read(quizSessionControllerProvider);

    expect(repository.submitCallCount, 1);

    expect(repository.lastAutoSubmitted, isTrue);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.remainingSeconds, 0);

    expect(
      state.errorMessage,
      'Submission sengaja digagalkan untuk timer test.',
    );
  });

  test('reset menghentikan countdown dan auto submission', () async {
    final repository = _TimerQuizRepository(remainingSeconds: 1);

    final container = _createContainer(repository: repository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-timer',
      mode: QuizMode.exam,
      questionCount: 2,
    );

    controller.reset();

    expect(
      container.read(quizSessionControllerProvider).status,
      QuizSessionStatus.initial,
    );

    await Future<void>.delayed(const Duration(milliseconds: 1300));

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.initial);

    expect(state.remainingSeconds, isNull);

    expect(repository.submitCallCount, 0);
  });

  test(
    'submission gagal memulakan semula timer jika masa masih berbaki',
    () async {
      final repository = _TimerQuizRepository(remainingSeconds: 3);

      final container = _createContainer(repository: repository);

      addTearDown(container.dispose);

      final controller = container.read(quizSessionControllerProvider.notifier);

      await controller.startQuiz(
        topicId: 'topic-timer',
        mode: QuizMode.exam,
        questionCount: 2,
      );

      await controller.submitQuiz();

      var state = container.read(quizSessionControllerProvider);

      expect(repository.submitCallCount, 1);

      expect(repository.lastAutoSubmitted, isFalse);

      expect(state.status, QuizSessionStatus.ready);

      expect(state.remainingSeconds, 3);

      await Future<void>.delayed(const Duration(milliseconds: 1150));

      state = container.read(quizSessionControllerProvider);

      expect(state.status, QuizSessionStatus.ready);

      expect(state.remainingSeconds, 2);

      expect(repository.submitCallCount, 1);
    },
  );
}

ProviderContainer _createContainer({required _TimerQuizRepository repository}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(repository),
      quizDraftRepositoryProvider.overrideWithValue(_TimerDraftRepository()),
      quizDraftOwnerIdProvider.overrideWithValue('timer-test-user'),
    ],
  );
}

List<QuizSessionQuestion> _questions({required String topicId}) {
  return [
    QuizSessionQuestion(
      id: 'timer-q1',
      topicId: topicId,
      questionText: 'Soalan timer pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'timer-q2',
      topicId: topicId,
      questionText: 'Soalan timer kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
