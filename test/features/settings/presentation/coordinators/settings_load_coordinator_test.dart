import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/coordinators/settings_load_coordinator.dart';

void main() {
  group('SettingsLoadCoordinator', () {
    test('loadInitial memuatkan kedua-dua data tanpa force refresh', () async {
      final calls = <String>[];

      final coordinator = SettingsLoadCoordinator(
        loadSettings: (forceRefresh) async {
          calls.add('loadSettings:$forceRefresh');
        },
        loadLeaderboardPreference: (forceRefresh) async {
          calls.add(
            'loadLeaderboardPreference:'
            '$forceRefresh',
          );
        },
      );

      await coordinator.loadInitial();

      expect(
        calls,
        containsAll(['loadSettings:false', 'loadLeaderboardPreference:false']),
      );

      expect(calls, hasLength(2));
    });

    test('refreshAll memuatkan kedua-dua data dengan force refresh', () async {
      final calls = <String>[];

      final coordinator = SettingsLoadCoordinator(
        loadSettings: (forceRefresh) async {
          calls.add('loadSettings:$forceRefresh');
        },
        loadLeaderboardPreference: (forceRefresh) async {
          calls.add(
            'loadLeaderboardPreference:'
            '$forceRefresh',
          );
        },
      );

      await coordinator.refreshAll();

      expect(
        calls,
        containsAll(['loadSettings:true', 'loadLeaderboardPreference:true']),
      );

      expect(calls, hasLength(2));
    });

    test('retrySettings hanya memuatkan semula tetapan', () async {
      final calls = <String>[];

      final coordinator = SettingsLoadCoordinator(
        loadSettings: (forceRefresh) async {
          calls.add('loadSettings:$forceRefresh');
        },
        loadLeaderboardPreference: (forceRefresh) async {
          calls.add(
            'loadLeaderboardPreference:'
            '$forceRefresh',
          );
        },
      );

      await coordinator.retrySettings();

      expect(calls, ['loadSettings:true']);
    });

    test(
      'retryLeaderboardPreference hanya memuatkan semula preference',
      () async {
        final calls = <String>[];

        final coordinator = SettingsLoadCoordinator(
          loadSettings: (forceRefresh) async {
            calls.add('loadSettings:$forceRefresh');
          },
          loadLeaderboardPreference: (forceRefresh) async {
            calls.add(
              'loadLeaderboardPreference:'
              '$forceRefresh',
            );
          },
        );

        await coordinator.retryLeaderboardPreference();

        expect(calls, ['loadLeaderboardPreference:true']);
      },
    );
  });
}
