import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_history_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_state.dart';

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  _FakeQuizHistoryRepository({required this.snapshot});

  QuizHistorySnapshot snapshot;

  final deletedAttemptIds = <String>[];

  int fetchCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    fetchCallCount++;

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

void main() {
  test('memuatkan dan memadam satu sejarah server', () async {
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

    var state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, hasLength(1));

    expect(state.totalAttempts, 1);

    expect(state.totalEarnedXp, 80);

    expect(state.averageScore, 100);

    final deleted = await controller.deleteAttempt(attempt.id);

    expect(deleted, isTrue);

    state = container.read(quizHistoryControllerProvider);

    expect(state.attempts, isEmpty);

    expect(state.totalAttempts, 0);

    expect(repository.deletedAttemptIds, [attempt.id]);
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

    final result = _createResult();

    await controller.recordServerAttempt(
      attemptId: '00000000-0000-0000-0000-000000000200',
      completedAt: DateTime(2026, 7, 16, 15),
      earnedXp: 80,
      result: result,
    );

    final state = container.read(quizHistoryControllerProvider);

    expect(state.status, QuizHistoryStatus.success);

    expect(state.attempts, hasLength(1));

    expect(state.totalAttempts, 1);

    expect(state.attempts.first.id, '00000000-0000-0000-0000-000000000200');
  });

  test('memadam semua sejarah server', () async {
    final repository = _FakeQuizHistoryRepository(
      snapshot: QuizHistorySnapshot(
        generatedAt: DateTime(2026, 7, 16, 12),
        totalCount: 1,
        attempts: [_createAttempt()],
      ),
    );

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
}
