import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/topics_controller.dart';

typedef TopicsLoadAction = Future<void> Function(bool forceRefresh);

final topicsLoadCoordinatorProvider = Provider<TopicsLoadCoordinator>((ref) {
  return TopicsLoadCoordinator(
    loadTopicsAction: (forceRefresh) {
      final controller = ref.read(topicsControllerProvider.notifier);

      if (forceRefresh) {
        return controller.refreshTopics();
      }

      return controller.loadTopics();
    },
  );
});

class TopicsLoadCoordinator {
  const TopicsLoadCoordinator({required this.loadTopicsAction});

  final TopicsLoadAction loadTopicsAction;

  Future<void> loadInitial() {
    return loadTopicsAction(false);
  }

  Future<void> retryTopics() {
    return loadTopicsAction(true);
  }

  Future<void> refreshTopics() {
    return loadTopicsAction(true);
  }
}
