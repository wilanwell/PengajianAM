import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../../quiz/presentation/controllers/quiz_history_controller.dart';
import '../../../quiz/presentation/controllers/quiz_session_controller.dart';
import '../../../quiz/presentation/controllers/quiz_setup_controller.dart';
import '../controllers/app_settings_controller.dart';

typedef SettingsAsyncAction = Future<void> Function();
typedef SettingsSyncAction = void Function();
typedef SettingsResetAction = Future<String?> Function();

final settingsDataResetCoordinatorProvider =
    Provider<SettingsDataResetCoordinator>((ref) {
      return SettingsDataResetCoordinator(
        clearLocalProgress: () {
          return ref
              .read(userProgressControllerProvider.notifier)
              .clearLocalProgress();
        },
        discardQuizDraft: () {
          return ref
              .read(quizSessionControllerProvider.notifier)
              .discardDraft();
        },
        resetQuizHistory: () {
          ref.read(quizHistoryControllerProvider.notifier).reset();
        },
        resetTopicAnalytics: () {
          ref.read(topicAnalyticsControllerProvider.notifier).reset();
        },
        resetQuizSetup: () {
          ref.read(quizSetupControllerProvider.notifier).reset();
        },
        resetHome: () {
          ref.read(homeControllerProvider.notifier).reset();
        },
        resetProfile: () {
          ref.read(profileControllerProvider.notifier).reset();
        },
        resetLeaderboard: () {
          ref.read(leaderboardControllerProvider.notifier).reset();
        },
        resetSettingsToDefaults: () {
          return ref
              .read(appSettingsControllerProvider.notifier)
              .resetToDefaults();
        },
        reloadHome: () {
          return ref
              .read(homeControllerProvider.notifier)
              .loadDashboard(forceRefresh: true);
        },
        reloadProfile: () {
          return ref
              .read(profileControllerProvider.notifier)
              .loadProfile(forceRefresh: true);
        },
        reloadLeaderboard: () {
          return ref
              .read(leaderboardControllerProvider.notifier)
              .loadLeaderboard(forceRefresh: true);
        },
      );
    });

class SettingsDataResetCoordinator {
  const SettingsDataResetCoordinator({
    required this.clearLocalProgress,
    required this.discardQuizDraft,
    required this.resetQuizHistory,
    required this.resetTopicAnalytics,
    required this.resetQuizSetup,
    required this.resetHome,
    required this.resetProfile,
    required this.resetLeaderboard,
    required this.resetSettingsToDefaults,
    required this.reloadHome,
    required this.reloadProfile,
    required this.reloadLeaderboard,
  });

  final SettingsAsyncAction clearLocalProgress;
  final SettingsAsyncAction discardQuizDraft;

  final SettingsSyncAction resetQuizHistory;
  final SettingsSyncAction resetTopicAnalytics;
  final SettingsSyncAction resetQuizSetup;
  final SettingsSyncAction resetHome;
  final SettingsSyncAction resetProfile;
  final SettingsSyncAction resetLeaderboard;

  final SettingsResetAction resetSettingsToDefaults;

  final SettingsAsyncAction reloadHome;
  final SettingsAsyncAction reloadProfile;
  final SettingsAsyncAction reloadLeaderboard;

  Future<String?> resetAllData() async {
    try {
      /*
       * RPC reset_my_learning_data() dipanggil melalui
       * UserProgressController. Operasi ini mereset XP,
       * progress, quiz attempts, sesi kuiz server dan
       * nama paparan.
       */
      await clearLocalProgress();

      /*
       * Padam draft pada peranti serta hentikan timer
       * dan state sesi kuiz semasa.
       */
      await discardQuizDraft();

      /*
       * Bersihkan semua cached presentation state
       * sebelum data terkini dimuatkan semula.
       */
      resetQuizHistory();
      resetTopicAnalytics();
      resetQuizSetup();
      resetHome();
      resetProfile();
      resetLeaderboard();

      final settingsError = await resetSettingsToDefaults();

      /*
       * Preference leaderboard tidak direset kerana
       * ia ialah pilihan privasi, bukan progress
       * pembelajaran.
       */
      await Future.wait<void>([
        reloadHome(),
        reloadProfile(),
        reloadLeaderboard(),
      ]);

      return settingsError;
    } catch (_) {
      return 'Sebahagian data tidak dapat '
          'direset. Semak sambungan Internet '
          'dan cuba semula.';
    }
  }
}
