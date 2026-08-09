import 'dart:async';

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

class _QueueQuizRepository implements QuizRepository {
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
    ];

    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000200',
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
    throw UnsupportedError('Validation tidak digunakan dalam queue test.');
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required QuizSessionSource sessionSource,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) {
    throw UnsupportedError('Submission tidak digunakan dalam queue test.');
  }
}

class _ControlledDraftRepository implements QuizDraftRepository {
  QuizDraft? storedDraft;

  final List<QuizDraft> savedDrafts = [];
  final List<String> events = [];

  int loadCallCount = 0;
  int saveCallCount = 0;
  int failedSaveCount = 0;
  int deleteCallCount = 0;

  String? lastOwnerUserId;

  bool failNextSave = false;
  bool _shouldBlockNextSave = false;

  late Completer<void> _blockedSaveStarted;
  late Completer<void> _blockedSaveRelease;

  void blockNextSave() {
    if (_shouldBlockNextSave) {
      throw StateError('Satu operasi save sudah ditetapkan untuk disekat.');
    }

    _shouldBlockNextSave = true;
    _blockedSaveStarted = Completer<void>();
    _blockedSaveRelease = Completer<void>();
  }

  Future<void> waitForBlockedSaveToStart() {
    return _blockedSaveStarted.future;
  }

  void releaseBlockedSave() {
    if (!_blockedSaveRelease.isCompleted) {
      _blockedSaveRelease.complete();
    }
  }

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
    final callNumber = ++saveCallCount;

    lastOwnerUserId = ownerUserId;
    events.add('save-$callNumber-start');

    if (failNextSave) {
      failNextSave = false;
      failedSaveCount++;

      events.add('save-$callNumber-failed');

      throw StateError('Kegagalan autosave untuk tujuan test.');
    }

    if (_shouldBlockNextSave) {
      _shouldBlockNextSave = false;

      if (!_blockedSaveStarted.isCompleted) {
        _blockedSaveStarted.complete();
      }

      await _blockedSaveRelease.future;
    }

    storedDraft = draft;
    savedDrafts.add(draft);

    events.add('save-$callNumber-end');
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    final callNumber = ++deleteCallCount;

    lastOwnerUserId = ownerUserId;
    events.add('delete-$callNumber-start');

    storedDraft = null;

    events.add('delete-$callNumber-end');
  }
}

void main() {
  test('discardDraft menunggu autosave sebelum memadam draft', () async {
    final draftRepository = _ControlledDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-01',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    final baselineSaveCount = draftRepository.saveCallCount;

    final baselineDeleteCount = draftRepository.deleteCallCount;

    draftRepository.blockNextSave();

    controller.selectAnswer(0);

    await draftRepository.waitForBlockedSaveToStart();

    final discardFuture = controller.discardDraft();

    await Future<void>.delayed(Duration.zero);

    expect(draftRepository.deleteCallCount, baselineDeleteCount);

    expect(
      container.read(quizSessionControllerProvider).status,
      QuizSessionStatus.ready,
    );

    draftRepository.releaseBlockedSave();

    await discardFuture;

    expect(draftRepository.deleteCallCount, baselineDeleteCount + 1);

    expect(draftRepository.storedDraft, isNull);

    expect(
      container.read(quizSessionControllerProvider).status,
      QuizSessionStatus.initial,
    );

    final saveEndIndex = draftRepository.events.indexOf(
      'save-${baselineSaveCount + 1}-end',
    );

    final deleteStartIndex = draftRepository.events.indexOf(
      'delete-${baselineDeleteCount + 1}-start',
    );

    expect(saveEndIndex, greaterThanOrEqualTo(0));
    expect(deleteStartIndex, greaterThan(saveEndIndex));
  });

  test('autosave dalam queue dilaksanakan secara bersiri', () async {
    final draftRepository = _ControlledDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    final baselineSaveCount = draftRepository.saveCallCount;

    final firstQueuedSave = baselineSaveCount + 1;

    final secondQueuedSave = baselineSaveCount + 2;

    draftRepository.blockNextSave();

    controller.selectAnswer(1);

    await draftRepository.waitForBlockedSaveToStart();

    controller.nextQuestion();

    await Future<void>.delayed(Duration.zero);

    expect(draftRepository.saveCallCount, firstQueuedSave);

    expect(
      draftRepository.events,
      isNot(contains('save-$secondQueuedSave-start')),
    );

    draftRepository.releaseBlockedSave();

    await controller.preserveDraftAndReset();

    final firstSaveEndIndex = draftRepository.events.indexOf(
      'save-$firstQueuedSave-end',
    );

    final secondSaveStartIndex = draftRepository.events.indexOf(
      'save-$secondQueuedSave-start',
    );

    expect(firstSaveEndIndex, greaterThanOrEqualTo(0));

    expect(secondSaveStartIndex, greaterThan(firstSaveEndIndex));

    expect(draftRepository.saveCallCount, baselineSaveCount + 3);

    expect(draftRepository.storedDraft?.currentQuestionIndex, 1);

    expect(draftRepository.storedDraft?.selectedAnswers, const {
      'question-1': 1,
    });
  });

  test('kegagalan satu autosave tidak memutuskan queue', () async {
    final draftRepository = _ControlledDraftRepository();

    final container = _createContainer(draftRepository: draftRepository);

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-03',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    final baselineSaveCount = draftRepository.saveCallCount;

    final failedSaveNumber = baselineSaveCount + 1;

    final nextSaveNumber = baselineSaveCount + 2;

    draftRepository.failNextSave = true;

    controller.selectAnswer(1);
    controller.nextQuestion();

    await controller.preserveDraftAndReset();

    expect(draftRepository.failedSaveCount, 1);

    expect(draftRepository.events, contains('save-$failedSaveNumber-failed'));

    expect(draftRepository.events, contains('save-$nextSaveNumber-end'));

    expect(draftRepository.saveCallCount, baselineSaveCount + 3);

    expect(draftRepository.storedDraft, isNotNull);

    expect(draftRepository.storedDraft?.currentQuestionIndex, 1);

    expect(draftRepository.storedDraft?.selectedAnswers, const {
      'question-1': 1,
    });

    expect(
      container.read(quizSessionControllerProvider).status,
      QuizSessionStatus.initial,
    );
  });
}

ProviderContainer _createContainer({
  required _ControlledDraftRepository draftRepository,
}) {
  return ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(_QueueQuizRepository()),
      quizDraftRepositoryProvider.overrideWithValue(draftRepository),
      quizDraftOwnerIdProvider.overrideWithValue('queue-test-user'),
    ],
  );
}
