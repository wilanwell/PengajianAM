import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_setup_state.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_hub_content.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';

void main() {
  testWidgets('memaparkan setup dan menyalurkan callback Quiz Hub', (
    tester,
  ) async {
    String? selectedTopicId;
    QuizMode? selectedMode;
    int? selectedQuestionCount;
    var continueCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1500));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizHubContent(
            topics: _sampleTopics(),
            setupState: const QuizSetupState(
              selectedTopicId: 'topic-1',
              mode: QuizMode.practice,
              questionCount: 10,
            ),
            questionCounts: const [10, 20],
            onTopicChanged: (topicId) {
              selectedTopicId = topicId;
            },
            onModeChanged: (mode) {
              selectedMode = mode;
            },
            onQuestionCountChanged: (count) {
              selectedQuestionCount = count;
            },
            onContinue: () {
              continueCount++;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-hub-hero-card')), findsOneWidget);

    expect(find.text('Sediakan Kuiz'), findsOneWidget);

    expect(find.text('Konsep Negara'), findsOneWidget);

    expect(find.text('Practice Mode'), findsAtLeastNWidgets(2));

    expect(find.text('10 soalan'), findsAtLeastNWidgets(2));

    expect(find.text('Tiada had masa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-hub-mode-exam')));

    await tester.pump();

    expect(selectedMode, QuizMode.exam);

    await tester.tap(find.byKey(const Key('quiz-hub-count-20')));

    await tester.pump();

    expect(selectedQuestionCount, 20);

    await tester.tap(find.byKey(const Key('quiz-hub-topic-dropdown')));

    await tester.pumpAndSettle();

    await tester.tap(find.text('S1-02 · Sistem Kerajaan').last);

    await tester.pumpAndSettle();

    expect(selectedTopicId, 'topic-2');

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-hub-continue-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-hub-continue-button')));

    await tester.pump();

    expect(continueCount, 1);
  });

  testWidgets('mengabaikan topic id tidak sah dan menyekat continue', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizHubContent(
            topics: _sampleTopics(),
            setupState: const QuizSetupState(
              selectedTopicId: 'topic-tidak-wujud',
            ),
            questionCounts: const [10, 20],
            onTopicChanged: (_) {},
            onModeChanged: (_) {},
            onQuestionCountChanged: (_) {},
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.text('Belum dipilih'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-hub-selected-topic-description')),
      findsNothing,
    );

    final continueButton = tester.widget<FilledButton>(
      find.byKey(const Key('quiz-hub-continue-button')),
    );

    expect(continueButton.onPressed, isNull);
  });
}

List<StudyTopic> _sampleTopics() {
  return const [
    StudyTopic(
      id: 'topic-1',
      code: 'S1-01',
      semester: 1,
      title: 'Konsep Negara',
      description: 'Pengenalan kepada konsep negara.',
      questionCount: 10,
      completedQuestionCount: 0,
    ),
    StudyTopic(
      id: 'topic-2',
      code: 'S1-02',
      semester: 1,
      title: 'Sistem Kerajaan',
      description: 'Struktur dan sistem kerajaan.',
      questionCount: 20,
      completedQuestionCount: 5,
    ),
  ];
}
