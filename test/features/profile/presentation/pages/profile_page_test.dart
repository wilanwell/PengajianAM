import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pengajian_am_stpm_objektif/app/router/route_names.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_state.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/domain/entities/student_profile.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_state.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/pages/profile_page.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';

class _FakeProfileController extends ProfileController {
  _FakeProfileController({required this.profile});

  final StudentProfile profile;

  int loadCount = 0;
  int refreshCount = 0;

  @override
  ProfileState build() {
    return ProfileState(status: ProfileStatus.success, profile: profile);
  }

  @override
  Future<void> loadProfile({bool forceRefresh = false}) async {
    loadCount++;
  }

  @override
  Future<void> refreshProfile() async {
    refreshCount++;
  }
}

class _FakeMistakeBookController extends MistakeBookController {
  _FakeMistakeBookController({required this.snapshot});

  final MistakeBookSnapshot snapshot;

  int loadCount = 0;
  int refreshCount = 0;

  @override
  MistakeBookState build() {
    return MistakeBookState(
      status: MistakeBookStatus.success,
      snapshot: snapshot,
    );
  }

  @override
  Future<void> loadMistakeBook({bool forceRefresh = false}) async {
    loadCount++;
  }

  @override
  Future<void> refreshMistakeBook() async {
    refreshCount++;
  }
}

class _FakeUserProgressController extends UserProgressController {
  _FakeUserProgressController({required this.progress});

  final UserProgress progress;

  @override
  UserProgress build() {
    return progress;
  }
}

void main() {
  testWidgets('memaparkan ringkasan Buku Kesilapan dalam Profile', (
    tester,
  ) async {
    final profileController = _FakeProfileController(profile: _sampleProfile());

    final mistakeBookController = _FakeMistakeBookController(
      snapshot: _sampleMistakeBookSnapshot(),
    );

    final userProgressController = _FakeUserProgressController(
      progress: _sampleUserProgress(),
    );

    final router = _createRouter();

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => profileController),
          mistakeBookControllerProvider.overrideWith(
            () => mistakeBookController,
          ),
          userProgressControllerProvider.overrideWith(
            () => userProgressController,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final mistakeBookCard = find.byKey(const Key('profile-mistake-book-card'));

    await tester.scrollUntilVisible(
      mistakeBookCard,
      300,
      scrollable: _verticalPageScrollable(),
    );

    await tester.pumpAndSettle();

    expect(mistakeBookCard, findsOneWidget);

    expect(find.text('Buku Kesilapan'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-reviewable')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-mastered')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-archived')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    expect(find.text('25%'), findsOneWidget);

    expect(find.text('3 daripada 12 soalan telah dikuasai.'), findsOneWidget);

    expect(profileController.loadCount, 1);

    expect(mistakeBookController.loadCount, 1);
  });

  testWidgets('butang Buku Kesilapan membuka halaman yang betul', (
    tester,
  ) async {
    final profileController = _FakeProfileController(profile: _sampleProfile());

    final mistakeBookController = _FakeMistakeBookController(
      snapshot: _sampleMistakeBookSnapshot(),
    );

    final userProgressController = _FakeUserProgressController(
      progress: _sampleUserProgress(),
    );

    final router = _createRouter();

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => profileController),
          mistakeBookControllerProvider.overrideWith(
            () => mistakeBookController,
          ),
          userProgressControllerProvider.overrideWith(
            () => userProgressController,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final openButton = find.byKey(const Key('profile-mistake-book-open'));

    await tester.scrollUntilVisible(
      openButton,
      300,
      scrollable: _verticalPageScrollable(),
    );

    await tester.pumpAndSettle();

    await tester.tap(openButton);

    await tester.pumpAndSettle();

    expect(find.text('Halaman Buku Kesilapan'), findsOneWidget);
  });

  testWidgets('pull-to-refresh menyegarkan Profile dan Buku Kesilapan', (
    tester,
  ) async {
    final profileController = _FakeProfileController(profile: _sampleProfile());

    final mistakeBookController = _FakeMistakeBookController(
      snapshot: _sampleMistakeBookSnapshot(),
    );

    final userProgressController = _FakeUserProgressController(
      progress: _sampleUserProgress(),
    );

    final router = _createRouter();

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => profileController),
          mistakeBookControllerProvider.overrideWith(
            () => mistakeBookController,
          ),
          userProgressControllerProvider.overrideWith(
            () => userProgressController,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(profileController.loadCount, 1);

    expect(mistakeBookController.loadCount, 1);

    expect(profileController.refreshCount, 0);

    expect(mistakeBookController.refreshCount, 0);

    await tester.drag(_verticalPageScrollable(), const Offset(0, 450));

    await tester.pump();

    await tester.pumpAndSettle();

    expect(profileController.refreshCount, 1);

    expect(mistakeBookController.refreshCount, 1);
  });
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: RoutePaths.profile,
    routes: [
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) {
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: RoutePaths.mistakeBook,
        name: RouteNames.mistakeBook,
        builder: (context, state) {
          return const Scaffold(
            body: Center(child: Text('Halaman Buku Kesilapan')),
          );
        },
      ),
    ],
  );
}

Finder _verticalPageScrollable() {
  return find.byWidgetPredicate((widget) {
    return widget is Scrollable && widget.axisDirection == AxisDirection.down;
  });
}

StudentProfile _sampleProfile() {
  return StudentProfile(
    userId: 'user-1',
    displayName: 'Pelajar Ujian',
    email: 'pelajar@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime.utc(2026, 1, 1),
    totalXp: 1250,
    completedQuizzes: 12,
    averageScore: 78.5,
    completedTopics: 4,
    totalTopics: 10,
    currentStreakDays: 3,
    bestStreakDays: 7,
    weeklyAnsweredQuestions: const [5, 10, 8, 12, 6, 4, 3],
    achievements: const [],
  );
}

UserProgress _sampleUserProgress() {
  return UserProgress(
    userId: 'user-1',
    displayName: 'Pelajar Ujian',
    email: 'pelajar@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime.utc(2026, 1, 1),
    totalXp: 1250,
    weeklyXp: 140,
    monthlyXp: 520,
    completedQuizzes: 12,
    totalCorrectAnswers: 157,
    totalQuizQuestions: 200,
    highestScore: 95,
    completedTopics: 4,
    totalTopics: 10,
    currentStreakDays: 3,
    bestStreakDays: 7,
    weeklyAnsweredQuestions: const [5, 10, 8, 12, 6, 4, 3],
  );
}

MistakeBookSnapshot _sampleMistakeBookSnapshot() {
  return MistakeBookSnapshot(
    generatedAt: DateTime.utc(2026, 7, 28),
    needsReviewCount: 9,
    reviewableCount: 7,
    masteredCount: 3,
    topics: const [],
  );
}
