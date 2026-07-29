import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_topic_analytics_repository.dart';
import '../../domain/exceptions/topic_analytics_failure.dart';
import '../../domain/repositories/topic_analytics_repository.dart';
import 'topic_analytics_state.dart';

final topicAnalyticsRepositoryProvider = Provider<TopicAnalyticsRepository>((
  ref,
) {
  return SupabaseTopicAnalyticsRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final topicAnalyticsControllerProvider =
    NotifierProvider<TopicAnalyticsController, TopicAnalyticsState>(
      TopicAnalyticsController.new,
    );

class TopicAnalyticsController extends Notifier<TopicAnalyticsState> {
  Future<void>? _activeRequest;

  int _requestGeneration = 0;

  TopicAnalyticsRepository get _repository {
    return ref.read(topicAnalyticsRepositoryProvider);
  }

  @override
  TopicAnalyticsState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _activeRequest = null;
    });

    return const TopicAnalyticsState();
  }

  Future<void> loadAnalytics({bool forceRefresh = false}) {
    final currentRequest = _activeRequest;

    if (!forceRefresh && currentRequest != null) {
      return currentRequest;
    }

    if (!forceRefresh && state.status == TopicAnalyticsStatus.success) {
      return Future<void>.value();
    }

    late final Future<void> request;

    request = _loadInternal().whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    });

    _activeRequest = request;

    return request;
  }

  Future<void> _loadInternal() async {
    final requestGeneration = ++_requestGeneration;

    final existingPerformances = state.performances;

    final existingLastUpdated = state.lastUpdated;

    state = TopicAnalyticsState(
      status: TopicAnalyticsStatus.loading,
      performances: existingPerformances,
      lastUpdated: existingLastUpdated,
    );

    late final TopicAnalyticsState resultState;

    try {
      final snapshot = await _repository.fetchAnalytics();

      resultState = TopicAnalyticsState(
        status: TopicAnalyticsStatus.success,
        performances: snapshot.performances,
        lastUpdated: snapshot.generatedAt,
      );
    } on TopicAnalyticsFailure catch (error) {
      resultState = TopicAnalyticsState(
        status: TopicAnalyticsStatus.failure,
        performances: existingPerformances,
        lastUpdated: existingLastUpdated,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = TopicAnalyticsState(
        status: TopicAnalyticsStatus.failure,
        performances: existingPerformances,
        lastUpdated: existingLastUpdated,
        errorMessage:
            'Analitik prestasi tidak dapat '
            'dimuatkan.',
      );
    }

    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }
  }

  Future<void> refreshAnalytics() {
    return loadAnalytics(forceRefresh: true);
  }

  void reset() {
    _requestGeneration++;
    _activeRequest = null;

    state = const TopicAnalyticsState();
  }
}
