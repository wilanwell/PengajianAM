import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_analytics_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/entities/topic_performance.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/domain/repositories/topic_analytics_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/analytics/presentation/controllers/topic_analytics_state.dart';

class _FakeTopicAnalyticsRepository implements TopicAnalyticsRepository {
  int fetchCallCount = 0;

  @override
  Future<TopicAnalyticsSnapshot> fetchAnalytics() async {
    fetchCallCount++;

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
}

void main() {
  test('memuatkan analitik prestasi daripada repository', () async {
    final repository = _FakeTopicAnalyticsRepository();

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

    final state = container.read(topicAnalyticsControllerProvider);

    expect(state.status, TopicAnalyticsStatus.success);

    expect(state.performances, hasLength(2));

    expect(state.totalAttempts, 2);

    expect(state.totalQuestions, 3);

    expect(state.totalCorrectAnswers, 2);

    expect(state.overallAverageScore, closeTo(66.67, 0.01));

    expect(state.strongestTopic?.topicTitle, 'Topik Pertama');

    expect(state.strongestTopic?.averageScore, 100);

    expect(state.weakestTopic?.topicTitle, 'Topik Kedua');

    expect(state.weakestTopic?.averageScore, 50);

    expect(state.lastUpdated, DateTime(2026, 7, 16, 12));

    expect(repository.fetchCallCount, 1);
  });
}
