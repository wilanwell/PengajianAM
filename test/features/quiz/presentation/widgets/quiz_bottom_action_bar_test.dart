import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_bottom_action_bar.dart';

void main() {
  testWidgets(
    'memaparkan regular actions dan menjalankan callback next serta flag',
    (tester) async {
      var previousCount = 0;
      var nextCount = 0;
      var flagCount = 0;
      var submitCount = 0;

      await tester.binding.setSurfaceSize(const Size(800, 600));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomActionBar(
                state: _buildState(currentQuestionIndex: 0),
                onPrevious: () {
                  previousCount++;
                },
                onNext: () {
                  nextCount++;
                },
                onToggleFlag: () {
                  flagCount++;
                },
                onSubmit: () {
                  submitCount++;
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('quiz-bottom-actions-regular')),
        findsOneWidget,
      );

      expect(find.text('Sebelum'), findsOneWidget);

      expect(find.text('Seterusnya'), findsOneWidget);

      final previousButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('quiz-previous-button')),
      );

      expect(previousButton.onPressed, isNull);

      await tester.tap(find.byKey(const Key('quiz-flag-button')));

      await tester.tap(find.byKey(const Key('quiz-next-button')));

      expect(flagCount, 1);
      expect(nextCount, 1);
      expect(previousCount, 0);
      expect(submitCount, 0);
    },
  );

  testWidgets('memaparkan Hantar pada soalan terakhir', (tester) async {
    var previousCount = 0;
    var nextCount = 0;
    var submitCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 600));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: QuizBottomActionBar(
              state: _buildState(currentQuestionIndex: 1, isFlagged: true),
              onPrevious: () {
                previousCount++;
              },
              onNext: () {
                nextCount++;
              },
              onToggleFlag: () {},
              onSubmit: () {
                submitCount++;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hantar'), findsOneWidget);

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

    final previousButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('quiz-previous-button')),
    );

    expect(previousButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('quiz-previous-button')));

    await tester.tap(find.byKey(const Key('quiz-next-button')));

    expect(previousCount, 1);
    expect(submitCount, 1);
    expect(nextCount, 0);
  });

  testWidgets('menggunakan compact actions pada skrin sempit', (tester) async {
    var nextCount = 0;

    await tester.binding.setSurfaceSize(const Size(320, 600));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: QuizBottomActionBar(
              state: _buildState(currentQuestionIndex: 0),
              onPrevious: () {},
              onNext: () {
                nextCount++;
              },
              onToggleFlag: () {},
              onSubmit: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('quiz-bottom-actions-compact')),
      findsOneWidget,
    );

    expect(find.text('Sebelum'), findsNothing);

    expect(find.text('Seterusnya'), findsNothing);

    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-next-button')));

    expect(nextCount, 1);
  });

  testWidgets('menggunakan compact actions apabila saiz teks besar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomActionBar(
                state: _buildState(currentQuestionIndex: 0),
                onPrevious: () {},
                onNext: () {},
                onToggleFlag: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('quiz-bottom-actions-compact')),
      findsOneWidget,
    );
  });
}

QuizSessionState _buildState({
  required int currentQuestionIndex,
  bool isFlagged = false,
}) {
  final questions = [
    QuizSessionQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Soalan kedua',
      options: ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];

  return QuizSessionState(
    status: QuizSessionStatus.ready,
    questions: questions,
    currentQuestionIndex: currentQuestionIndex,
    flaggedQuestionIds: isFlagged
        ? {questions[currentQuestionIndex].id}
        : const {},
  );
}
