import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_draft_persistence_coordinator.dart';

class _ControlledQuizDraftRepository implements QuizDraftRepository {
  final List<String> events = [];
  final List<String> savedOwnerIds = [];
  final List<QuizDraft> savedDrafts = [];

  int loadCallCount = 0;
  int saveCallCount = 0;
  int failedSaveCount = 0;
  int deleteCallCount = 0;

  bool failNextSave = false;
  bool failNextDelete = false;

  bool _shouldBlockNextSave = false;

  Completer<void>? _blockedSaveStarted;
  Completer<void>? _blockedSaveRelease;

  void blockNextSave() {
    if (_shouldBlockNextSave) {
      throw StateError('Satu operasi save sudah ditetapkan untuk disekat.');
    }

    _shouldBlockNextSave = true;
    _blockedSaveStarted = Completer<void>();
    _blockedSaveRelease = Completer<void>();
  }

  Future<void> waitForBlockedSaveToStart() {
    final completer = _blockedSaveStarted;

    if (completer == null) {
      throw StateError('Tiada operasi save ditetapkan untuk disekat.');
    }

    return completer.future;
  }

  void releaseBlockedSave() {
    final completer = _blockedSaveRelease;

    if (completer == null) {
      throw StateError('Tiada operasi save sedang disekat.');
    }

    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    loadCallCount++;

    return null;
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    final callNumber = ++saveCallCount;

    events.add('save-$callNumber-start');

    if (_shouldBlockNextSave) {
      _shouldBlockNextSave = false;

      final startedCompleter = _blockedSaveStarted;

      final releaseCompleter = _blockedSaveRelease;

      if (startedCompleter == null || releaseCompleter == null) {
        throw StateError('Blocked save completers tidak tersedia.');
      }

      if (!startedCompleter.isCompleted) {
        startedCompleter.complete();
      }

      await releaseCompleter.future;
    }

    if (failNextSave) {
      failNextSave = false;
      failedSaveCount++;

      events.add('save-$callNumber-failed');

      throw StateError('Kegagalan save untuk tujuan test.');
    }

    savedOwnerIds.add(ownerUserId);
    savedDrafts.add(draft);

    events.add('save-$callNumber-end');
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    final callNumber = ++deleteCallCount;

    events.add('delete-$callNumber-start');

    if (failNextDelete) {
      failNextDelete = false;

      events.add('delete-$callNumber-failed');

      throw StateError('Kegagalan delete untuk tujuan test.');
    }

    events.add('delete-$callNumber-end');
  }
}

