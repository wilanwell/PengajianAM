import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/home/domain/entities/home_summary.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/widgets/home_page_content.dart';

void main() {
  testWidgets('memaparkan ringkasan dan menyalurkan callback Home', (
    tester,
  ) async {
    var topicsCount = 0;
    var quizCount = 0;
    var leaderboardCount = 0;
    var mistakeBookCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePageContent(
            summary: _sampleSummary(),
            onRefresh: () async {},
            onOpenTopics: () {
              topicsCount++;
            },
            onStartQuiz: () {
              quizCount++;
            },
            onOpenLeaderboard: () {
              leaderboardCount++;
            },
            onOpenMistakeBook: () {
              mistakeBookCount++;
            },
          ),
        ),
      ),
    );

    expect(find.text('Hai, Pelajar Ujian!'), findsOneWidget);

    expect(find.text('Semester 1'), findsWidgets);

    expect(find.text('Kuiz Disiapkan'), findsOneWidget);

    expect(find.text('12'), findsOneWidget);

    expect(find.text('79%'), findsOneWidget);

    expect(find.text('1250'), findsOneWidget);

    expect(find.text('#8'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    Future<void> tapItem(String key) async {
      final finder = find.byKey(Key(key));

      await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);

      await tester.tap(finder);
      await tester.pump();
    }

    await tapItem('home-semester-overview');

    await tapItem('home-weekly-ranking-card');

    await tapItem('home-quick-topics');

    await tapItem('home-quick-quiz');

    await tapItem('home-quick-leaderboard');

    await tapItem('home-quick-mistake-book');

    expect(topicsCount, 2);

    expect(quizCount, 1);

    expect(leaderboardCount, 2);

    expect(mistakeBookCount, 1);
  });

  testWidgets('pull-to-refresh menjalankan callback refresh', (tester) async {
    var refreshCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePageContent(
            summary: _sampleSummary(),
            onRefresh: () async {
              refreshCount++;
            },
            onOpenTopics: () {},
            onStartQuiz: () {},
            onOpenLeaderboard: () {},
            onOpenMistakeBook: () {},
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 450));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });
}

HomeSummary _sampleSummary() {
  return const HomeSummary(
    displayName: 'Pelajar Ujian',
    semesterLabel: 'Semester 1',
    completedQuizzes: 12,
    averageScore: 78.5,
    totalXp: 1250,
    weeklyRank: 8,
    currentTopic: 'Perlembagaan Persekutuan',
    currentTopicProgress: 0.6,
    completedTopics: 4,
    totalTopics: 10,
  );
}
