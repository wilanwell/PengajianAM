import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/domain/entities/leaderboard_period.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_controller.dart';

typedef UpdateLeaderboardPreference = Future<String?> Function(bool optIn);

typedef ReadLeaderboardPeriod = LeaderboardPeriod Function();

typedef SettingsLeaderboardSyncAction = void Function();

typedef SettingsLeaderboardAsyncAction = Future<void> Function();

typedef ReloadLeaderboardPeriod =
    Future<void> Function(LeaderboardPeriod period);

final settingsLeaderboardParticipationCoordinatorProvider =
    Provider<SettingsLeaderboardParticipationCoordinator>((ref) {
      return SettingsLeaderboardParticipationCoordinator(
        updatePreference: (optIn) {
          return ref
              .read(leaderboardPreferenceControllerProvider.notifier)
              .updateParticipation(optIn);
        },
        readSelectedPeriod: () {
          return ref.read(leaderboardControllerProvider).period;
        },
        resetLeaderboard: () {
          ref.read(leaderboardControllerProvider.notifier).reset();
        },
        resetHome: () {
          ref.read(homeControllerProvider.notifier).reset();
        },
        reloadHome: () {
          return ref
              .read(homeControllerProvider.notifier)
              .loadDashboard(forceRefresh: true);
        },
        reloadLeaderboardPeriod: (period) {
          return ref
              .read(leaderboardControllerProvider.notifier)
              .loadLeaderboard(period: period, forceRefresh: true);
        },
      );
    });

class SettingsLeaderboardParticipationCoordinator {
  const SettingsLeaderboardParticipationCoordinator({
    required this.updatePreference,
    required this.readSelectedPeriod,
    required this.resetLeaderboard,
    required this.resetHome,
    required this.reloadHome,
    required this.reloadLeaderboardPeriod,
  });

  final UpdateLeaderboardPreference updatePreference;

  final ReadLeaderboardPeriod readSelectedPeriod;

  final SettingsLeaderboardSyncAction resetLeaderboard;

  final SettingsLeaderboardSyncAction resetHome;

  final SettingsLeaderboardAsyncAction reloadHome;

  final ReloadLeaderboardPeriod reloadLeaderboardPeriod;

  Future<String?> updateParticipation(bool optIn) async {
    /*
     * Simpan period yang sedang dipilih sebelum
     * Home memuatkan Leaderboard mingguan.
     */
    final selectedPeriod = readSelectedPeriod();

    final errorMessage = await updatePreference(optIn);

    if (errorMessage != null) {
      return errorMessage;
    }

    /*
     * Buang cache lama supaya ranking dan status
     * penyertaan terdahulu tidak terus dipaparkan.
     */
    resetLeaderboard();
    resetHome();

    /*
     * Home sentiasa menggunakan Leaderboard
     * mingguan.
     */
    await reloadHome();

    /*
     * Pulihkan pilihan bulanan selepas Home
     * selesai menggunakan data mingguan.
     */
    if (selectedPeriod != LeaderboardPeriod.weekly) {
      await reloadLeaderboardPeriod(selectedPeriod);
    }

    return null;
  }
}
