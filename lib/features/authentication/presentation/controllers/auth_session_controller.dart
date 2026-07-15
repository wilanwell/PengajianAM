import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/shared_preferences_auth_session_repository.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_session_repository.dart';
import 'auth_session_state.dart';

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  return SharedPreferencesAuthSessionRepository();
});

final authSessionControllerProvider =
    NotifierProvider<AuthSessionController, AuthSessionState>(
      AuthSessionController.new,
    );

class AuthSessionController extends Notifier<AuthSessionState> {
  AuthSessionRepository get _repository {
    return ref.read(authSessionRepositoryProvider);
  }

  @override
  AuthSessionState build() {
    return const AuthSessionState();
  }

  Future<void> loadSession({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == AuthSessionStatus.loading ||
            state.status == AuthSessionStatus.authenticated ||
            state.status == AuthSessionStatus.unauthenticated)) {
      return;
    }

    state = const AuthSessionState(status: AuthSessionStatus.loading);

    try {
      final storedSession = await _repository.loadSession();

      if (storedSession?.isAuthenticated == true) {
        state = AuthSessionState(
          status: AuthSessionStatus.authenticated,
          session: storedSession!,
        );

        return;
      }

      state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
    } catch (_) {
      // Jika local storage gagal dibaca, pengguna dibawa
      // ke Login dan aplikasi masih boleh digunakan.
      state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
    }
  }

  Future<void> signIn() async {
    final session = AuthSession(
      isAuthenticated: true,
      signedInAt: DateTime.now(),
    );

    state = AuthSessionState(
      status: AuthSessionStatus.authenticated,
      session: session,
    );

    try {
      await _repository.saveSession(session);
    } catch (_) {
      // Sesi masih aktif untuk penggunaan semasa walaupun
      // local persistence gagal.
    }
  }

  Future<void> signOut() async {
    state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);

    try {
      await _repository.clearSession();
    } catch (_) {
      // State semasa tetap dianggap sudah log keluar.
    }
  }

  void resetState() {
    state = const AuthSessionState();
  }
}
