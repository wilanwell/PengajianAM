import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_session.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/repositories/auth_session_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_state.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthSession? storedSession;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<AuthSession?> loadSession() async {
    return storedSession;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    storedSession = session;
    saveCallCount++;
  }

  @override
  Future<void> clearSession() async {
    storedSession = null;
    clearCallCount++;
  }
}

void main() {
  test('menyimpan dan memuatkan sesi log masuk', () async {
    final repository = _FakeAuthSessionRepository();

    final firstContainer = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    final firstController = firstContainer.read(
      authSessionControllerProvider.notifier,
    );

    await firstController.signIn();

    var state = firstContainer.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.authenticated);

    expect(state.isAuthenticated, isTrue);

    expect(repository.storedSession, isNotNull);

    expect(repository.saveCallCount, 1);

    firstContainer.dispose();

    final secondContainer = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(secondContainer.dispose);

    final secondController = secondContainer.read(
      authSessionControllerProvider.notifier,
    );

    await secondController.loadSession();

    state = secondContainer.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.authenticated);

    expect(state.isAuthenticated, isTrue);
  });

  test('mengembalikan status unauthenticated jika sesi tiada', () async {
    final repository = _FakeAuthSessionRepository();

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.loadSession();

    final state = container.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.unauthenticated);

    expect(state.isAuthenticated, isFalse);
  });

  test('memadam sesi apabila pengguna log keluar', () async {
    final repository = _FakeAuthSessionRepository()
      ..storedSession = AuthSession(
        isAuthenticated: true,
        signedInAt: DateTime(2026, 7, 16),
      );

    final container = ProviderContainer(
      overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.loadSession();

    expect(
      container.read(authSessionControllerProvider).isAuthenticated,
      isTrue,
    );

    await controller.signOut();

    final state = container.read(authSessionControllerProvider);

    expect(state.status, AuthSessionStatus.unauthenticated);

    expect(state.isAuthenticated, isFalse);

    expect(repository.storedSession, isNull);

    expect(repository.clearCallCount, 1);
  });
}
