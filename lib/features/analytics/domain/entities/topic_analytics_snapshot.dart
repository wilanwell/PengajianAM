import 'topic_performance.dart';

class TopicAnalyticsSnapshot {
  const TopicAnalyticsSnapshot({
    required this.generatedAt,
    required this.performances,
  });

  final DateTime generatedAt;
  final List<TopicPerformance> performances;
}
