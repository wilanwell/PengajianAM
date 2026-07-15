import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_state.dart';

void main() {
  test('memuatkan dan menukar tempoh leaderboard', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(leaderboardControllerProvider.notifier);

    await controller.loadLeaderboard();

    var state = container.read(leaderboardControllerProvider);

    expect(state.status, LeaderboardStatus.success);

    expect(state.period, LeaderboardPeriod.weekly);

    expect(state.entries, hasLength(10));

    expect(state.currentUserEntry?.rank, 5);

    expect(state.topThree, hasLength(3));

    await controller.changePeriod(LeaderboardPeriod.monthly);

    state = container.read(leaderboardControllerProvider);

    expect(state.period, LeaderboardPeriod.monthly);

    expect(state.currentUserEntry?.rank, 6);

    expect(state.currentUserEntry?.xp, 6540);
  });
}
