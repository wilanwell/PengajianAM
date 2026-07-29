import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leaderboard/presentation/controllers/leaderboard_preference_controller.dart';
import '../controllers/app_settings_controller.dart';

typedef SettingsLoadAction = Future<void> Function(bool forceRefresh);

final settingsLoadCoordinatorProvider = Provider<SettingsLoadCoordinator>((
  ref,
) {
  return SettingsLoadCoordinator(
    loadSettings: (forceRefresh) {
      return ref
          .read(appSettingsControllerProvider.notifier)
          .loadSettings(forceRefresh: forceRefresh);
    },
    loadLeaderboardPreference: (forceRefresh) {
      return ref
          .read(leaderboardPreferenceControllerProvider.notifier)
          .loadPreference(forceRefresh: forceRefresh);
    },
  );
});

class SettingsLoadCoordinator {
  const SettingsLoadCoordinator({
    required this.loadSettings,
    required this.loadLeaderboardPreference,
  });

  final SettingsLoadAction loadSettings;

  final SettingsLoadAction loadLeaderboardPreference;

  Future<void> loadInitial() {
    return _loadAll(forceRefresh: false);
  }

  Future<void> refreshAll() {
    return _loadAll(forceRefresh: true);
  }

  Future<void> retrySettings() {
    return loadSettings(true);
  }

  Future<void> retryLeaderboardPreference() {
    return loadLeaderboardPreference(true);
  }

  Future<void> _loadAll({required bool forceRefresh}) async {
    await Future.wait<void>([
      loadSettings(forceRefresh),
      loadLeaderboardPreference(forceRefresh),
    ]);
  }
}
