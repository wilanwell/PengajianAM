import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../features/authentication/presentation/controllers/account_deletion_controller.dart';
import '../../features/authentication/presentation/controllers/auth_session_controller.dart';
import '../../features/authentication/presentation/controllers/auth_session_state.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../features/leaderboard/presentation/controllers/leaderboard_preference_controller.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/progress/presentation/controllers/user_progress_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_history_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_session_controller.dart';
import '../../features/quiz/presentation/controllers/quiz_setup_controller.dart';
import '../../features/topics/presentation/controllers/topics_controller.dart';

final appAuthenticatedSessionControllerProvider =
    NotifierProvider<AppAuthenticatedSessionController, bool>(
      AppAuthenticatedSessionController.new,
    );

class AppAuthenticatedSessionController extends Notifier<bool> {
  Future<String?>? _inFlightPreparation;

  @override
  bool build() {
    ref.onDispose(() {
      _inFlightPreparation = null;
    });

    return false;
  }

  /// Menyediakan state aplikasi selepas
  /// authentication berjaya.
  ///
  /// Null bermaksud proses berjaya.
  /// String bermaksud mesej error.
  Future<String?> prepareAuthenticatedSession() {
    final currentPreparation = _inFlightPreparation;

    if (currentPreparation != null) {
      return currentPreparation;
    }

    late final Future<String?> preparation;

    preparation = _prepareInternal().whenComplete(() {
      if (identical(_inFlightPreparation, preparation)) {
        _inFlightPreparation = null;
      }
    });

    _inFlightPreparation = preparation;

    return preparation;
  }

  Future<String?> _prepareInternal() async {
    state = true;

    try {
      /*
       * LoginController hanya menetapkan
       * LoginStatus.success selepas
       * AuthSessionController selesai
       * mewujudkan sesi authenticated.
       *
       * Oleh itu, SupabaseClient tidak perlu
       * dibaca secara terus di sini.
       */
      final authState = ref.read(authSessionControllerProvider);

      if (authState.status != AuthSessionStatus.authenticated) {
        return 'Sesi log masuk belum tersedia. '
            'Sila cuba log masuk semula.';
      }

      final authenticatedUserId = authState.session.userId?.trim() ?? '';

      if (authenticatedUserId.isEmpty) {
        return 'Identiti pengguna tidak sah. '
            'Sila cuba log masuk semula.';
      }

      /*
       * Buang semua state yang mungkin masih
       * menyimpan data akaun sebelumnya.
       *
       * HomePage akan memuatkan data baharu
       * menggunakan forceRefresh.
       */
      _invalidateUserScopedState();

      return null;
    } catch (_) {
      return 'Sesi log masuk tidak dapat '
          'disediakan. Sila cuba semula.';
    } finally {
      state = false;
    }
  }

  void _invalidateUserScopedState() {
    ref.invalidate(accountDeletionControllerProvider);

    ref.invalidate(homeControllerProvider);

    ref.invalidate(userProgressControllerProvider);

    ref.invalidate(topicsControllerProvider);

    ref.invalidate(leaderboardControllerProvider);

    /*
     * Preference leaderboard juga merupakan
     * data khusus kepada pengguna semasa.
     */
    ref.invalidate(leaderboardPreferenceControllerProvider);

    ref.invalidate(profileControllerProvider);

    ref.invalidate(quizSetupControllerProvider);

    ref.invalidate(quizSessionControllerProvider);

    ref.invalidate(quizHistoryControllerProvider);

    ref.invalidate(topicAnalyticsControllerProvider);
  }
}
