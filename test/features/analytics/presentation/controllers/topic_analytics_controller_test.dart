import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_analytics_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_performance.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/exceptions/topic_analytics_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/repositories/topic_analytics_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_state.dart';

class _FakeTopicAnalyticsRepository implements TopicAnalyticsRepository {
  _FakeTopicAnalyticsRepository({required this.snapshot, this.failure});

  final TopicAnalyticsSnapshot snapshot;

  final TopicAnalyticsFailure? failure;

  int fetchCallCount = 0;

  @override
  Future<TopicAnalyticsSnapshot> fetchAnalytics() async {
    fetchCallCount++;

    final currentFailure = failure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return snapshot;
  }
}

class _CompleterTopicAnalyticsRepository implements TopicAnalyticsRepository {
  final Completer<TopicAnalyticsSnapshot> completer =
      Completer<TopicAnalyticsSnapshot>();

  int fetchCallCount = 0;

  @override
  Future<TopicAnalyticsSnapshot> fetchAnalytics() {
    fetchCallCount++;

    return completer.future;
  }
}

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
  test('memuatkan menyimpan cache dan menyegarkan analitik', () async {
    final repository = _FakeTopicAnalyticsRepository(
      snapshot: _sampleSnapshot(),
    );

    final container = ProviderContainer(
      overrides: [
        topicAnalyticsRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      topicAnalyticsControllerProvider.notifier,
    );

    await controller.loadAnalytics();

    var state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.success);

    expect(state.performances, hasLength(2));

    expect(state.totalAttempts, 2);

    expect(state.totalQuestions, 3);

    expect(state.totalCorrectAnswers, 2);

    expect(state.overallAverageScore, closeTo(66.67, 0.01));

    expect(state.strongestTopic?.topicTitle, 'Topik Pertama');

    expect(state.weakestTopic?.topicTitle, 'Topik Kedua');

    expect(state.lastUpdated, DateTime(2026, 7, 16, 12));

    expect(repository.fetchCallCount, 1);

    await controller.loadAnalytics();

    expect(repository.fetchCallCount, 1);

    await controller.refreshAnalytics();

    state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.success);

    expect(repository.fetchCallCount, 2);
  });

  test(
    'menggabungkan permintaan serentak kepada satu repository call',
    () async {
      final repository = _CompleterTopicAnalyticsRepository();

      final container = ProviderContainer(
        overrides: [
          topicAnalyticsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final controller = container.read(
        topicAnalyticsControllerProvider.notifier,
      );

      final firstRequest = controller.loadAnalytics();

      final secondRequest = controller.loadAnalytics();

      expect(identical(firstRequest, secondRequest), isTrue);

      expect(repository.fetchCallCount, 1);

      repository.completer.complete(_sampleSnapshot());

      await Future.wait([firstRequest, secondRequest]);

      expect(
        container.read(topicAnalyticsControllerProvider).status,
        TopicAnalyticsStatus.success,
      );
    },
  );

  test('memetakan TopicAnalyticsFailure kepada failure state', () async {
    final repository = _FakeTopicAnalyticsRepository(
      snapshot: _sampleSnapshot(),
      failure: const TopicAnalyticsFailure('Analitik tidak dapat dicapai.'),
    );

    final container = ProviderContainer(
      overrides: [
        topicAnalyticsRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    await container
        .read(topicAnalyticsControllerProvider.notifier)
        .loadAnalytics();

    final state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.failure);

    expect(state.performances, isEmpty);

    expect(state.lastUpdated, isNull);

    expect(state.errorMessage, 'Analitik tidak dapat dicapai.');
  });

  test('mengekalkan analitik lama apabila refresh gagal', () async {
    final snapshot = _sampleSnapshot();

    final repository = _SequenceTopicAnalyticsRepository(
      responses: [
        snapshot,
        const TopicAnalyticsFailure('Sambungan Internet terputus.'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        topicAnalyticsRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      topicAnalyticsControllerProvider.notifier,
    );

    await controller.loadAnalytics();

    var state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.success);

    expect(state.performances, same(snapshot.performances));

    expect(state.lastUpdated, snapshot.generatedAt);

    await controller.refreshAnalytics();

    state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.failure);

    expect(state.performances, same(snapshot.performances));

    expect(state.lastUpdated, snapshot.generatedAt);

    expect(state.errorMessage, 'Sambungan Internet terputus.');

    expect(repository.fetchCallCount, 2);
  });

  test('reset membuang cache dan state analitik', () async {
    final repository = _FakeTopicAnalyticsRepository(
      snapshot: _sampleSnapshot(),
    );

    final container = ProviderContainer(
      overrides: [
        topicAnalyticsRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      topicAnalyticsControllerProvider.notifier,
    );

    await controller.loadAnalytics();

    controller.reset();

    final state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.initial);

    expect(state.performances, isEmpty);

    expect(state.lastUpdated, isNull);

    expect(state.errorMessage, isNull);
  });
}

TopicAnalyticsSnapshot _sampleSnapshot() {
  return TopicAnalyticsSnapshot(
    generatedAt: DateTime(2026, 7, 16, 12),
    performances: const [
      TopicPerformance(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Topik Pertama',
        attemptCount: 1,
        totalQuestions: 1,
        totalCorrectAnswers: 1,
        bestScore: 100,
        totalEarnedXp: 80,
      ),
      TopicPerformance(
        topicId: 'topic-2',
        topicCode: 'S1-02',
        topicTitle: 'Topik Kedua',
        attemptCount: 1,
        totalQuestions: 2,
        totalCorrectAnswers: 1,
        bestScore: 50,
        totalEarnedXp: 30,
      ),
    ],
  );
}
