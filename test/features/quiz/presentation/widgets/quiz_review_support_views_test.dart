import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_review_support_views.dart';

void main() {
  testWidgets('memaparkan ringkasan semakan jawapan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuizReviewSummaryCard(result: _buildResult())),
      ),
    );

    expect(find.byKey(const Key('quiz-review-summary-card')), findsOneWidget);

    expect(find.text('Ringkasan Semakan'), findsOneWidget);

    final correctItem = find.byKey(const Key('quiz-review-summary-correct'));

    final incorrectItem = find.byKey(
      const Key('quiz-review-summary-incorrect'),
    );

    final unansweredItem = find.byKey(
      const Key('quiz-review-summary-unanswered'),
    );

    expect(
      find.descendant(of: correctItem, matching: find.text('1')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: incorrectItem, matching: find.text('1')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: unansweredItem, matching: find.text('1')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: correctItem, matching: find.text('Betul')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: incorrectItem, matching: find.text('Salah')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: unansweredItem, matching: find.text('Tidak Dijawab')),
      findsOneWidget,
    );
  });

  testWidgets('memaparkan empty view untuk penapis tanpa jawapan', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuizReviewEmptyView())),
    );

    expect(find.byKey(const Key('quiz-review-empty-view')), findsOneWidget);

    expect(find.text('Tiada jawapan dalam kategori ini'), findsOneWidget);

    expect(
      find.text('Pilih penapis lain untuk melihat soalan.'),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}

QuizResult _buildResult() {
  return QuizResult(
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questions: _buildQuestions(),
    selectedAnswers: const {'question-1': 0, 'question-2': 0},
    correctAnswers: 1,
    answeredQuestions: 2,
    elapsedTime: const Duration(minutes: 2),
    autoSubmitted: false,
  );
}

List<QuizQuestion> _buildQuestions() {
  return [
    QuizQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan pertama?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 0,
      explanation: 'Pilihan A ialah jawapan betul.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan kedua?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Pilihan B ialah jawapan betul.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-3',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan ketiga?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Pilihan B ialah jawapan betul.',
      shuffleOptions: false,
    ),
  ];
}
