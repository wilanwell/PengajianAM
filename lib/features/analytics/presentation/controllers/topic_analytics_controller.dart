import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_topic_analytics_repository.dart';
import '../../domain/exceptions/topic_analytics_failure.dart';
import '../../domain/repositories/topic_analytics_repository.dart';
import 'topic_analytics_state.dart';

final topicAnalyticsRepositoryProvider = Provider<TopicAnalyticsRepository>((
  ref,
) {
  return SupabaseTopicAnalyticsRepository(ref.read(supabaseClientProvider));
});

final topicAnalyticsControllerProvider =
    NotifierProvider<TopicAnalyticsController, TopicAnalyticsState>(
      TopicAnalyticsController.new,
    );

class TopicAnalyticsController extends Notifier<TopicAnalyticsState> {
  TopicAnalyticsRepository get _repository {
    return ref.read(topicAnalyticsRepositoryProvider);
  }

  @override
  TopicAnalyticsState build() {
    return const TopicAnalyticsState();
  }

  Future<void> loadAnalytics({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == TopicAnalyticsStatus.loading ||
            state.status == TopicAnalyticsStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: TopicAnalyticsStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final snapshot = await _repository.fetchAnalytics();

      state = TopicAnalyticsState(
        status: TopicAnalyticsStatus.success,
        performances: snapshot.performances,
        lastUpdated: snapshot.generatedAt,
      );
    } on TopicAnalyticsFailure catch (error) {
      state = TopicAnalyticsState(
        status: TopicAnalyticsStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = const TopicAnalyticsState(
        status: TopicAnalyticsStatus.failure,
        errorMessage: 'Analitik prestasi tidak dapat dimuatkan.',
      );
    }
  }

  Future<void> refreshAnalytics() {
    return loadAnalytics(forceRefresh: true);
  }

  void reset() {
    state = const TopicAnalyticsState();
  }
}
