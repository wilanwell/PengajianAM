import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/coordinators/settings_leaderboard_participation_coordinator.dart';

void main() {
  group('SettingsLeaderboardParticipationCoordinator', () {
    test(
      'mengemas kini penyertaan dan memuatkan semula data mingguan',
      () async {
        final calls = <String>[];

        final coordinator = SettingsLeaderboardParticipationCoordinator(
          updatePreference: (optIn) async {
            calls.add('updatePreference:$optIn');

            return null;
          },
          readSelectedPeriod: () {
            calls.add('readSelectedPeriod');

            return LeaderboardPeriod.weekly;
          },
          resetLeaderboard: () {
            calls.add('resetLeaderboard');
          },
          resetHome: () {
            calls.add('resetHome');
          },
          reloadHome: () async {
            calls.add('reloadHome');
          },
          reloadLeaderboardPeriod: (period) async {
            calls.add(
              'reloadLeaderboardPeriod:'
              '${period.name}',
            );
          },
        );

        final errorMessage = await coordinator.updateParticipation(true);

        expect(errorMessage, isNull);

        expect(calls, [
          'readSelectedPeriod',
          'updatePreference:true',
          'resetLeaderboard',
          'resetHome',
          'reloadHome',
        ]);
      },
    );

    test('memulihkan period bulanan selepas Home dimuatkan', () async {
      final calls = <String>[];

      final coordinator = SettingsLeaderboardParticipationCoordinator(
        updatePreference: (optIn) async {
          calls.add('updatePreference:$optIn');

          return null;
        },
        readSelectedPeriod: () {
          calls.add('readSelectedPeriod');

          return LeaderboardPeriod.monthly;
        },
        resetLeaderboard: () {
          calls.add('resetLeaderboard');
        },
        resetHome: () {
          calls.add('resetHome');
        },
        reloadHome: () async {
          calls.add('reloadHome');
        },
        reloadLeaderboardPeriod: (period) async {
          calls.add(
            'reloadLeaderboardPeriod:'
            '${period.name}',
          );
        },
      );

      final errorMessage = await coordinator.updateParticipation(false);

      expect(errorMessage, isNull);

      expect(calls, [
        'readSelectedPeriod',
        'updatePreference:false',
        'resetLeaderboard',
        'resetHome',
        'reloadHome',
        'reloadLeaderboardPeriod:monthly',
      ]);
    });

    test(
      'tidak membersihkan cache apabila kemas kini preference gagal',
      () async {
        final calls = <String>[];

        final coordinator = SettingsLeaderboardParticipationCoordinator(
          updatePreference: (optIn) async {
            calls.add('updatePreference:$optIn');

            return 'Tetapan leaderboard '
                'tidak dapat dikemas kini.';
          },
          readSelectedPeriod: () {
            calls.add('readSelectedPeriod');

            return LeaderboardPeriod.monthly;
          },
          resetLeaderboard: () {
            calls.add('resetLeaderboard');
          },
          resetHome: () {
            calls.add('resetHome');
          },
          reloadHome: () async {
            calls.add('reloadHome');
          },
          reloadLeaderboardPeriod: (period) async {
            calls.add(
              'reloadLeaderboardPeriod:'
              '${period.name}',
            );
          },
        );

        final errorMessage = await coordinator.updateParticipation(true);

        expect(
          errorMessage,
          'Tetapan leaderboard '
          'tidak dapat dikemas kini.',
        );

        expect(calls, ['readSelectedPeriod', 'updatePreference:true']);
      },
    );
  });
}
