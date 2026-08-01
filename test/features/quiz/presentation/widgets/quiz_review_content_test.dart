import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_review_coordinator.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_review_card.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_review_content.dart';

void main() {
  testWidgets('memaparkan kandungan semakan '
      'dan menjalankan callback penapis', (tester) async {
    QuizReviewFilter? selectedByCallback;

    await tester.binding.setSurfaceSize(const Size(800, 1600));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizReviewContent(
          result: _buildResult(),
          selectedFilter: QuizReviewFilter.all,
          visibleQuestionIndexes: const [0, 1, 2],
          onFilterSelected: (filter) {
            selectedByCallback = filter;
          },
        ),
      ),
    );

    expect(find.text('Semakan Jawapan'), findsOneWidget);

    expect(find.text('Ringkasan Semakan'), findsOneWidget);

    expect(find.text('3 soalan'), findsOneWidget);

    expect(find.byType(QuizReviewCard), findsNWidgets(3));

    expect(find.text('Soalan pertama', skipOffstage: false), findsOneWidget);

    expect(find.text('Soalan kedua', skipOffstage: false), findsOneWidget);

    expect(find.text('Soalan ketiga', skipOffstage: false), findsOneWidget);

    final allChip = tester.widget<FilterChip>(
      find.byKey(const Key('quiz-review-filter-all')),
    );

    expect(allChip.selected, isTrue);

    final incorrectFilter = find.byKey(
      const Key('quiz-review-filter-incorrect'),
    );

    await tester.ensureVisible(incorrectFilter);

    await tester.tap(incorrectFilter);

    await tester.pump();

    expect(selectedByCallback, QuizReviewFilter.incorrect);
  });

  testWidgets('memaparkan empty view apabila '
      'tiada indeks soalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizReviewContent(
          result: _buildResult(),
          selectedFilter: QuizReviewFilter.unanswered,
          visibleQuestionIndexes: const [],
          onFilterSelected: (_) {},
        ),
      ),
    );

    expect(find.text('0 soalan'), findsOneWidget);

    expect(find.byKey(const Key('quiz-review-empty-view')), findsOneWidget);

    expect(find.byType(QuizReviewCard), findsNothing);

    final unansweredChip = tester.widget<FilterChip>(
      find.byKey(const Key('quiz-review-filter-unanswered')),
    );

    expect(unansweredChip.selected, isTrue);
  });

  testWidgets('mengekalkan nombor asal soalan '
      'selepas penapisan', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizReviewContent(
          result: _buildResult(),
          selectedFilter: QuizReviewFilter.incorrect,
          visibleQuestionIndexes: const [1],
          onFilterSelected: (_) {},
        ),
      ),
    );

    expect(find.text('1 soalan'), findsOneWidget);

    expect(find.byType(QuizReviewCard), findsOneWidget);

    expect(find.text('Soalan pertama', skipOffstage: false), findsNothing);

    expect(find.text('Soalan kedua', skipOffstage: false), findsOneWidget);

    final reviewCard = find.byType(QuizReviewCard);

    expect(
      find.descendant(of: reviewCard, matching: find.text('2')),
      findsOneWidget,
    );
  });
}

QuizResult _buildResult() {
  return QuizResult(
    topicId: 'topic-1',
    mode: QuizMode.practice,
    questions: _buildQuestions(),
    selectedAnswers: const {'question-1': 0, 'question-2': 0},
    correctAnswers: 1,
    answeredQuestions: 2,
    elapsedTime: const Duration(minutes: 2),
    autoSubmitted: false,
  );
}

List<QuizQuestion> _buildQuestions() {
  return [
    QuizQuestion(
      id: 'question-1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 0,
      explanation: 'Penerangan pertama.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-2',
      topicId: 'topic-1',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Penerangan kedua.',
      shuffleOptions: false,
    ),
    QuizQuestion(
      id: 'question-3',
      topicId: 'topic-1',
      questionText: 'Soalan ketiga',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Penerangan ketiga.',
      shuffleOptions: false,
    ),
  ];
}
