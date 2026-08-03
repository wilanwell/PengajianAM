import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_question_dialogs.dart';

void main() {
  testWidgets(
    'dialog keluar memaparkan ringkasan dan mengembalikan saveAndExit',
    (tester) async {
      QuizExitAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      selectedAction = await QuizQuestionDialogs.showExitDialog(
                        context: context,
                        state: _buildState(),
                      );
                    },
                    child: const Text('Buka Dialog Keluar'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog Keluar'));

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quiz-exit-dialog')), findsOneWidget);

      expect(
        find.textContaining('1 daripada 2 soalan telah dijawab'),
        findsOneWidget,
      );

      expect(find.textContaining('1 soalan belum dijawab'), findsOneWidget);

      expect(find.textContaining('1 soalan ditanda'), findsOneWidget);

      await tester.tap(find.byKey(const Key('quiz-exit-save-button')));

      await tester.pumpAndSettle();

      expect(selectedAction, QuizExitAction.saveAndExit);
    },
  );

  testWidgets('dialog hantar mengembalikan true selepas pengesahan', (
    tester,
  ) async {
    bool? shouldSubmit;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    shouldSubmit = await QuizQuestionDialogs.showSubmitDialog(
                      context: context,
                      state: _buildState(),
                    );
                  },
                  child: const Text('Buka Dialog Hantar'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Buka Dialog Hantar'));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-submit-dialog')), findsOneWidget);

    expect(find.text('Hantar Jawapan?'), findsOneWidget);

    expect(find.text('Semak Semula'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-submit-confirm-button')));

    await tester.pumpAndSettle();

    expect(shouldSubmit, isTrue);
  });

  testWidgets(
    'dialog hantar mengembalikan false apabila semak semula dipilih',
    (tester) async {
      bool? shouldSubmit;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      shouldSubmit = await QuizQuestionDialogs.showSubmitDialog(
                        context: context,
                        state: _buildState(),
                      );
                    },
                    child: const Text('Buka Pengesahan'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Pengesahan'));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quiz-submit-review-button')));

      await tester.pumpAndSettle();

      expect(shouldSubmit, isFalse);
    },
  );

  testWidgets('memaparkan Snackbar ketika submission sedang berlangsung', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () {
                  QuizQuestionDialogs.showSubmittingMessage(context);
                },
                child: const Text('Tunjuk Snackbar'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Tunjuk Snackbar'));

    await tester.pump();

    expect(find.byKey(const Key('quiz-submitting-snackbar')), findsOneWidget);

    expect(
      find.text(
        'Jawapan sedang dihantar. '
        'Sila tunggu sebentar.',
      ),
      findsOneWidget,
    );
  });
}

QuizSessionState _buildState() {
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
    selectedAnswers: const {'question-1': 0},
    flaggedQuestionIds: const {'question-2'},
  );
}
