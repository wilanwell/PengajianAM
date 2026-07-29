import 'package:flutter/material.dart';
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
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/pages/quiz_history_page.dart';

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
  testWidgets('memaparkan ringkasan dan rekod sejarah kuiz', (tester) async {
    final repository = _SequenceQuizHistoryRepository(
      responses: [_sampleSnapshot()],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('Sejarah Kuiz'), findsOneWidget);

    expect(find.byKey(const Key('quiz-history-summary')), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('quiz-history-summary-attempts')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('quiz-history-summary-average')),
        matching: find.text('100%'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('quiz-history-summary-xp')),
        matching: find.text('80'),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('quiz-history-attempt-attempt-1')),
      findsOneWidget,
    );

    expect(find.text('S1-02 · Negara Berdaulat'), findsOneWidget);

    expect(find.byKey(const Key('quiz-history-clear-button')), findsOneWidget);

    expect(repository.fetchCallCount, 1);
  });

  testWidgets('memaparkan error awal dan membenarkan cuba semula', (
    tester,
  ) async {
    final repository = _SequenceQuizHistoryRepository(
      responses: [
        const QuizHistoryFailure('Sejarah kuiz tidak dapat dicapai.'),
        _sampleSnapshot(),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('Sejarah kuiz tidak dapat dicapai.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);

    await tester.tap(find.text('Cuba Semula'));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-history-summary')), findsOneWidget);

    expect(find.text('S1-02 · Negara Berdaulat'), findsOneWidget);

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('mengekalkan sejarah lama apabila refresh gagal', (tester) async {
    final repository = _SequenceQuizHistoryRepository(
      responses: [
        _sampleSnapshot(),
        const QuizHistoryFailure('Sambungan Internet terputus.'),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('S1-02 · Negara Berdaulat'), findsOneWidget);

    final listView = find.byKey(
      const PageStorageKey<String>('quiz-history-main-list'),
    );

    await tester.drag(listView, const Offset(0, 450));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-history-stale-warning')), findsOneWidget);

    expect(find.text('Data Terakhir Dipaparkan'), findsOneWidget);

    expect(find.text('Sambungan Internet terputus.'), findsOneWidget);

    expect(find.text('S1-02 · Negara Berdaulat'), findsOneWidget);

    expect(find.byKey(const Key('quiz-history-clear-button')), findsOneWidget);

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('memaparkan empty state apabila belum ada sejarah', (
    tester,
  ) async {
    final repository = _SequenceQuizHistoryRepository(
      responses: [
        QuizHistorySnapshot(
          generatedAt: DateTime.utc(2026, 7, 29, 8),
          totalCount: 0,
          attempts: const [],
        ),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.byKey(const Key('quiz-history-empty')), findsOneWidget);

    expect(find.text('Belum Ada Sejarah Kuiz'), findsOneWidget);

    expect(
      find.text(
        'Keputusan kuiz yang dihantar akan '
        'dipaparkan di halaman ini.',
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('quiz-history-clear-button')), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required QuizHistoryRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [quizHistoryRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: QuizHistoryPage()),
    ),
  );

  await tester.pumpAndSettle();
}

QuizHistorySnapshot _sampleSnapshot() {
  return QuizHistorySnapshot(
    generatedAt: DateTime.utc(2026, 7, 29, 8),
    totalCount: 1,
    attempts: [_createAttempt()],
  );
}

QuizAttempt _createAttempt() {
  return QuizAttempt(
    id: 'attempt-1',
    completedAt: DateTime.utc(2026, 7, 29, 7),
    earnedXp: 80,
    result: _createResult(),
  );
}

QuizResult _createResult() {
  final question = QuizQuestion(
    id: 'question-1',
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
    selectedAnswers: const {'question-1': 0},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 80,
    elapsedTime: const Duration(seconds: 30),
    autoSubmitted: false,
  );
}
