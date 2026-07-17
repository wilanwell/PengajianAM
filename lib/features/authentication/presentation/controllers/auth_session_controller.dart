import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_auth_session_repository.dart';
import '../../domain/entities/auth_registration_result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_session_repository.dart';
import 'auth_session_state.dart';

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  return SupabaseAuthSessionRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final authSessionControllerProvider =
    NotifierProvider<AuthSessionController, AuthSessionState>(
      AuthSessionController.new,
    );

class AuthSessionController extends Notifier<AuthSessionState> {
  StreamSubscription<AuthSession?>? _subscription;

  AuthSessionRepository get _repository {
    return ref.read(authSessionRepositoryProvider);
  }

  @override
  AuthSessionState build() {
    _subscription = _repository.authStateChanges.listen(
      _handleSessionChange,
      onError: (Object error, StackTrace stackTrace) {
        if (state.status == AuthSessionStatus.initial ||
            state.status == AuthSessionStatus.loading) {
          state = const AuthSessionState(
            status: AuthSessionStatus.unauthenticated,
          );
        }
      },
    );

    ref.onDispose(() {
      final subscription = _subscription;

      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });

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

    final session = _repository.currentSession;

    _handleSessionChange(session);
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthSessionState(status: AuthSessionStatus.loading);

    final session = await _repository.signInWithPassword(
      email: email,
      password: password,
    );

    state = AuthSessionState(
      status: AuthSessionStatus.authenticated,
      session: session,
    );
  }

  Future<AuthRegistrationResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = const AuthSessionState(status: AuthSessionStatus.loading);

    final result = await _repository.signUp(
      displayName: displayName,
      email: email,
      password: password,
    );

    final session = result.session;

    if (session == null) {
      state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
    } else {
      state = AuthSessionState(
        status: AuthSessionStatus.authenticated,
        session: session,
      );
    }

    return result;
  }

  Future<void> signOut() async {
    await _repository.signOut();

    state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
  }

  void resetState() {
    state = const AuthSessionState();
  }

  void _handleSessionChange(AuthSession? session) {
    if (session?.isAuthenticated == true) {
      state = AuthSessionState(
        status: AuthSessionStatus.authenticated,
        session: session!,
      );

      return;
    }

    state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
  }
}
