import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/app.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_registration_result.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/entities/auth_session.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/domain/repositories/auth_session_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/authentication/presentation/controllers/auth_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/repositories/topics_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/widgets/topic_card.dart';

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

class _FakeTopicsRepository implements TopicsRepository {
  const _FakeTopicsRepository();

  @override
  Future<List<StudyTopic>> fetchTopics() async {
    return const [
      StudyTopic(
        id: 'topic-s1-01',
        code: 'S1-01',
        semester: 1,
        title: 'Kemahiran Insaniah',
        description: 'Kemahiran mencari dan menganalisis maklumat.',
        questionCount: 20,
        completedQuestionCount: 0,
      ),
      StudyTopic(
        id: 'topic-s1-02',
        code: 'S1-02',
        semester: 1,
        title: 'Negara Berdaulat',
        description: 'Konsep dan ciri negara berdaulat.',
        questionCount: 20,
        completedQuestionCount: 0,
      ),
    ];
  }
}

Widget _buildTestApp({AuthSession? initialSession}) {
  final authRepository = _FakeAuthSessionRepository()
    ..storedSession = initialSession;

  return ProviderScope(
    overrides: [
      authSessionRepositoryProvider.overrideWithValue(authRepository),
      topicsRepositoryProvider.overrideWithValue(const _FakeTopicsRepository()),
    ],
    child: const App(),
  );
}

Finder _findTopicCard(String topicTitle, {bool skipOffstage = true}) {
  return find.byWidgetPredicate(
    (widget) {
      return widget is TopicCard && widget.topic.title == topicTitle;
    },
    description: 'TopicCard untuk $topicTitle',
    skipOffstage: skipOffstage,
  );
}

void main() {
  testWidgets('splash membawa pengguna tanpa sesi ke login', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('Memuatkan aplikasi...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Log Masuk'), findsOneWidget);
  });

  testWidgets('splash membawa pengguna dengan sesi ke home', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initialSession: AuthSession(
          isAuthenticated: true,
          userId: 'existing-widget-user',
          email: 'existing@example.com',
          signedInAt: DateTime(2026, 7, 16),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Utama'), findsOneWidget);

    expect(find.text('Topik'), findsWidgets);

    expect(find.text('Kuiz'), findsWidgets);

    expect(find.text('Ranking'), findsWidgets);

    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('memaparkan borang log masuk', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);

    expect(find.text('E-mel'), findsOneWidget);

    expect(find.text('Kata laluan'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Log Masuk'), findsOneWidget);
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

  testWidgets('log masuk dan membuka topik daripada repository', (
    tester,
  ) async {
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

    // Fake authentication repository menyelesaikan
    // proses log masuk tanpa network request.
    await tester.pumpAndSettle();

    expect(find.text('Utama'), findsOneWidget);

    expect(find.byType(NavigationBar), findsOneWidget);

    final topicsNavigationLabel = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Topik'),
    );

    expect(topicsNavigationLabel, findsOneWidget);

    await tester.tap(topicsNavigationLabel);

    await tester.pumpAndSettle();

    expect(find.text('Topik Pembelajaran'), findsOneWidget);

    final kemahiranInsaniahCard = _findTopicCard(
      'Kemahiran Insaniah',
      skipOffstage: false,
    );

    expect(kemahiranInsaniahCard, findsOneWidget);

    final negaraBerdaulatCard = _findTopicCard(
      'Negara Berdaulat',
      skipOffstage: false,
    );

    expect(negaraBerdaulatCard, findsOneWidget);

    await tester.ensureVisible(negaraBerdaulatCard);

    await tester.pumpAndSettle();

    final visibleNegaraBerdaulatCard = _findTopicCard('Negara Berdaulat');

    expect(visibleNegaraBerdaulatCard, findsOneWidget);
  });
}
