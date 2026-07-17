import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_topics_repository.dart';
import '../../domain/exceptions/topics_failure.dart';
import '../../domain/repositories/topics_repository.dart';
import 'topics_state.dart';

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  return SupabaseTopicsRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final topicsControllerProvider =
    NotifierProvider<TopicsController, TopicsState>(TopicsController.new);

class TopicsController extends Notifier<TopicsState> {
  TopicsRepository get _repository {
    return ref.read(topicsRepositoryProvider);
  }

  @override
  TopicsState build() {
    return const TopicsState();
  }

  Future<void> loadTopics({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == TopicsStatus.loading ||
            state.status == TopicsStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: TopicsStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final topics = await _repository.fetchTopics();

      state = TopicsState(status: TopicsStatus.success, topics: topics);
    } on TopicsFailure catch (error) {
      state = TopicsState(
        status: TopicsStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = const TopicsState(
        status: TopicsStatus.failure,
        errorMessage:
            'Senarai topik tidak dapat '
            'dimuatkan. Sila cuba semula.',
      );
    }
  }

  void searchChanged(String value) {
    state = state.copyWith(searchQuery: value, clearErrorMessage: true);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', clearErrorMessage: true);
  }

  void filterChanged(TopicProgressFilter filter) {
    state = state.copyWith(filter: filter, clearErrorMessage: true);
  }

  Future<void> refreshTopics() {
    return loadTopics(forceRefresh: true);
  }

  void reset() {
    state = const TopicsState();
  }
}
