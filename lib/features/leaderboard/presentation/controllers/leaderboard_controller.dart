import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import 'leaderboard_state.dart';

final leaderboardControllerProvider =
    NotifierProvider<LeaderboardController, LeaderboardState>(
      LeaderboardController.new,
    );

class LeaderboardController extends Notifier<LeaderboardState> {
  static final List<LeaderboardEntry> _weeklyEntries =
      List<LeaderboardEntry>.unmodifiable([
        const LeaderboardEntry(
          userId: 'user-01',
          nickname: 'NotaNinja',
          rank: 1,
          previousRank: 2,
          xp: 2450,
        ),
        const LeaderboardEntry(
          userId: 'user-02',
          nickname: 'FokusPA',
          rank: 2,
          previousRank: 1,
          xp: 2260,
        ),
        const LeaderboardEntry(
          userId: 'user-03',
          nickname: 'StudyQueen',
          rank: 3,
          previousRank: 3,
          xp: 2050,
        ),
        const LeaderboardEntry(
          userId: 'user-04',
          nickname: 'PerlembagaanPro',
          rank: 4,
          previousRank: 5,
          xp: 1900,
        ),
        const LeaderboardEntry(
          userId: 'current-user',
          nickname: 'PelajarPA',
          rank: 5,
          previousRank: 7,
          xp: 1820,
          isCurrentUser: true,
        ),
        const LeaderboardEntry(
          userId: 'user-06',
          nickname: 'KedaulatanAce',
          rank: 6,
          previousRank: 4,
          xp: 1700,
        ),
        const LeaderboardEntry(
          userId: 'user-07',
          nickname: 'TadbirUrusMaster',
          rank: 7,
          previousRank: 8,
          xp: 1600,
        ),
        const LeaderboardEntry(
          userId: 'user-08',
          nickname: 'STPMCemerlang',
          rank: 8,
          previousRank: 6,
          xp: 1490,
        ),
        const LeaderboardEntry(
          userId: 'user-09',
          nickname: 'SabahScholar',
          rank: 9,
          previousRank: 10,
          xp: 1370,
        ),
        const LeaderboardEntry(
          userId: 'user-10',
          nickname: 'PAObjective',
          rank: 10,
          previousRank: 9,
          xp: 1250,
        ),
      ]);

  static final List<LeaderboardEntry> _monthlyEntries =
      List<LeaderboardEntry>.unmodifiable([
        const LeaderboardEntry(
          userId: 'user-03',
          nickname: 'StudyQueen',
          rank: 1,
          previousRank: 2,
          xp: 8450,
        ),
        const LeaderboardEntry(
          userId: 'user-01',
          nickname: 'NotaNinja',
          rank: 2,
          previousRank: 1,
          xp: 8120,
        ),
        const LeaderboardEntry(
          userId: 'user-04',
          nickname: 'PerlembagaanPro',
          rank: 3,
          previousRank: 4,
          xp: 7750,
        ),
        const LeaderboardEntry(
          userId: 'user-02',
          nickname: 'FokusPA',
          rank: 4,
          previousRank: 3,
          xp: 7380,
        ),
        const LeaderboardEntry(
          userId: 'user-07',
          nickname: 'TadbirUrusMaster',
          rank: 5,
          previousRank: 7,
          xp: 6900,
        ),
        const LeaderboardEntry(
          userId: 'current-user',
          nickname: 'PelajarPA',
          rank: 6,
          previousRank: 8,
          xp: 6540,
          isCurrentUser: true,
        ),
        const LeaderboardEntry(
          userId: 'user-06',
          nickname: 'KedaulatanAce',
          rank: 7,
          previousRank: 5,
          xp: 6280,
        ),
        const LeaderboardEntry(
          userId: 'user-08',
          nickname: 'STPMCemerlang',
          rank: 8,
          previousRank: 6,
          xp: 5990,
        ),
        const LeaderboardEntry(
          userId: 'user-09',
          nickname: 'SabahScholar',
          rank: 9,
          previousRank: 10,
          xp: 5500,
        ),
        const LeaderboardEntry(
          userId: 'user-10',
          nickname: 'PAObjective',
          rank: 10,
          previousRank: 9,
          xp: 5100,
        ),
      ]);

  @override
  LeaderboardState build() {
    return const LeaderboardState();
  }

  Future<void> loadLeaderboard({
    LeaderboardPeriod? period,
    bool forceRefresh = false,
  }) async {
    final selectedPeriod = period ?? state.period;

    if (!forceRefresh &&
        state.status == LeaderboardStatus.success &&
        state.period == selectedPeriod) {
      return;
    }

    state = state.copyWith(
      status: LeaderboardStatus.loading,
      period: selectedPeriod,
      clearErrorMessage: true,
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final entries = switch (selectedPeriod) {
        LeaderboardPeriod.weekly => _weeklyEntries,
        LeaderboardPeriod.monthly => _monthlyEntries,
      };

      state = LeaderboardState(
        status: LeaderboardStatus.success,
        period: selectedPeriod,
        entries: entries,
        lastUpdated: DateTime.now(),
      );
    } catch (_) {
      state = LeaderboardState(
        status: LeaderboardStatus.failure,
        period: selectedPeriod,
        errorMessage: 'Leaderboard tidak dapat dimuatkan. Sila cuba semula.',
      );
    }
  }

  Future<void> changePeriod(LeaderboardPeriod period) {
    return loadLeaderboard(period: period, forceRefresh: true);
  }

  Future<void> refreshLeaderboard() {
    return loadLeaderboard(period: state.period, forceRefresh: true);
  }

  void reset() {
    state = const LeaderboardState();
  }
}
