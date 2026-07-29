import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_state.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/domain/entities/student_profile.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/widgets/profile_page_content.dart';

void main() {
  testWidgets('menyalurkan callback menu Profile', (tester) async {
    var analyticsCount = 0;
    var historyCount = 0;
    var settingsCount = 0;
    var aboutCount = 0;
    var logoutCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePageContent(
            profile: _sampleProfile(),
            mistakeBookState: _sampleMistakeBookState(),
            isLoggingOut: false,
            onRefresh: () async {},
            onEditName: () {},
            onOpenMistakeBook: () {},
            onRetryMistakeBook: () {},
            onOpenAnalytics: () {
              analyticsCount++;
            },
            onOpenQuizHistory: () {
              historyCount++;
            },
            onOpenSettings: () {
              settingsCount++;
            },
            onShowAbout: () {
              aboutCount++;
            },
            onLogout: () {
              logoutCount++;
            },
          ),
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;

    Future<void> tapMenu(String key) async {
      final finder = find.byKey(Key(key));

      await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);

      await tester.tap(finder);
      await tester.pump();
    }

    await tapMenu('profile-analytics-menu');

    await tapMenu('profile-quiz-history-menu');

    await tapMenu('profile-settings-menu');

    await tapMenu('profile-about-menu');

    await tapMenu('profile-logout-menu');

    expect(analyticsCount, 1);
    expect(historyCount, 1);
    expect(settingsCount, 1);
    expect(aboutCount, 1);
    expect(logoutCount, 1);
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

MistakeBookState _sampleMistakeBookState() {
  return MistakeBookState(
    status: MistakeBookStatus.success,
    snapshot: MistakeBookSnapshot(
      generatedAt: DateTime.utc(2026, 7, 29),
      needsReviewCount: 9,
      reviewableCount: 7,
      masteredCount: 3,
      topics: const [],
    ),
  );
}
