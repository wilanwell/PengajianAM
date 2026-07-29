import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_analytics_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_performance.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/exceptions/topic_analytics_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/repositories/topic_analytics_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/pages/topic_analytics_page.dart';

class _SequenceTopicAnalyticsRepository implements TopicAnalyticsRepository {
  _SequenceTopicAnalyticsRepository({required List<Object> responses})
    : _responses = List<Object>.from(responses);

  final List<Object> _responses;

  int fetchCallCount = 0;

  @override
  Future<TopicAnalyticsSnapshot> fetchAnalytics() async {
    fetchCallCount++;

    if (_responses.isEmpty) {
      throw StateError('Tiada response ujian tersedia.');
    }

    final response = _responses.removeAt(0);

    if (response is TopicAnalyticsSnapshot) {
      return response;
    }

    if (response is TopicAnalyticsFailure) {
      throw response;
    }

    throw StateError('Jenis response ujian tidak sah.');
  }
}

void main() {
  testWidgets('memaparkan ringkasan dan prestasi mengikut topik', (
    tester,
  ) async {
    final repository = _SequenceTopicAnalyticsRepository(
      responses: [_sampleSnapshot()],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('Analitik Prestasi'), findsOneWidget);

    expect(find.text('Ringkasan Prestasi'), findsOneWidget);

    final topicsMetric = find.byKey(
      const Key('topic-analytics-summary-topics'),
    );

    final attemptsMetric = find.byKey(
      const Key('topic-analytics-summary-attempts'),
    );

    final averageMetric = find.byKey(
      const Key('topic-analytics-summary-average'),
    );

    expect(
      find.descendant(of: topicsMetric, matching: find.text('2')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: attemptsMetric, matching: find.text('5')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: averageMetric, matching: find.text('67%')),
      findsOneWidget,
    );

    expect(find.text('Topik Terkuat'), findsOneWidget);

    expect(find.text('Perlu Diberi Perhatian'), findsWidgets);

    expect(
      find.byKey(const Key('topic-analytics-performance-topic-1')),
      findsOneWidget,
    );

    expect(find.text('S1-01 · Topik Pertama'), findsOneWidget);

    expect(repository.fetchCallCount, 1);
  });

  testWidgets('memaparkan error awal dan membenarkan cuba semula', (
    tester,
  ) async {
    final repository = _SequenceTopicAnalyticsRepository(
      responses: [
        const TopicAnalyticsFailure('Analitik tidak dapat dicapai.'),
        _sampleSnapshot(),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('Analitik tidak dapat dicapai.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);

    await tester.tap(find.text('Cuba Semula'));

    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Prestasi'), findsOneWidget);

    expect(find.text('S1-01 · Topik Pertama'), findsOneWidget);

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('mengekalkan data lama apabila refresh gagal', (tester) async {
    final repository = _SequenceTopicAnalyticsRepository(
      responses: [
        _sampleSnapshot(),
        const TopicAnalyticsFailure('Sambungan Internet terputus.'),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('S1-01 · Topik Pertama'), findsOneWidget);

    final listView = find.byKey(
      const PageStorageKey<String>('topic-analytics-main-list'),
    );

    await tester.drag(listView, const Offset(0, 450));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('topic-analytics-stale-warning')),
      findsOneWidget,
    );

    expect(find.text('Data Terakhir Dipaparkan'), findsOneWidget);

    expect(find.text('Sambungan Internet terputus.'), findsOneWidget);

    expect(find.text('S1-01 · Topik Pertama'), findsOneWidget);

    expect(find.byKey(const Key('topic-analytics-summary')), findsOneWidget);

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('memaparkan empty state apabila belum ada rekod kuiz', (
    tester,
  ) async {
    final repository = _SequenceTopicAnalyticsRepository(
      responses: [
        TopicAnalyticsSnapshot(
          generatedAt: DateTime.utc(2026, 7, 29, 8),
          performances: const [],
        ),
      ],
    );

    await _pumpPage(tester, repository: repository);

    expect(find.byKey(const Key('topic-analytics-empty')), findsOneWidget);

    expect(find.text('Belum Ada Data Analitik'), findsOneWidget);

    expect(
      find.text(
        'Jawab dan hantar sekurang-kurangnya '
        'satu kuiz untuk melihat prestasi '
        'mengikut topik.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required TopicAnalyticsRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        topicAnalyticsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: TopicAnalyticsPage()),
    ),
  );

  await tester.pumpAndSettle();
}

TopicAnalyticsSnapshot _sampleSnapshot() {
  return TopicAnalyticsSnapshot(
    generatedAt: DateTime.utc(2026, 7, 29, 8),
    performances: const [
      TopicPerformance(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Topik Pertama',
        attemptCount: 2,
        totalQuestions: 10,
        totalCorrectAnswers: 9,
        bestScore: 100,
        totalEarnedXp: 160,
      ),
      TopicPerformance(
        topicId: 'topic-2',
        topicCode: 'S1-02',
        topicTitle: 'Topik Kedua',
        attemptCount: 3,
        totalQuestions: 20,
        totalCorrectAnswers: 11,
        bestScore: 70,
        totalEarnedXp: 120,
      ),
    ],
  );
}
