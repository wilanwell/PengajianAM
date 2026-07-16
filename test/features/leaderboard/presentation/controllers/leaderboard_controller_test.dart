import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_state.dart';

class _FakeLeaderboardRepository implements LeaderboardRepository {
  final requestedPeriods = <LeaderboardPeriod>[];

  final requestedLimits = <int>[];

  @override
  Future<LeaderboardSnapshot> fetchLeaderboard({
    required LeaderboardPeriod period,
    int limit = 100,
  }) async {
    requestedPeriods.add(period);

    requestedLimits.add(limit);

    return switch (period) {
      LeaderboardPeriod.weekly => LeaderboardSnapshot(
        period: period,
        generatedAt: DateTime(2026, 7, 16, 12),
        participantCount: 4,
        entries: const [
          LeaderboardEntry(
            userId: 'entry-1',
            nickname: 'Pelajar-A111',
            rank: 1,
            xp: 2450,
            previousRank: null,
          ),
          LeaderboardEntry(
            userId: 'current-entry',
            nickname: 'PelajarPA',
            rank: 2,
            xp: 1820,
            previousRank: null,
            isCurrentUser: true,
          ),
          LeaderboardEntry(
            userId: 'entry-3',
            nickname: 'Pelajar-C333',
            rank: 3,
            xp: 1600,
            previousRank: null,
          ),
          LeaderboardEntry(
            userId: 'entry-4',
            nickname: 'Pelajar-D444',
            rank: 4,
            xp: 1200,
            previousRank: null,
          ),
        ],
      ),

      LeaderboardPeriod.monthly => LeaderboardSnapshot(
        period: period,
        generatedAt: DateTime(2026, 7, 16, 13),
        participantCount: 5,
        entries: const [
          LeaderboardEntry(
            userId: 'entry-1',
            nickname: 'Pelajar-A111',
            rank: 1,
            xp: 8450,
            previousRank: null,
          ),
          LeaderboardEntry(
            userId: 'entry-2',
            nickname: 'Pelajar-B222',
            rank: 2,
            xp: 7200,
            previousRank: null,
          ),
          LeaderboardEntry(
            userId: 'current-entry',
            nickname: 'PelajarPA',
            rank: 3,
            xp: 6540,
            previousRank: null,
            isCurrentUser: true,
          ),
          LeaderboardEntry(
            userId: 'entry-4',
            nickname: 'Pelajar-D444',
            rank: 4,
            xp: 5900,
            previousRank: null,
          ),
          LeaderboardEntry(
            userId: 'entry-5',
            nickname: 'Pelajar-E555',
            rank: 5,
            xp: 5100,
            previousRank: null,
          ),
        ],
      ),
    };
  }
}

void main() {
  test('memuatkan leaderboard mingguan daripada repository', () async {
    final repository = _FakeLeaderboardRepository();

    final container = ProviderContainer(
      overrides: [leaderboardRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(leaderboardControllerProvider.notifier);

    await controller.loadLeaderboard();

    final state = container.read(leaderboardControllerProvider);

    expect(state.status, LeaderboardStatus.success);

    expect(state.period, LeaderboardPeriod.weekly);

    expect(state.entries, hasLength(4));

    expect(state.participantCount, 4);

    expect(state.currentUserEntry, isNotNull);

    expect(state.currentUserEntry!.rank, 2);

    expect(state.currentUserEntry!.xp, 1820);

    expect(state.topThree, hasLength(3));

    expect(state.remainingEntries, hasLength(1));

    expect(state.lastUpdated, DateTime(2026, 7, 16, 12));

    expect(repository.requestedPeriods, [LeaderboardPeriod.weekly]);

    expect(repository.requestedLimits, [100]);
  });

  test('menukar leaderboard kepada tempoh bulanan', () async {
    final repository = _FakeLeaderboardRepository();

    final container = ProviderContainer(
      overrides: [leaderboardRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(leaderboardControllerProvider.notifier);

    await controller.loadLeaderboard();

    await controller.changePeriod(LeaderboardPeriod.monthly);

    final state = container.read(leaderboardControllerProvider);

    expect(state.status, LeaderboardStatus.success);

    expect(state.period, LeaderboardPeriod.monthly);

    expect(state.entries, hasLength(5));

    expect(state.participantCount, 5);

    expect(state.currentUserEntry, isNotNull);

    expect(state.currentUserEntry!.rank, 3);

    expect(state.currentUserEntry!.xp, 6540);

    expect(repository.requestedPeriods, [
      LeaderboardPeriod.weekly,
      LeaderboardPeriod.monthly,
    ]);
  });

  test('tidak memuatkan semula tempoh yang sama tanpa force refresh', () async {
    final repository = _FakeLeaderboardRepository();

    final container = ProviderContainer(
      overrides: [leaderboardRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(leaderboardControllerProvider.notifier);

    await controller.loadLeaderboard();

    await controller.loadLeaderboard();

    expect(repository.requestedPeriods, hasLength(1));

    await controller.refreshLeaderboard();

    expect(repository.requestedPeriods, hasLength(2));
  });
}
