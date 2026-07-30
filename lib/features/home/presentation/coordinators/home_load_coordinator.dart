import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/home_controller.dart';
import '../controllers/home_state.dart';

typedef HomeLoadAction = Future<void> Function(bool forceRefresh);

typedef HomeStatusReader = HomeStatus Function();

typedef HomeResetAction = void Function();

final homeLoadCoordinatorProvider = Provider<HomeLoadCoordinator>((ref) {
  return HomeLoadCoordinator(
    loadDashboardAction: (forceRefresh) {
      final controller = ref.read(homeControllerProvider.notifier);

      if (forceRefresh) {
        return controller.refreshDashboard();
      }

      return controller.loadDashboard();
    },
    readHomeStatus: () {
      return ref.read(homeControllerProvider).status;
    },
    resetHome: () {
      ref.read(homeControllerProvider.notifier).reset();
    },
  );
});

class HomeLoadCoordinator {
  const HomeLoadCoordinator({
    required this.loadDashboardAction,
    required this.readHomeStatus,
    required this.resetHome,
  });

  final HomeLoadAction loadDashboardAction;

  final HomeStatusReader readHomeStatus;

  final HomeResetAction resetHome;

  Future<void> loadInitial() {
    return loadDashboardAction(true);
  }

  Future<void> refreshDashboard() {
    return loadDashboardAction(true);
  }

  Future<void> retryDashboard() {
    return loadDashboardAction(true);
  }

  Future<void> synchronizeAfterProgressChange({
    required bool isLoggingOut,
  }) async {
    if (isLoggingOut) {
      return;
    }

    if (readHomeStatus() == HomeStatus.loading) {
      return;
    }

    resetHome();

    await loadDashboardAction(false);
  }

  Future<void> ensureLoadedAfterInvalidation({
    required bool isLoggingOut,
  }) async {
    if (isLoggingOut) {
      return;
    }

    if (readHomeStatus() != HomeStatus.initial) {
      return;
    }

    await loadDashboardAction(true);
  }
}
