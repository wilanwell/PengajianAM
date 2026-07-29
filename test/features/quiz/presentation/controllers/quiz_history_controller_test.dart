import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_history_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/exceptions/quiz_history_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_state.dart';

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  _FakeQuizHistoryRepository({required this.snapshot, this.fetchFailure});

  QuizHistorySnapshot snapshot;

  final QuizHistoryFailure? fetchFailure;

  final List<String> deletedAttemptIds = <String>[];

  int fetchCallCount = 0;

  int clearCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    fetchCallCount++;

    final currentFailure = fetchFailure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return snapshot;
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {
    deletedAttemptIds.add(attemptId);

    final updatedAttempts = snapshot.attempts
        .where((attempt) {
          return attempt.id != attemptId;
        })
        .toList(growable: false);

    snapshot = QuizHistorySnapshot(
      generatedAt: DateTime(2026, 7, 16, 13),
      totalCount: snapshot.totalCount > 0 ? snapshot.totalCount - 1 : 0,
      attempts: List<QuizAttempt>.unmodifiable(updatedAttempts),
    );
  }

  @override
  Future<int> clearHistory() async {
    clearCallCount++;

    final deletedCount = snapshot.totalCount;

    snapshot = QuizHistorySnapshot(
      generatedAt: DateTime(2026, 7, 16, 14),
      totalCount: 0,
      attempts: const [],
    );

    return deletedCount;
  }
}

class _CompleterQuizHistoryRepository implements QuizHistoryRepository {
  final Completer<QuizHistorySnapshot> completer =
      Completer<QuizHistorySnapshot>();

  int fetchCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) {
    fetchCallCount++;

    return completer.future;
  }

  @override
  Future<void> deleteAttempt(String attemptId) {
    throw UnimplementedError();
  }

  @override
  Future<int> clearHistory() {
    throw UnimplementedError();
  }
}

class _SequenceQuizHistoryRepository implements QuizHistoryRepository {
  _SequenceQuizHistoryRepository({required List<Object> responses})
    : _responses = List<Object>.from(responses);

  final List<Object> _responses;

  int fetchCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    fetchCallCount++;

    if (_responses.isEmpty) {
      throw StateError('Tiada response ujian tersedia.');
    }

    final response = _responses.removeAt(0);

    if (response is QuizHistorySnapshot) {
      return response;
    }

    if (response is QuizHistoryFailure) {
      throw response;
    }

    throw StateError('Jenis response ujian tidak sah.');
  }

  @override
  Future<void> deleteAttempt(String attemptId) {
    throw UnimplementedError();
  }

  @override
  Future<int> clearHistory() {
    throw UnimplementedError();
  }
}

