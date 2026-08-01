import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_result_statistics_grid.dart';

void main() {
  testWidgets('memaparkan semua statistik keputusan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuizResultStatisticsGrid(result: _buildResult())),
      ),
    );

    expect(find.byKey(const Key('quiz-result-statistics')), findsOneWidget);

    expect(find.byKey(const Key('quiz-result-correct-stat')), findsOneWidget);

    expect(find.byKey(const Key('quiz-result-incorrect-stat')), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-result-unanswered-stat')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('quiz-result-time-stat')), findsOneWidget);

    expect(find.text('Betul'), findsOneWidget);

    expect(find.text('Salah'), findsOneWidget);

    expect(find.text('Tidak Dijawab'), findsOneWidget);

    expect(find.text('Masa Digunakan'), findsOneWidget);

    expect(find.text('01:05'), findsOneWidget);
  });

  testWidgets('memaparkan nilai pada kad statistik yang betul', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuizResultStatisticsGrid(result: _buildResult())),
      ),
    );

    final correctCard = find.byKey(const Key('quiz-result-correct-stat'));

    final incorrectCard = find.byKey(const Key('quiz-result-incorrect-stat'));

    final unansweredCard = find.byKey(const Key('quiz-result-unanswered-stat'));

    expect(
      find.descendant(of: correctCard, matching: find.text('1')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: incorrectCard, matching: find.text('0')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: unansweredCard, matching: find.text('1')),
      findsOneWidget,
    );
  });
}

QuizResult _buildResult() {
  return QuizResult(
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Konsep Negara',
    mode: QuizMode.practice,
    questions: _buildQuestions(),
    selectedAnswers: const {'question-1': 1},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 10,
    elapsedTime: const Duration(minutes: 1, seconds: 5),
    autoSubmitted: false,
  );
}

List<QuizQuestion> _buildQuestions() {
  return [
    QuizQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Apakah jawapan yang betul?',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Pilihan B ialah jawapan betul.',
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
  ];
}
