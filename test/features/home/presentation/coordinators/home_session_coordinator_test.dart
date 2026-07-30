import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/coordinators/home_session_coordinator.dart';

void main() {
  group('HomeSessionCoordinator', () {
    test(
      'logout memanggil action dan memulangkan null apabila berjaya',
      () async {
        var logoutCount = 0;

        final coordinator = HomeSessionCoordinator(
          logoutAction: () async {
            logoutCount++;
          },
        );

        final result = await coordinator.logout();

        expect(logoutCount, 1);

        expect(result, isNull);
      },
    );

    test('logout menukar exception kepada mesej kegagalan', () async {
      final coordinator = HomeSessionCoordinator(
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
