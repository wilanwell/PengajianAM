import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_result_support_cards.dart';

void main() {
  testWidgets('memaparkan maklumat latihan semula', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QuizResultMistakeReviewInfoCard()),
      ),
    );

    expect(find.text('Fokus Penguasaan'), findsOneWidget);

    expect(
      find.textContaining('tidak menambah XP atau ranking'),
      findsOneWidget,
    );

    expect(find.textContaining('Perlu Dijawab Semula'), findsOneWidget);

    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });

  testWidgets('memaparkan jumlah XP yang diperoleh', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QuizResultEarnedXpCard(earnedXp: 35)),
      ),
    );

    expect(find.text('XP Diperoleh'), findsOneWidget);

    expect(find.text('+35 XP'), findsOneWidget);

    expect(find.byKey(const Key('quiz-result-earned-xp')), findsOneWidget);

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('memaparkan statistik keputusan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuizResultStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Betul',
            value: '8',
            color: Colors.green,
            backgroundColor: Colors.greenAccent,
          ),
        ),
      ),
    );

    expect(find.text('8'), findsOneWidget);

    expect(find.text('Betul'), findsOneWidget);

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
