import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/session/app_logout_controller.dart';
import '../controllers/profile_controller.dart';

typedef ProfileDisplayNameUpdateAction = Future<String?> Function(String value);

typedef ProfileLogoutAction = Future<void> Function();

final profileAccountCoordinatorProvider = Provider<ProfileAccountCoordinator>((
  ref,
) {
  return ProfileAccountCoordinator(
    updateDisplayNameAction: (value) {
      return ref
          .read(profileControllerProvider.notifier)
          .updateDisplayName(value);
    },
    logoutAction: () {
      return ref.read(appLogoutControllerProvider.notifier).logout();
    },
  );
});

class ProfileAccountCoordinator {
  const ProfileAccountCoordinator({
    required this.updateDisplayNameAction,
    required this.logoutAction,
  });

  final ProfileDisplayNameUpdateAction updateDisplayNameAction;

  final ProfileLogoutAction logoutAction;

  Future<String?> updateDisplayName(String value) async {
    try {
      return await updateDisplayNameAction(value);
    } catch (_) {
      return 'Nama paparan tidak dapat '
          'dikemas kini. Sila cuba semula.';
    }
  }

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
