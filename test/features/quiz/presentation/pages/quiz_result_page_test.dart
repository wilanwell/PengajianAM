import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/pages/quiz_result_page.dart';

void main() {
  testWidgets('keputusan latihan semula tidak memaparkan ganjaran XP', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: QuizResultPage(result: _mistakeReviewResult()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Keputusan Latihan Semula'), findsOneWidget);
    expect(find.text('Latihan Selesai'), findsOneWidget);
    expect(find.text('Fokus Penguasaan'), findsOneWidget);
    expect(
      find.textContaining('tidak menambah XP atau ranking'),
      findsOneWidget,
    );
    expect(find.text('XP Diperoleh'), findsNothing);

    final returnButton = find.text('Kembali ke Topik Buku Kesilapan');

    await tester.scrollUntilVisible(
      returnButton,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(returnButton, findsOneWidget);
  });
}

QuizResult _mistakeReviewResult() {
  return QuizResult(
    topicId: 'topic-s1-01',
    topicCode: 'S1-01',
    topicTitle: 'Kemahiran Insaniah',
    mode: QuizMode.practice,
    sessionSource: QuizSessionSource.mistakeReview,
    questions: [
      QuizQuestion(
        id: 'question-1',
        topicId: 'topic-s1-01',
        questionText: 'Apakah jawapan yang betul?',
        options: const ['Pilihan A', 'Pilihan B'],
        correctOptionIndex: 1,
        explanation: 'Pilihan B ialah jawapan yang betul.',
        shuffleOptions: false,
      ),
    ],
    selectedAnswers: const {'question-1': 1},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 0,
    elapsedTime: const Duration(seconds: 25),
    autoSubmitted: false,
  );
}
