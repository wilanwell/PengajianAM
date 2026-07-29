import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/coordinators/profile_account_coordinator.dart';

void main() {
  group('ProfileAccountCoordinator', () {
    test(
      'updateDisplayName menghantar nama dan memulangkan null apabila berjaya',
      () async {
        String? receivedName;

        final coordinator = ProfileAccountCoordinator(
          updateDisplayNameAction: (value) async {
            receivedName = value;

            return null;
          },
          logoutAction: () async {},
        );

        final result = await coordinator.updateDisplayName('Pelajar Baharu');

        expect(receivedName, 'Pelajar Baharu');

        expect(result, isNull);
      },
    );

    test('updateDisplayName mengekalkan mesej kegagalan controller', () async {
      final coordinator = ProfileAccountCoordinator(
        updateDisplayNameAction: (value) async {
          return 'Nama paparan tidak sah.';
        },
        logoutAction: () async {},
      );

      final result = await coordinator.updateDisplayName('Nama');

      expect(result, 'Nama paparan tidak sah.');
    });

    test('updateDisplayName menukar exception kepada mesej umum', () async {
      final coordinator = ProfileAccountCoordinator(
        updateDisplayNameAction: (value) async {
          throw Exception('unexpected error');
        },
        logoutAction: () async {},
      );

      final result = await coordinator.updateDisplayName('Pelajar Baharu');

      expect(
        result,
        'Nama paparan tidak dapat '
        'dikemas kini. Sila cuba semula.',
      );
    });

    test('logout memulangkan null apabila berjaya', () async {
      var logoutCount = 0;

      final coordinator = ProfileAccountCoordinator(
        updateDisplayNameAction: (value) async {
          return null;
        },
        logoutAction: () async {
          logoutCount++;
        },
      );

      final result = await coordinator.logout();

      expect(logoutCount, 1);

      expect(result, isNull);
    });

    test('logout menukar exception kepada mesej kegagalan', () async {
      final coordinator = ProfileAccountCoordinator(
        updateDisplayNameAction: (value) async {
          return null;
        },
        logoutAction: () async {
          throw Exception('logout failed');
        },
      );

      final result = await coordinator.logout();

      expect(
        result,
        'Log keluar tidak dapat '
        'diselesaikan.',
      );
    });
  });
}
