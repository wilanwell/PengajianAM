import '../entities/topic_analytics_snapshot.dart';

abstract interface class TopicAnalyticsRepository {
  Future<TopicAnalyticsSnapshot> fetchAnalytics();
}
