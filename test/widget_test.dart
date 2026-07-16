import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/app.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_session.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/repositories/auth_session_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_registration_result.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthSession? storedSession;

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
      userId: 'widget-user',
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
    final session = AuthSession(
      isAuthenticated: true,
      userId: 'widget-user',
      email: email,
      signedInAt: DateTime(2026, 7, 16),
    );

    storedSession = session;

    return AuthRegistrationResult(
      userId: session.userId!,
      email: email,
      session: session,
    );
  }

  @override
  Future<void> signOut() async {
    storedSession = null;
  }
}

Widget _buildTestApp({AuthSession? initialSession}) {
  final repository = _FakeAuthSessionRepository()
    ..storedSession = initialSession;

  return ProviderScope(
    overrides: [authSessionRepositoryProvider.overrideWithValue(repository)],
    child: const App(),
  );
}

void main() {
  testWidgets('splash membawa pengguna tanpa sesi ke login', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('Memuatkan aplikasi...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);

    expect(find.text('Log Masuk'), findsOneWidget);
  });

  testWidgets('splash membawa pengguna dengan sesi ke home', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initialSession: AuthSession(
          isAuthenticated: true,
          signedInAt: DateTime(2026, 7, 16),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Utama'), findsOneWidget);

    expect(find.text('Topik'), findsOneWidget);

    expect(find.text('Kuiz'), findsOneWidget);

    expect(find.text('Ranking'), findsOneWidget);

    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('memaparkan borang log masuk', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);

    expect(find.text('E-mel'), findsOneWidget);

    expect(find.text('Kata laluan'), findsOneWidget);

    expect(find.text('Log Masuk'), findsOneWidget);
  });

  testWidgets('membuka halaman pendaftaran', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    final registerButton = find.widgetWithText(OutlinedButton, 'Daftar Akaun');

    expect(registerButton, findsOneWidget);

    await tester.ensureVisible(registerButton);

    await tester.pumpAndSettle();

    await tester.tap(registerButton);

    await tester.pumpAndSettle();

    expect(find.text('Cipta Akaun'), findsOneWidget);

    expect(find.text('Sahkan kata laluan'), findsOneWidget);
  });

  testWidgets('log masuk dan membuka navigasi utama', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);

    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'student@email.com');

    await tester.enterText(textFields.at(1), '123456');

    final loginButton = find.widgetWithText(FilledButton, 'Log Masuk');

    expect(loginButton, findsOneWidget);

    await tester.ensureVisible(loginButton);

    await tester.pumpAndSettle();

    await tester.tap(loginButton);

    await tester.pump();

    // Mock login menggunakan delay 600 milisaat.
    await tester.pump(const Duration(milliseconds: 700));

    await tester.pumpAndSettle();

    expect(find.text('Utama'), findsOneWidget);

    expect(find.text('Topik'), findsOneWidget);

    expect(find.text('Kuiz'), findsOneWidget);

    expect(find.text('Ranking'), findsOneWidget);

    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Topik'));

    await tester.pumpAndSettle();

    expect(find.text('Topik Pembelajaran'), findsOneWidget);
  });
}
