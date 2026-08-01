import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_result_summary_card.dart';

void main() {
  testWidgets('memaparkan ringkasan keputusan lulus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizResultSummaryCard(
            result: _buildResult(correctAnswers: 1, answeredQuestions: 2),
          ),
        ),
      ),
    );

    expect(find.text('1/2'), findsOneWidget);

    expect(find.text('50%'), findsOneWidget);

    expect(find.text('Bagus!'), findsOneWidget);

    expect(find.text('Kuiz anda telah berjaya dihantar.'), findsOneWidget);
  });

  testWidgets('memaparkan ringkasan auto submit yang gagal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizResultSummaryCard(
            result: _buildResult(
              correctAnswers: 0,
              answeredQuestions: 0,
              autoSubmitted: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0/2'), findsOneWidget);

    expect(find.text('0%'), findsOneWidget);

    expect(find.text('Teruskan Berusaha'), findsOneWidget);

    expect(
      find.text(
        'Masa tamat dan kuiz telah '
        'dihantar secara automatik.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('memaparkan ringkasan latihan semula', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizResultSummaryCard(
            result: _buildResult(
              correctAnswers: 1,
              answeredQuestions: 1,
              sessionSource: QuizSessionSource.mistakeReview,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Latihan Selesai'), findsOneWidget);

    expect(
      find.text(
        'Status Buku Kesilapan '
        'anda telah dikemas kini.',
      ),
      findsOneWidget,
    );
  });
}

QuizResult _buildResult({
  required int correctAnswers,
  required int answeredQuestions,
  bool autoSubmitted = false,
  QuizSessionSource sessionSource = QuizSessionSource.standard,
}) {
  return QuizResult(
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Konsep Negara',
    mode: QuizMode.practice,
    sessionSource: sessionSource,
    questions: _buildQuestions(),
    selectedAnswers: const {},
    correctAnswers: correctAnswers,
    answeredQuestions: answeredQuestions,
    earnedXp: 0,
    elapsedTime: const Duration(seconds: 30),
    autoSubmitted: autoSubmitted,
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
