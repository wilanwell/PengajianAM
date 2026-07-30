import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_state.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/widgets/topics_page_content.dart';

void main() {
  testWidgets('memaparkan summary dan menyalurkan callback Topics', (
    tester,
  ) async {
    final searchController = TextEditingController();

    addTearDown(searchController.dispose);

    String? searchValue;
    TopicProgressFilter? selectedFilter;
    StudyTopic? selectedTopic;

    await tester.binding.setSurfaceSize(const Size(800, 1500));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicsPageContent(
            state: TopicsState(
              status: TopicsStatus.success,
              topics: _sampleTopics(),
            ),
            searchController: searchController,
            onSearchChanged: (value) {
              searchValue = value;
            },
            onClearSearch: () {},
            onFilterSelected: (filter) {
              selectedFilter = filter;
            },
            onRefresh: () async {},
            onTopicSelected: (topic) {
              selectedTopic = topic;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('topics-summary-card')), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('topics-summary-topic-count')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('topics-summary-question-count')),
        matching: find.text('20'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('topics-summary-completed-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('topics-search-field')),
      'kerajaan',
    );

    expect(searchValue, 'kerajaan');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Selesai'));

    await tester.pump();

    expect(selectedFilter, TopicProgressFilter.completed);

    final topicFinder = find.byKey(const Key('topics-topic-topic-1'));

    await tester.scrollUntilVisible(
      topicFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(topicFinder);
    await tester.pump();

    expect(selectedTopic?.id, 'topic-1');
  });

  testWidgets('memaparkan hasil carian dan callback kosongkan carian', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'kerajaan');

    addTearDown(searchController.dispose);

    var clearCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicsPageContent(
            state: TopicsState(
              status: TopicsStatus.success,
              topics: _sampleTopics(),
              searchQuery: 'kerajaan',
            ),
            searchController: searchController,
            onSearchChanged: (_) {},
            onClearSearch: () {
              clearCount++;
            },
            onFilterSelected: (_) {},
            onRefresh: () async {},
            onTopicSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Sistem Kerajaan'), findsOneWidget);

    expect(find.text('Konsep Negara'), findsNothing);

    expect(find.text('1 topik'), findsOneWidget);

    await tester.tap(find.byKey(const Key('topics-clear-search-button')));

    await tester.pump();

    expect(clearCount, 1);
  });

  testWidgets('memaparkan empty state dan menjalankan refresh', (tester) async {
    final searchController = TextEditingController(text: 'tidak wujud');

    addTearDown(searchController.dispose);

    var refreshCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicsPageContent(
            state: TopicsState(
              status: TopicsStatus.success,
              topics: _sampleTopics(),
              searchQuery: 'tidak wujud',
            ),
            searchController: searchController,
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onFilterSelected: (_) {},
            onRefresh: () async {
              refreshCount++;
            },
            onTopicSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('topics-empty-view')), findsOneWidget);

    expect(find.text('Tiada topik ditemui'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 450));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
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
      questionCount: 10,
      completedQuestionCount: 10,
    ),
  ];
}
