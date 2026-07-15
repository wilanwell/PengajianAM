import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import 'leaderboard_state.dart';

final leaderboardControllerProvider =
    NotifierProvider<LeaderboardController, LeaderboardState>(
      LeaderboardController.new,
    );

class LeaderboardController extends Notifier<LeaderboardState> {
  static const List<_LeaderboardSeed> _weeklySeeds = [
    _LeaderboardSeed(
      userId: 'user-01',
      nickname: 'NotaNinja',
      xp: 2450,
      previousRank: 2,
    ),
    _LeaderboardSeed(
      userId: 'user-02',
      nickname: 'FokusPA',
      xp: 2260,
      previousRank: 1,
    ),
    _LeaderboardSeed(
      userId: 'user-03',
      nickname: 'StudyQueen',
      xp: 2050,
      previousRank: 3,
    ),
    _LeaderboardSeed(
      userId: 'user-04',
      nickname: 'PerlembagaanPro',
      xp: 1900,
      previousRank: 5,
    ),
    _LeaderboardSeed(
      userId: 'user-06',
      nickname: 'KedaulatanAce',
      xp: 1700,
      previousRank: 4,
    ),
    _LeaderboardSeed(
      userId: 'user-07',
      nickname: 'TadbirUrusMaster',
      xp: 1600,
      previousRank: 8,
    ),
    _LeaderboardSeed(
      userId: 'user-08',
      nickname: 'STPMCemerlang',
      xp: 1490,
      previousRank: 6,
    ),
    _LeaderboardSeed(
      userId: 'user-09',
      nickname: 'SabahScholar',
      xp: 1370,
      previousRank: 10,
    ),
    _LeaderboardSeed(
      userId: 'user-10',
      nickname: 'PAObjective',
      xp: 1250,
      previousRank: 9,
    ),
  ];

  static const List<_LeaderboardSeed> _monthlySeeds = [
    _LeaderboardSeed(
      userId: 'user-03',
      nickname: 'StudyQueen',
      xp: 8450,
      previousRank: 2,
    ),
    _LeaderboardSeed(
      userId: 'user-01',
      nickname: 'NotaNinja',
      xp: 8120,
      previousRank: 1,
    ),
    _LeaderboardSeed(
      userId: 'user-04',
      nickname: 'PerlembagaanPro',
      xp: 7750,
      previousRank: 4,
    ),
    _LeaderboardSeed(
      userId: 'user-02',
      nickname: 'FokusPA',
      xp: 7380,
      previousRank: 3,
    ),
    _LeaderboardSeed(
      userId: 'user-07',
      nickname: 'TadbirUrusMaster',
      xp: 6900,
      previousRank: 7,
    ),
    _LeaderboardSeed(
      userId: 'user-06',
      nickname: 'KedaulatanAce',
      xp: 6280,
      previousRank: 5,
    ),
    _LeaderboardSeed(
      userId: 'user-08',
      nickname: 'STPMCemerlang',
      xp: 5990,
      previousRank: 6,
    ),
    _LeaderboardSeed(
      userId: 'user-09',
      nickname: 'SabahScholar',
      xp: 5500,
      previousRank: 10,
    ),
    _LeaderboardSeed(
      userId: 'user-10',
      nickname: 'PAObjective',
      xp: 5100,
      previousRank: 9,
    ),
  ];

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
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final progress = ref.read(userProgressControllerProvider);

      final entries = _buildEntries(period: selectedPeriod, progress: progress);

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

  List<LeaderboardEntry> _buildEntries({
    required LeaderboardPeriod period,
    required UserProgress progress,
  }) {
    final sourceSeeds = period == LeaderboardPeriod.weekly
        ? _weeklySeeds
        : _monthlySeeds;

    final currentUserXp = period == LeaderboardPeriod.weekly
        ? progress.weeklyXp
        : progress.monthlyXp;

    final currentUserPreviousRank = period == LeaderboardPeriod.weekly ? 7 : 8;

    final seeds = <_LeaderboardSeed>[
      ...sourceSeeds,
      _LeaderboardSeed(
        userId: progress.userId,
        nickname: progress.displayName,
        xp: currentUserXp,
        previousRank: currentUserPreviousRank,
        isCurrentUser: true,
      ),
    ];

    seeds.sort((first, second) {
      final xpComparison = second.xp.compareTo(first.xp);

      if (xpComparison != 0) {
        return xpComparison;
      }

      return first.nickname.compareTo(second.nickname);
    });

    return List<LeaderboardEntry>.unmodifiable([
      for (var index = 0; index < seeds.length; index++)
        LeaderboardEntry(
          userId: seeds[index].userId,
          nickname: seeds[index].nickname,
          rank: index + 1,
          xp: seeds[index].xp,
          previousRank: seeds[index].previousRank,
          isCurrentUser: seeds[index].isCurrentUser,
        ),
    ]);
  }
}

class _LeaderboardSeed {
  const _LeaderboardSeed({
    required this.userId,
    required this.nickname,
    required this.xp,
    required this.previousRank,
    this.isCurrentUser = false,
  });

  final String userId;
  final String nickname;
  final int xp;
  final int previousRank;
  final bool isCurrentUser;
}
