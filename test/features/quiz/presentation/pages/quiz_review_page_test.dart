import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/pages/quiz_review_page.dart';

void main() {
  testWidgets('memaparkan dan menapis semakan jawapan', (tester) async {
    final firstQuestion = QuizQuestion(
      id: 'q1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: const ['Jawapan A', 'Jawapan B'],
      correctOptionIndex: 0,
      explanation: 'Penerangan pertama',
    );

    final secondQuestion = QuizQuestion(
      id: 'q2',
      topicId: 'topic-1',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Penerangan kedua',
    );

    final result = QuizResult(
      topicId: 'topic-1',
      mode: QuizMode.practice,
      questions: [firstQuestion, secondQuestion],
      selectedAnswers: const {'q1': 0, 'q2': 0},
      correctAnswers: 1,
      answeredQuestions: 2,
      elapsedTime: const Duration(minutes: 2),
      autoSubmitted: false,
    );

    await tester.pumpWidget(MaterialApp(home: QuizReviewPage(result: result)));

    await tester.pumpAndSettle();

    expect(find.text('Semakan Jawapan'), findsOneWidget);

    // skipOffstage: false memastikan item yang berada di bawah
    // kawasan skrin test masih boleh dikesan.
    expect(find.text('Soalan pertama', skipOffstage: false), findsOneWidget);

    expect(find.text('Soalan kedua', skipOffstage: false), findsOneWidget);

    final incorrectFilter = find.widgetWithText(FilterChip, 'Salah');

    expect(incorrectFilter, findsOneWidget);

    await tester.ensureVisible(incorrectFilter);
    await tester.pumpAndSettle();

    await tester.tap(incorrectFilter);
    await tester.pumpAndSettle();

    // Soalan pertama dijawab betul, jadi ia tidak patut berada
    // dalam senarai selepas penapis Salah dipilih.
    expect(find.text('Soalan pertama', skipOffstage: false), findsNothing);

    // Soalan kedua dijawab salah dan mesti kekal dalam senarai.
    expect(find.text('Soalan kedua', skipOffstage: false), findsOneWidget);
  });
}
