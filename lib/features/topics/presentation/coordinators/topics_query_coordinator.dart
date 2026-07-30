import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/topics_controller.dart';
import '../controllers/topics_state.dart';

typedef TopicsSearchChangedAction = void Function(String value);

typedef TopicsClearSearchAction = void Function();

typedef TopicsFilterChangedAction = void Function(TopicProgressFilter filter);

final topicsQueryCoordinatorProvider = Provider<TopicsQueryCoordinator>((ref) {
  return TopicsQueryCoordinator(
    searchChangedAction: (value) {
      ref.read(topicsControllerProvider.notifier).searchChanged(value);
    },
    clearSearchAction: () {
      ref.read(topicsControllerProvider.notifier).clearSearch();
    },
    filterChangedAction: (filter) {
      ref.read(topicsControllerProvider.notifier).filterChanged(filter);
    },
  );
});

class TopicsQueryCoordinator {
  const TopicsQueryCoordinator({
    required this.searchChangedAction,
    required this.clearSearchAction,
    required this.filterChangedAction,
  });

  final TopicsSearchChangedAction searchChangedAction;

  final TopicsClearSearchAction clearSearchAction;

  final TopicsFilterChangedAction filterChangedAction;

  void updateSearch(String value) {
    searchChangedAction(value);
  }

  void clearSearch() {
    clearSearchAction();
  }

  void selectFilter(TopicProgressFilter filter) {
    filterChangedAction(filter);
  }
}