void main() {
  test('queueSave melaksanakan operasi secara bersiri', () async {
    final repository = _ControlledQuizDraftRepository();

    final coordinator = QuizDraftPersistenceCoordinator(repository);

    final firstDraft = _createDraft(sessionId: 'session-1');

    final secondDraft = _createDraft(sessionId: 'session-2');

    repository.blockNextSave();

    coordinator.queueSave(ownerUserId: 'owner-1', draft: firstDraft);

    await repository.waitForBlockedSaveToStart();

    coordinator.queueSave(ownerUserId: 'owner-2', draft: secondDraft);

    await Future<void>.delayed(Duration.zero);

    expect(repository.saveCallCount, 1);

    expect(repository.events, isNot(contains('save-2-start')));

    repository.releaseBlockedSave();

    await coordinator.waitForPendingOperations();

    expect(repository.saveCallCount, 2);

    expect(repository.savedOwnerIds, const ['owner-1', 'owner-2']);

    expect(repository.savedDrafts.length, 2);

    expect(repository.savedDrafts[0], same(firstDraft));

    expect(repository.savedDrafts[1], same(secondDraft));

    final firstEndIndex = repository.events.indexOf('save-1-end');

    final secondStartIndex = repository.events.indexOf('save-2-start');

    expect(firstEndIndex, greaterThanOrEqualTo(0));

    expect(secondStartIndex, greaterThan(firstEndIndex));
  });

  test('queue diteruskan selepas satu save gagal', () async {
    final repository = _ControlledQuizDraftRepository()..failNextSave = true;

    final coordinator = QuizDraftPersistenceCoordinator(repository);

    final firstDraft = _createDraft(sessionId: 'session-failed');

    final secondDraft = _createDraft(sessionId: 'session-success');

    coordinator.queueSave(ownerUserId: 'owner-1', draft: firstDraft);

    coordinator.queueSave(ownerUserId: 'owner-2', draft: secondDraft);

    await expectLater(coordinator.waitForPendingOperations(), completes);

    expect(repository.saveCallCount, 2);

    expect(repository.failedSaveCount, 1);

    expect(repository.events, contains('save-1-failed'));

    expect(repository.events, contains('save-2-end'));

    expect(repository.savedOwnerIds, const ['owner-2']);

    expect(repository.savedDrafts.length, 1);

    expect(repository.savedDrafts.single, same(secondDraft));
  });

  test('deleteSafely menunggu save dalam queue', () async {
    final repository = _ControlledQuizDraftRepository();

    final coordinator = QuizDraftPersistenceCoordinator(repository);

    repository.blockNextSave();

    coordinator.queueSave(
      ownerUserId: 'owner-1',
      draft: _createDraft(sessionId: 'session-1'),
    );

    await repository.waitForBlockedSaveToStart();

    final deleteFuture = coordinator.deleteSafely(ownerUserId: 'owner-1');

    await Future<void>.delayed(Duration.zero);

    expect(repository.deleteCallCount, 0);

    repository.releaseBlockedSave();

    await deleteFuture;

    expect(repository.deleteCallCount, 1);

    final saveEndIndex = repository.events.indexOf('save-1-end');

    final deleteStartIndex = repository.events.indexOf('delete-1-start');

    expect(saveEndIndex, greaterThanOrEqualTo(0));

    expect(deleteStartIndex, greaterThan(saveEndIndex));
  });

  test('saveSafely dan deleteSafely menyerap kegagalan repository', () async {
    final repository = _ControlledQuizDraftRepository()
      ..failNextSave = true
      ..failNextDelete = true;

    final coordinator = QuizDraftPersistenceCoordinator(repository);

    await expectLater(
      coordinator.saveSafely(
        ownerUserId: 'owner-1',
        draft: _createDraft(sessionId: 'session-1'),
      ),
      completes,
    );

    await expectLater(
      coordinator.deleteSafely(ownerUserId: 'owner-1'),
      completes,
    );

    expect(repository.saveCallCount, 1);

    expect(repository.failedSaveCount, 1);

    expect(repository.deleteCallCount, 1);

    expect(repository.events, contains('delete-1-failed'));
  });

  test('input null tidak memanggil repository', () async {
    final repository = _ControlledQuizDraftRepository();

    final coordinator = QuizDraftPersistenceCoordinator(repository);

    final draft = _createDraft(sessionId: 'session-1');

    await coordinator.saveSafely(ownerUserId: null, draft: draft);

    await coordinator.saveSafely(ownerUserId: 'owner-1', draft: null);

    coordinator.queueSave(ownerUserId: null, draft: draft);

    coordinator.queueSave(ownerUserId: 'owner-1', draft: null);

    await coordinator.deleteSafely(ownerUserId: null);

    await coordinator.waitForPendingOperations();

    expect(repository.loadCallCount, 0);

    expect(repository.saveCallCount, 0);

    expect(repository.deleteCallCount, 0);

    expect(repository.events, isEmpty);
  });
}

QuizDraft _createDraft({required String sessionId}) {
  final startedAt = DateTime(2026, 8, 4, 10);

  return QuizDraft(
    sessionId: sessionId,
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questionCount: 1,
    questions: [
      QuizSessionQuestion(
        id: 'question-1',
        topicId: 'topic-1',
        questionText: 'Soalan pertama',
        options: ['Pilihan A', 'Pilihan B'],
        questionOrder: 1,
      ),
    ],
    currentQuestionIndex: 0,
    selectedAnswers: const {'question-1': 0},
    flaggedQuestionIds: const {},
    startedAt: startedAt,
    sessionExpiresAt: DateTime(2026, 8, 4, 11),
    savedAt: DateTime(2026, 8, 4, 10, 5),
  );
}
