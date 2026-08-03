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

class _InteractionQuizRepository implements QuizRepository {
  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    return _createSession(
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
    return _createSession(
      topicId: topicId,
      mode: QuizMode.practice,
      source: QuizSessionSource.mistakeReview,
    );
  }

  QuizSession _createSession({
    required String topicId,
    required QuizMode mode,
    required QuizSessionSource source,
  }) {
    final now = DateTime.now();

    final questions = [
      QuizSessionQuestion(
        id: 'question-1',
        topicId: topicId,
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 1,
      ),
      QuizSessionQuestion(
        id: 'question-2',
        topicId: topicId,
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 2,
      ),
      QuizSessionQuestion(
        id: 'question-3',
        topicId: topicId,
        questionText: 'Soalan ketiga',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 3,
      ),
    ];

    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000100',
      topicId: topicId,
      mode: mode,
      source: source,
      questionCount: questions.length,
      serverTime: now,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 1)),
      questions: questions,
    );
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) {
    throw UnsupportedError(
      'Validation tidak digunakan dalam interaction test.',
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
      'Submission tidak digunakan dalam interaction test.',
    );
  }
}

class _MemoryQuizDraftRepository implements QuizDraftRepository {
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

void main() {
  test('mengurus navigation, jawapan dan flag dengan selamat', () async {
    final draftRepository = _MemoryQuizDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-01',
      mode: QuizMode.practice,
      questionCount: 3,
    );

    var state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.currentQuestionIndex, 0);

    controller.previousQuestion();

    expect(
      container.read(quizSessionControllerProvider).currentQuestionIndex,
      0,
    );

    controller.goToQuestion(-1);
    controller.goToQuestion(99);

    expect(
      container.read(quizSessionControllerProvider).currentQuestionIndex,
      0,
    );

    controller.selectAnswer(-1);
    controller.selectAnswer(2);

    expect(
      container.read(quizSessionControllerProvider).selectedAnswers,
      isEmpty,
    );

    controller.selectAnswer(1);

    state = container.read(quizSessionControllerProvider);

    expect(state.selectedAnswers, const {'question-1': 1});

    controller.toggleFlagCurrentQuestion();

    state = container.read(quizSessionControllerProvider);

    expect(state.flaggedQuestionIds, const {'question-1'});

    controller.toggleFlagCurrentQuestion();

    expect(
      container.read(quizSessionControllerProvider).flaggedQuestionIds,
      isEmpty,
    );

    controller.nextQuestion();

    expect(
      container.read(quizSessionControllerProvider).currentQuestionIndex,
      1,
    );

    controller.previousQuestion();

    expect(
      container.read(quizSessionControllerProvider).currentQuestionIndex,
      0,
    );

    controller.goToQuestion(2);
    controller.nextQuestion();

    expect(
      container.read(quizSessionControllerProvider).currentQuestionIndex,
      2,
    );
  });

  test('preserveDraftAndReset menyimpan snapshot terakhir', () async {
    final draftRepository = _MemoryQuizDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questionCount: 3,
    );

    controller.selectAnswer(0);
    controller.nextQuestion();
    controller.toggleFlagCurrentQuestion();

    await controller.preserveDraftAndReset();

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.initial);

    expect(state.questions, isEmpty);

    final draft = draftRepository.storedDraft;

    expect(draft, isNotNull);

    expect(draft?.topicId, 'topic-s1-02');

    expect(draft?.currentQuestionIndex, 1);

    expect(draft?.selectedAnswers, const {'question-1': 0});

    expect(draft?.flaggedQuestionIds, const {'question-2'});

    expect(draftRepository.lastOwnerUserId, 'interaction-user');
  });

  test('discardDraft memadam draft dan mengosongkan sesi', () async {
    final draftRepository = _MemoryQuizDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-03',
      mode: QuizMode.practice,
      questionCount: 3,
    );

    expect(draftRepository.storedDraft, isNotNull);

    final deleteCountBeforeDiscard = draftRepository.deleteCallCount;

    await controller.discardDraft();

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.initial);

    expect(state.questions, isEmpty);

    expect(draftRepository.storedDraft, isNull);

    expect(draftRepository.deleteCallCount, deleteCountBeforeDiscard + 1);
  });

  test('reset mengosongkan state tanpa memadam draft tersimpan', () async {
    final draftRepository = _MemoryQuizDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-04',
      mode: QuizMode.practice,
      questionCount: 3,
    );

    final storedDraftBeforeReset = draftRepository.storedDraft;

    final deleteCountBeforeReset = draftRepository.deleteCallCount;

    expect(storedDraftBeforeReset, isNotNull);

    controller.reset();

    final state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.initial);

    expect(state.questions, isEmpty);

    expect(draftRepository.storedDraft, same(storedDraftBeforeReset));

    expect(draftRepository.deleteCallCount, deleteCountBeforeReset);
  });
}

ProviderContainer _createContainer({
  required _MemoryQuizDraftRepository draftRepository,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(_InteractionQuizRepository()),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('interaction-user'),
    ],
  );
}
