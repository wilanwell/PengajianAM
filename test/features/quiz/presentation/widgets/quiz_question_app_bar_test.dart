import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_question_app_bar.dart';

void main() {
  testWidgets('memaparkan tajuk, navigator, badge dan timer', (tester) async {
    var navigatorCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: QuizQuestionAppBar(
            title: 'Mod Latihan',
            showQuestionNavigator: true,
            unansweredQuestionCount: 3,
            remainingTimeLabel: '12:34',
            onOpenQuestionNavigator: () {
              navigatorCount++;
            },
          ),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-question-app-bar')), findsOneWidget);

    expect(find.text('Mod Latihan'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-question-navigator-button')),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    expect(find.text('3'), findsOneWidget);

    expect(find.text('12:34'), findsOneWidget);

    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-question-navigator-button')));

    expect(navigatorCount, 1);
  });

  testWidgets('menyembunyikan navigator dan timer apabila tidak diperlukan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: QuizQuestionAppBar(
            title: 'Memuatkan Kuiz',
            showQuestionNavigator: false,
            unansweredQuestionCount: 0,
            onOpenQuestionNavigator: () {},
          ),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.text('Memuatkan Kuiz'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-question-navigator-button')),
      findsNothing,
    );

    expect(find.byKey(const Key('quiz-question-timer')), findsNothing);
  });

  testWidgets('menyembunyikan label badge apabila semua soalan dijawab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: QuizQuestionAppBar(
            title: 'Mod Peperiksaan',
            showQuestionNavigator: true,
            unansweredQuestionCount: 0,
            onOpenQuestionNavigator: () {},
          ),
          body: const SizedBox(),
        ),
      ),
    );

    final badge = tester.widget<Badge>(
      find.byKey(const Key('quiz-question-unanswered-badge')),
    );

    expect(badge.isLabelVisible, isFalse);

    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });

  testWidgets('memaparkan timer tanpa navigator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: QuizQuestionAppBar(
            title: 'Menghantar Jawapan',
            showQuestionNavigator: false,
            unansweredQuestionCount: 0,
            remainingTimeLabel: '00:10',
            onOpenQuestionNavigator: () {},
          ),
          body: const SizedBox(),
        ),
      ),
    );

    expect(
      find.byKey(const Key('quiz-question-navigator-button')),
      findsNothing,
    );

    expect(find.text('00:10'), findsOneWidget);
  });
}
