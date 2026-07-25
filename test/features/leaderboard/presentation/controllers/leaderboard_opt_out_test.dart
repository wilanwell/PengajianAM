import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_state.dart';

class _OptOutLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<LeaderboardSnapshot> fetchLeaderboard({
    required LeaderboardPeriod period,
    int limit = 100,
  }) async {
    return LeaderboardSnapshot(
      period: period,
      generatedAt: DateTime.utc(2026, 7, 24, 3),
      periodStartsAt: DateTime.utc(2026, 7, 19, 16),
      periodEndsAt: DateTime.utc(2026, 7, 26, 16),
      timezone: 'Asia/Kuala_Lumpur',
      isParticipating: false,
      currentUserXp: 140,
      participantCount: 0,
      entries: const [],
    );
  }
}

void main() {
  test('pengguna opt-out berjaya memuatkan '
      'leaderboard tanpa ranking', () async {
    final repository = _OptOutLeaderboardRepository();

    final container = ProviderContainer(
      overrides: [leaderboardRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container
        .read(leaderboardControllerProvider.notifier)
        .loadLeaderboard();

    final state = container.read(leaderboardControllerProvider);

    expect(state.status, LeaderboardStatus.success);

    expect(state.isParticipating, isFalse);

    expect(state.currentUserEntry, isNull);

    expect(state.hasCurrentUserRanking, isFalse);

    expect(state.currentUserXp, 140);

    expect(state.participantCount, 0);

    expect(state.entries, isEmpty);

    expect(state.timezone, 'Asia/Kuala_Lumpur');
  });
}
