import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/session/app_logout_controller.dart';

typedef HomeLogoutAction = Future<void> Function();

final homeSessionCoordinatorProvider = Provider<HomeSessionCoordinator>((ref) {
  return HomeSessionCoordinator(
    logoutAction: () {
      return ref.read(appLogoutControllerProvider.notifier).logout();
    },
  );
});

class HomeSessionCoordinator {
  const HomeSessionCoordinator({required this.logoutAction});

  final HomeLogoutAction logoutAction;

  Future<String?> logout() async {
    try {
      await logoutAction();

      return null;
    } catch (_) {
      return 'Log keluar tidak dapat '
          'diselesaikan.';
    }
  }
}
