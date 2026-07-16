import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_question_navigator.dart';

void main() {
  testWidgets('memaparkan status dan memilih nombor soalan', (tester) async {
    final questions = [
      QuizSessionQuestion(
        id: 'q1',
        topicId: 'topic-1',
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 1,
      ),
      QuizSessionQuestion(
        id: 'q2',
        topicId: 'topic-1',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 2,
      ),
      QuizSessionQuestion(
        id: 'q3',
        topicId: 'topic-1',
        questionText: 'Soalan ketiga',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 3,
      ),
    ];

    final state = QuizSessionState(
      status: QuizSessionStatus.ready,
      sessionId: '00000000-0000-0000-0000-000000000001',
      topicId: 'topic-1',
      mode: QuizMode.practice,
      requestedQuestionCount: 3,
      questions: questions,
      currentQuestionIndex: 1,
      selectedAnswers: const {'q1': 0},
      flaggedQuestionIds: const {'q2'},
      sessionExpiresAt: DateTime(2026, 7, 16, 12),
    );

    int? selectedIndex;
    var closeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizQuestionNavigator(
            state: state,
            onClose: () {
              closeCalled = true;
            },
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

    final firstQuestionButton = find.byKey(
      const ValueKey('quiz-question-nav-1'),
    );

    final secondQuestionButton = find.byKey(
      const ValueKey('quiz-question-nav-2'),
    );

    final thirdQuestionButton = find.byKey(
      const ValueKey('quiz-question-nav-3'),
    );

    expect(firstQuestionButton, findsOneWidget);

    expect(secondQuestionButton, findsOneWidget);

    expect(thirdQuestionButton, findsOneWidget);

    await tester.tap(thirdQuestionButton);

    await tester.pump();

    expect(selectedIndex, 2);

    final closeButton = find.byTooltip('Tutup');

    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);

    await tester.pump();

    expect(closeCalled, isTrue);
  });
}
