import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_registration_result.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_session.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/repositories/auth_session_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_state.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthSession? storedSession;
  bool requireEmailConfirmation = false;

  @override
  AuthSession? get currentSession {
    return storedSession;
  }

  @override
  Stream<AuthSession?> get authStateChanges {
    return const Stream<AuthSession?>.empty();
  }

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final session = AuthSession(
      isAuthenticated: true,
      userId: 'user-123',
      email: email,
      signedInAt: DateTime(2026, 7, 16),
    );

    storedSession = session;

    return session;
  }

  @override
  Future<AuthRegistrationResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final session = requireEmailConfirmation
        ? null
        : AuthSession(
            isAuthenticated: true,
            userId: 'user-456',
            email: email,
            signedInAt: DateTime(2026, 7, 16),
          );

    storedSession = session;

    return AuthRegistrationResult(
      userId: 'user-456',
      email: email,
      session: session,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> signOut() async {
    storedSession = null;
  }
}

void main() {
  test('memuatkan sesi Supabase yang aktif', () async {
    final repository = _FakeAuthSessionRepository()
      ..storedSession = AuthSession(
        isAuthenticated: true,
        userId: 'user-123',
        email: 'student@example.com',
        signedInAt: DateTime(2026, 7, 16),
      );

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.loadSession();

    final state = container.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.authenticated);

    expect(state.isAuthenticated, isTrue);
    expect(state.session.userId, 'user-123');
  });

  test('log masuk menggunakan e-mel dan kata laluan', () async {
    final repository = _FakeAuthSessionRepository();

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.signInWithPassword(
      email: 'student@example.com',
      password: 'password123',
    );

    final state = container.read(authSessionControllerProvider);

    expect(state.isAuthenticated, isTrue);
    expect(state.session.email, 'student@example.com');
  });

  test('pendaftaran boleh memerlukan pengesahan e-mel', () async {
    final repository = _FakeAuthSessionRepository()
      ..requireEmailConfirmation = true;

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    final result = await controller.signUp(
      displayName: 'Pelajar Ujian',
      email: 'new@example.com',
      password: 'password123',
    );

    expect(result.requiresEmailConfirmation, isTrue);

    expect(
      container.read(authSessionControllerProvider).status,
      AuthSessionStatus.unauthenticated,
    );
  });

  test('log keluar memadam sesi semasa', () async {
    final repository = _FakeAuthSessionRepository();

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.signInWithPassword(
      email: 'student@example.com',
      password: 'password123',
    );

    await controller.signOut();

    final state = container.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.unauthenticated);

    expect(repository.storedSession, isNull);
  });
}