void main() {
  test('memuatkan menyimpan cache dan menyegarkan sejarah kuiz', () async {
    final repository = _FakeQuizHistoryRepository(snapshot: _sampleSnapshot());

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    var state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, hasLength(1));

    expect(state.totalAttempts, 1);

    expect(state.totalEarnedXp, 80);

    expect(state.averageScore, 100);

    expect(repository.fetchCallCount, 1);

    await controller.loadHistory();

    expect(repository.fetchCallCount, 1);

    await controller.refreshHistory();

    state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(repository.fetchCallCount, 2);
  });

  test(
    'menggabungkan permintaan serentak kepada satu repository call',
    () async {
      final repository = _CompleterQuizHistoryRepository();

      final container = ProviderContainer(
        overrides: [
          quizHistoryRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final controller = container.read(quizHistoryControllerProvider.notifier);

      final firstRequest = controller.loadHistory();

      final secondRequest = controller.loadHistory();

      expect(identical(firstRequest, secondRequest), isTrue);

      expect(repository.fetchCallCount, 1);

      repository.completer.complete(_sampleSnapshot());

      await Future.wait([firstRequest, secondRequest]);

      expect(
        container.read(quizHistoryControllerProvider).status,
        QuizHistoryStatus.success,
      );
    },
  );

  test('memetakan QuizHistoryFailure kepada failure state', () async {
    final repository = _FakeQuizHistoryRepository(
      snapshot: _sampleSnapshot(),
      fetchFailure: const QuizHistoryFailure(
        'Sejarah kuiz tidak dapat dicapai.',
      ),
    );

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(quizHistoryControllerProvider.notifier).loadHistory();

    final state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.failure);

    expect(state.attempts, isEmpty);

    expect(state.totalCount, 0);

    expect(state.lastUpdated, isNull);

    expect(state.errorMessage, 'Sejarah kuiz tidak dapat dicapai.');
  });

  test('mengekalkan sejarah lama apabila refresh gagal', () async {
    final snapshot = _sampleSnapshot();

    final repository = _SequenceQuizHistoryRepository(
      responses: [
        snapshot,
        const QuizHistoryFailure('Sambungan Internet terputus.'),
      ],
    );

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    var state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, same(snapshot.attempts));

    expect(state.totalCount, snapshot.totalCount);

    expect(state.lastUpdated, snapshot.generatedAt);

    await controller.refreshHistory();

    state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.failure);

    expect(state.attempts, same(snapshot.attempts));

    expect(state.totalCount, snapshot.totalCount);

    expect(state.lastUpdated, snapshot.generatedAt);

    expect(state.errorMessage, 'Sambungan Internet terputus.');

    expect(repository.fetchCallCount, 2);
  });

  test('menambah attempt server ke state semasa', () async {
    final repository = _FakeQuizHistoryRepository(
      snapshot: QuizHistorySnapshot(
        generatedAt: DateTime(2026, 7, 16, 12),
        totalCount: 0,
        attempts: const [],
      ),
    );

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    await controller.recordServerAttempt(
      attemptId: '00000000-0000-0000-0000-000000000200',
      completedAt: DateTime(2026, 7, 16, 15),
      earnedXp: 80,
      result: _createResult(),
    );

    final state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, hasLength(1));

    expect(state.totalAttempts, 1);

    expect(state.attempts.first.id, '00000000-0000-0000-0000-000000000200');
  });

  test(
    'response lama tidak menimpa attempt yang ditambah semasa loading',
    () async {
      final repository = _CompleterQuizHistoryRepository();

      final container = ProviderContainer(
        overrides: [
          quizHistoryRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final controller = container.read(quizHistoryControllerProvider.notifier);

      final pendingRequest = controller.loadHistory();

      await controller.recordServerAttempt(
        attemptId: '00000000-0000-0000-0000-000000000300',
        completedAt: DateTime(2026, 7, 16, 16),
        earnedXp: 80,
        result: _createResult(),
      );

      repository.completer.complete(_sampleSnapshot());

      await pendingRequest;

      final state = container.read(quizHistoryControllerProvider);

      expect(state.status, QuizHistoryStatus.success);

      expect(state.attempts, hasLength(1));

      expect(state.attempts.first.id, '00000000-0000-0000-0000-000000000300');
    },
  );

  test('memadam satu sejarah server', () async {
    final attempt = _createAttempt();

    final repository = _FakeQuizHistoryRepository(
      snapshot: QuizHistorySnapshot(
        generatedAt: DateTime(2026, 7, 16, 12),
        totalCount: 1,
        attempts: [attempt],
      ),
    );

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    final deleted = await controller.deleteAttempt(attempt.id);

    final state = container.read(quizHistoryControllerProvider);

    expect(deleted, isTrue);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, isEmpty);

    expect(state.totalAttempts, 0);

    expect(repository.deletedAttemptIds, [attempt.id]);
  });

  test('memadam semua sejarah server', () async {
    final repository = _FakeQuizHistoryRepository(snapshot: _sampleSnapshot());

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    final cleared = await controller.clearHistory();

    final state = container.read(quizHistoryControllerProvider);

    expect(cleared, isTrue);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, isEmpty);

    expect(state.totalAttempts, 0);

    expect(repository.clearCallCount, 1);
  });

  test('reset membuang cache sejarah kuiz', () async {
    final repository = _FakeQuizHistoryRepository(snapshot: _sampleSnapshot());

    final container = ProviderContainer(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizHistoryControllerProvider.notifier);

    await controller.loadHistory();

    controller.reset();

    final state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.initial);

    expect(state.attempts, isEmpty);

    expect(state.totalCount, 0);

    expect(state.lastUpdated, isNull);

    expect(state.errorMessage, isNull);
  });
}

QuizResult _createResult() {
  final question = QuizQuestion(
    id: 'q1',
    topicId: 'topic-s1-02',
    questionText: 'Apakah maksud negara berdaulat?',
    options: const ['Bebas mentadbir', 'Dikawal kuasa luar'],
    correctOptionIndex: 0,
    explanation: 'Negara berdaulat bebas mentadbir.',
  );

  return QuizResult(
    topicId: 'topic-s1-02',
    topicCode: 'S1-02',
    topicTitle: 'Negara Berdaulat',
    mode: QuizMode.practice,
    questions: [question],
    selectedAnswers: const {'q1': 0},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 80,
    elapsedTime: const Duration(seconds: 30),
    autoSubmitted: false,
  );
}

QuizAttempt _createAttempt() {
  return QuizAttempt(
    id: '00000000-0000-0000-0000-000000000100',
    completedAt: DateTime(2026, 7, 16, 12),
    earnedXp: 80,
    result: _createResult(),
  );
}

QuizHistorySnapshot _sampleSnapshot() {
  return QuizHistorySnapshot(
    generatedAt: DateTime(2026, 7, 16, 12),
    totalCount: 1,
    attempts: [_createAttempt()],
  );
}
