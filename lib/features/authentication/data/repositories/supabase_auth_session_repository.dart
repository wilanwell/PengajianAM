import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/auth_registration_result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/exceptions/authentication_failure.dart';
import '../../domain/repositories/auth_session_repository.dart';

class SupabaseAuthSessionRepository implements AuthSessionRepository {
  const SupabaseAuthSessionRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;
  final NetworkRequestExecutor _requestExecutor;

  @override
  AuthSession? get currentSession {
    return _mapSession(_client.auth.currentSession);
  }

  @override
  Stream<AuthSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((authState) {
      return _mapSession(authState.session);
    });
  }

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _requestExecutor.run<AuthResponse>(
        request: () {
          return _client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
        },
      );

      final session = _mapSession(response.session);

      if (session == null) {
        throw const AuthenticationFailure(
          'Sesi log masuk tidak dapat diwujudkan.',
        );
      }

      return session;
    } on AuthenticationFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw AuthenticationFailure(error.message);
    } on AuthException catch (error) {
      throw AuthenticationFailure(_mapAuthErrorMessage(error.message));
    } catch (_) {
      throw const AuthenticationFailure(
        'Tidak dapat berhubung dengan pelayan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  @override
  Future<AuthRegistrationResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final response = await _requestExecutor.run<AuthResponse>(
        request: () {
          return _client.auth.signUp(
            email: normalizedEmail,
            password: password,
            data: {'display_name': displayName.trim()},
          );
        },
      );

      final user = response.user;

      if (user == null) {
        throw const AuthenticationFailure('Akaun tidak dapat dicipta.');
      }

      return AuthRegistrationResult(
        userId: user.id,
        email: user.email ?? normalizedEmail,
        session: _mapSession(response.session),
      );
    } on AuthenticationFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw AuthenticationFailure(error.message);
    } on AuthException catch (error) {
      throw AuthenticationFailure(_mapAuthErrorMessage(error.message));
    } catch (_) {
      throw const AuthenticationFailure(
        'Pendaftaran tidak dapat diselesaikan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _requestExecutor.run<void>(
        request: () {
          return _client.auth.signOut();
        },
      );
    } on NetworkRequestTimeoutFailure catch (error) {
      throw AuthenticationFailure(error.message);
    } on AuthException catch (error) {
      throw AuthenticationFailure(_mapAuthErrorMessage(error.message));
    } catch (_) {
      throw const AuthenticationFailure('Log keluar tidak dapat diselesaikan.');
    }
  }

  AuthSession? _mapSession(Session? session) {
    if (session == null) {
      return null;
    }

    return AuthSession(
      isAuthenticated: true,
      userId: session.user.id,
      email: session.user.email,
      signedInAt: DateTime.now(),
    );
  }

  String _mapAuthErrorMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'E-mel atau kata laluan tidak betul.';
    }

    if (message.contains('email not confirmed')) {
      return 'E-mel belum disahkan. '
          'Sila semak peti masuk e-mel anda.';
    }

    if (message.contains('user already registered')) {
      return 'E-mel ini telah didaftarkan.';
    }

    if (message.contains('password should be at least') ||
        message.contains('password is too short')) {
      return 'Kata laluan terlalu pendek.';
    }

    if (message.contains('email rate limit exceeded')) {
      return 'Terlalu banyak permintaan e-mel. '
          'Sila cuba semula kemudian.';
    }

    if (message.contains('signup is disabled')) {
      return 'Pendaftaran akaun sedang '
          'dinyahaktifkan.';
    }

    if (message.contains('network request failed') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused')) {
      return 'Tidak dapat berhubung dengan pelayan. '
          'Semak sambungan Internet anda.';
    }

    return 'Authentication gagal. '
        'Sila cuba semula.';
  }
}
