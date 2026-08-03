import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_question_content.dart';

void main() {
  testWidgets('memaparkan soalan, progress dan pilihan jawapan', (
    tester,
  ) async {
    int? selectedAnswer;
    var navigatorCount = 0;
    var flagCount = 0;
    var nextCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1000));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizQuestionContent(
            state: _buildReadyState(),
            onAnswerSelected: (index) {
              selectedAnswer = index;
            },
            onPrevious: () {},
            onNext: () {
              nextCount++;
            },
            onToggleFlag: () {
              flagCount++;
            },
            onOpenNavigator: () {
              navigatorCount++;
            },
            onSubmit: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-question-content')), findsOneWidget);

    expect(find.text('Soalan 1 daripada 2'), findsOneWidget);

    expect(find.text('1 dijawab'), findsOneWidget);

    expect(
      find.text(
        'Semak Semua Soalan '
        '(1 belum dijawab)',
      ),
      findsOneWidget,
    );

    expect(find.text('Apakah maksud kedaulatan?'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-current-question-flagged')),
      findsOneWidget,
    );

    expect(find.text('Ditanda'), findsOneWidget);

    expect(find.text('Kuasa tertinggi'), findsOneWidget);

    expect(find.text('Pembahagian kuasa'), findsOneWidget);

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-open-navigator-button')));

    await tester.tap(find.text('Kuasa tertinggi'));

    await tester.tap(find.byKey(const Key('quiz-flag-button')));

    await tester.tap(find.byKey(const Key('quiz-next-button')));

    expect(navigatorCount, 1);
    expect(selectedAnswer, 0);
    expect(flagCount, 1);
    expect(nextCount, 1);
  });

  testWidgets('memaparkan mesej apabila soalan tidak tersedia', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizQuestionContent(
            state: const QuizSessionState(status: QuizSessionStatus.ready),
            onAnswerSelected: (_) {},
            onPrevious: () {},
            onNext: () {},
            onToggleFlag: () {},
            onOpenNavigator: () {},
            onSubmit: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('quiz-question-unavailable-view')),
      findsOneWidget,
    );

    expect(find.text('Soalan tidak tersedia.'), findsOneWidget);

    expect(find.byKey(const Key('quiz-bottom-action-bar')), findsNothing);
  });

  testWidgets('memaparkan butang Hantar pada soalan terakhir', (tester) async {
    var submitCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1000));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizQuestionContent(
            state: _buildReadyState(currentQuestionIndex: 1),
            onAnswerSelected: (_) {},
            onPrevious: () {},
            onNext: () {},
            onToggleFlag: () {},
            onOpenNavigator: () {},
            onSubmit: () {
              submitCount++;
            },
          ),
        ),
      ),
    );

    expect(find.text('Hantar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-next-button')));

    expect(submitCount, 1);
  });
}

QuizSessionState _buildReadyState({int currentQuestionIndex = 0}) {
  final questions = [
    QuizSessionQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Apakah maksud kedaulatan?',
      options: const ['Kuasa tertinggi', 'Pembahagian kuasa'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Apakah bentuk kerajaan?',
      options: const ['Persekutuan', 'Kesatuan'],
      questionOrder: 2,
    ),
  ];

  return QuizSessionState(
    status: QuizSessionStatus.ready,
    questions: questions,
    currentQuestionIndex: currentQuestionIndex,
    selectedAnswers: const {'question-1': 1},
    flaggedQuestionIds: const {'question-1'},
  );
}
