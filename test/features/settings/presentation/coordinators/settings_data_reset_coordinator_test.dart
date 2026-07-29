import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/coordinators/settings_data_reset_coordinator.dart';

void main() {
  group('SettingsDataResetCoordinator', () {
    test('menjalankan semua operasi reset mengikut urutan', () async {
      final calls = <String>[];

      final coordinator = SettingsDataResetCoordinator(
        clearLocalProgress: () async {
          calls.add('clearLocalProgress');
        },
        discardQuizDraft: () async {
          calls.add('discardQuizDraft');
        },
        resetQuizHistory: () {
          calls.add('resetQuizHistory');
        },
        resetTopicAnalytics: () {
          calls.add('resetTopicAnalytics');
        },
        resetQuizSetup: () {
          calls.add('resetQuizSetup');
        },
        resetHome: () {
          calls.add('resetHome');
        },
        resetProfile: () {
          calls.add('resetProfile');
        },
        resetLeaderboard: () {
          calls.add('resetLeaderboard');
        },
        resetSettingsToDefaults: () async {
          calls.add('resetSettingsToDefaults');
          return null;
        },
        reloadHome: () async {
          calls.add('reloadHome');
        },
        reloadProfile: () async {
          calls.add('reloadProfile');
        },
        reloadLeaderboard: () async {
          calls.add('reloadLeaderboard');
        },
      );

      final errorMessage = await coordinator.resetAllData();

      expect(errorMessage, isNull);

      expect(calls, [
        'clearLocalProgress',
        'discardQuizDraft',
        'resetQuizHistory',
        'resetTopicAnalytics',
        'resetQuizSetup',
        'resetHome',
        'resetProfile',
        'resetLeaderboard',
        'resetSettingsToDefaults',
        'reloadHome',
        'reloadProfile',
        'reloadLeaderboard',
      ]);
    });

    test('memulangkan error tetapan selepas data dimuat semula', () async {
      final calls = <String>[];

      final coordinator = SettingsDataResetCoordinator(
        clearLocalProgress: () async {},
        discardQuizDraft: () async {},
        resetQuizHistory: () {},
        resetTopicAnalytics: () {},
        resetQuizSetup: () {},
        resetHome: () {},
        resetProfile: () {},
        resetLeaderboard: () {},
        resetSettingsToDefaults: () async {
          calls.add('resetSettingsToDefaults');

          return 'Tetapan aplikasi tidak dapat direset.';
        },
        reloadHome: () async {
          calls.add('reloadHome');
        },
        reloadProfile: () async {
          calls.add('reloadProfile');
        },
        reloadLeaderboard: () async {
          calls.add('reloadLeaderboard');
        },
      );

      final errorMessage = await coordinator.resetAllData();

      expect(errorMessage, 'Tetapan aplikasi tidak dapat direset.');

      expect(calls, [
        'resetSettingsToDefaults',
        'reloadHome',
        'reloadProfile',
        'reloadLeaderboard',
      ]);
    });

    test('memulangkan mesej umum apabila operasi reset gagal', () async {
      final calls = <String>[];

      final coordinator = SettingsDataResetCoordinator(
        clearLocalProgress: () async {
          calls.add('clearLocalProgress');
        },
        discardQuizDraft: () async {
          calls.add('discardQuizDraft');

          throw StateError('Draft gagal dipadam.');
        },
        resetQuizHistory: () {
          calls.add('resetQuizHistory');
        },
        resetTopicAnalytics: () {
          calls.add('resetTopicAnalytics');
        },
        resetQuizSetup: () {
          calls.add('resetQuizSetup');
        },
        resetHome: () {
          calls.add('resetHome');
        },
        resetProfile: () {
          calls.add('resetProfile');
        },
        resetLeaderboard: () {
          calls.add('resetLeaderboard');
        },
        resetSettingsToDefaults: () async {
          calls.add('resetSettingsToDefaults');
          return null;
        },
        reloadHome: () async {
          calls.add('reloadHome');
        },
        reloadProfile: () async {
          calls.add('reloadProfile');
        },
        reloadLeaderboard: () async {
          calls.add('reloadLeaderboard');
        },
      );

      final errorMessage = await coordinator.resetAllData();

      expect(
        errorMessage,
        'Sebahagian data tidak dapat '
        'direset. Semak sambungan Internet '
        'dan cuba semula.',
      );

      expect(calls, ['clearLocalProgress', 'discardQuizDraft']);
    });
  });
}
