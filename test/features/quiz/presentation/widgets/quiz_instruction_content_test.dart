import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_instruction_content.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';

void main() {
  testWidgets('memaparkan arahan Practice Mode dan '
      'menjalankan callback mula', (tester) async {
    var startCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizInstructionContent(
          topic: _sampleTopic,
          mode: QuizMode.practice,
          questionCount: 10,
          isProcessing: false,
          onStart: () {
            startCount++;
          },
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-instruction-content')), findsOneWidget);

    expect(find.text('S1-01'), findsOneWidget);

    expect(find.text('Konsep Negara'), findsOneWidget);

    expect(find.text('Practice Mode'), findsOneWidget);

    expect(find.text('10 soalan'), findsOneWidget);

    expect(find.text('Tiada had masa'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-instruction-start-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-instruction-start-button')));

    await tester.pump();

    expect(startCount, 1);
  });

  testWidgets('memaparkan masa Exam Mode dan '
      'menyekat mula ketika processing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizInstructionContent(
          topic: _sampleTopic,
          mode: QuizMode.exam,
          questionCount: 20,
          isProcessing: true,
          onStart: () {},
        ),
      ),
    );

    expect(find.text('Exam Mode'), findsOneWidget);

    expect(find.text('20 soalan'), findsOneWidget);

    expect(find.text('30 minit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-instruction-start-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Memeriksa Sesi...'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-instruction-start-progress')),
      findsOneWidget,
    );

    final startButton = tester.widget<FilledButton>(
      find.byKey(const Key('quiz-instruction-start-button')),
    );

    expect(startButton.onPressed, isNull);
  });
}

const StudyTopic _sampleTopic = StudyTopic(
  id: 'topic-1',
  code: 'S1-01',
  semester: 1,
  title: 'Konsep Negara',
  description: 'Pengenalan kepada konsep negara.',
  questionCount: 20,
  completedQuestionCount: 5,
);
