import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../features/authentication/presentation/controllers/account_deletion_controller.dart';
import '../../features/authentication/presentation/controllers/auth_session_controller.dart';
import '../../features/authentication/presentation/controllers/login_controller.dart';
import '../../features/authentication/presentation/controllers/password_recovery_controller.dart';
import '../../features/authentication/presentation/controllers/register_controller.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/progress/presentation/controllers/user_progress_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_history_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_session_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_setup_controller.dart';
import '../../features/topics/presentation/controllers/topics_controller.dart';

final appLogoutControllerProvider = NotifierProvider<AppLogoutController, bool>(
  AppLogoutController.new,
);

class AppLogoutController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<void> logout() async {
    if (state) {
      return;
    }

    state = true;

    try {
      /*
       * Simpan draft pengguna semasa dan
       * hentikan timer sebelum sesi Supabase
       * dibuang.
       *
       * Draft disimpan menggunakan ID akaun
       * yang masih aktif.
       */
      await ref
          .read(quizSessionControllerProvider.notifier)
          .preserveDraftAndReset();

      /*
       * Logout hanya dilakukan selepas semua
       * operasi draft selesai.
       */
      await ref.read(authSessionControllerProvider.notifier).signOut();

      /*
       * Selepas logout berjaya, kosongkan semua
       * state yang mungkin mengandungi data
       * pengguna terdahulu.
       */
      _clearUserScopedState();
    } finally {
      state = false;
    }
  }

  void _clearUserScopedState() {
    /*
     * Authentication form state.
     */
    ref.invalidate(loginControllerProvider);

    ref.invalidate(registerControllerProvider);

    ref.invalidate(passwordRecoveryControllerProvider);

    ref.invalidate(accountDeletionControllerProvider);

    /*
     * Dashboard dan content progress.
     */
    ref.invalidate(homeControllerProvider);

    ref.invalidate(topicsControllerProvider);

    ref.invalidate(userProgressControllerProvider);

    /*
     * Quiz dan analytics.
     */
    ref.invalidate(quizSetupControllerProvider);

    ref.invalidate(quizSessionControllerProvider);

    ref.invalidate(quizHistoryControllerProvider);

    ref.invalidate(topicAnalyticsControllerProvider);

    /*
     * Public-looking screens yang masih
     * mengandungi data atau kedudukan pengguna
     * semasa.
     */
    ref.invalidate(leaderboardControllerProvider);

    ref.invalidate(profileControllerProvider);
  }
}
