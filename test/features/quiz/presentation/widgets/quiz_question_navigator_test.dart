import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_question_navigator.dart';

void main() {
  testWidgets('memaparkan status dan memilih nombor soalan', (tester) async {
    final questions = [
      QuizQuestion(
        id: 'q1',
        topicId: 'topic-1',
        questionText: 'Soalan pertama',
        options: const ['A', 'B'],
        correctOptionIndex: 0,
        explanation: 'Penerangan pertama',
      ),
      QuizQuestion(
        id: 'q2',
        topicId: 'topic-1',
        questionText: 'Soalan kedua',
        options: const ['A', 'B'],
        correctOptionIndex: 1,
        explanation: 'Penerangan kedua',
      ),
      QuizQuestion(
        id: 'q3',
        topicId: 'topic-1',
        questionText: 'Soalan ketiga',
        options: const ['A', 'B'],
        correctOptionIndex: 0,
        explanation: 'Penerangan ketiga',
      ),
    ];

    final state = QuizSessionState(
      status: QuizSessionStatus.ready,
      topicId: 'topic-1',
      mode: QuizMode.practice,
      requestedQuestionCount: 3,
      questions: questions,
      currentQuestionIndex: 1,
      selectedAnswers: const {'q1': 0},
      flaggedQuestionIds: const {'q2'},
    );

    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizQuestionNavigator(
            state: state,
            onClose: () {},
            onQuestionSelected: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Navigasi Soalan'), findsOneWidget);

    expect(find.text('1 dijawab'), findsOneWidget);

    expect(find.text('2 belum dijawab'), findsOneWidget);

    expect(find.text('1 ditanda'), findsOneWidget);

    final thirdQuestionButton = find.byKey(
      const ValueKey('quiz-question-nav-3'),
    );

    expect(thirdQuestionButton, findsOneWidget);

    await tester.tap(thirdQuestionButton);

    await tester.pump();

    expect(selectedIndex, 2);
  });
}
