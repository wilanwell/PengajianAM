import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_result_content.dart';

void main() {
  testWidgets('memaparkan keputusan kuiz standard '
      'dan menjalankan semua callback', (tester) async {
    var reviewCount = 0;
    var retryCount = 0;
    var topicsCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultContent(
          result: _standardResult(),
          onReviewAnswers: () {
            reviewCount++;
          },
          onRetryQuiz: () {
            retryCount++;
          },
          onReturnToMistakeBookTopic: () {},
          onReturnToTopics: () {
            topicsCount++;
          },
        ),
      ),
    );

    expect(find.text('Keputusan Kuiz'), findsOneWidget);

    expect(find.text('1/2'), findsOneWidget);

    expect(find.text('50%'), findsOneWidget);

    expect(find.text('Bagus!'), findsOneWidget);

    expect(find.text('+25 XP'), findsOneWidget);

    expect(find.text('01:05'), findsOneWidget);

    expect(find.byKey(const Key('quiz-result-earned-xp-card')), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-result-mistake-review-card')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-result-review-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-result-review-button')));

    await tester.pump();

    expect(reviewCount, 1);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-result-retry-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-result-retry-button')));

    await tester.pump();

    expect(retryCount, 1);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-result-topics-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-result-topics-button')));

    await tester.pump();

    expect(topicsCount, 1);
  });

  testWidgets('memaparkan keputusan latihan semula '
      'tanpa ganjaran XP', (tester) async {
    var mistakeBookCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1400));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultContent(
          result: _mistakeReviewResult(),
          onReviewAnswers: () {},
          onRetryQuiz: () {},
          onReturnToMistakeBookTopic: () {
            mistakeBookCount++;
          },
          onReturnToTopics: () {},
        ),
      ),
    );

    expect(find.text('Keputusan Latihan Semula'), findsOneWidget);

    expect(find.text('Latihan Selesai'), findsOneWidget);

    expect(find.text('Fokus Penguasaan'), findsOneWidget);

    expect(
      find.byKey(const Key('quiz-result-mistake-review-card')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('quiz-result-earned-xp-card')), findsNothing);

    expect(find.text('Cuba Lagi'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-result-mistake-book-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('quiz-result-mistake-book-button')));

    await tester.pump();

    expect(mistakeBookCount, 1);
  });

  testWidgets('memaparkan mesej apabila Exam Mode '
      'dihantar secara automatik', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultContent(
          result: _autoSubmittedResult(),
          onReviewAnswers: () {},
          onRetryQuiz: () {},
          onReturnToMistakeBookTopic: () {},
          onReturnToTopics: () {},
        ),
      ),
    );

    expect(find.text('Teruskan Berusaha'), findsOneWidget);

    expect(
      find.text(
        'Masa tamat dan kuiz telah '
        'dihantar secara automatik.',
      ),
      findsOneWidget,
    );
  });
}

QuizResult _standardResult() {
  return QuizResult(
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Konsep Negara',
    mode: QuizMode.practice,
    questions: _questions,
    selectedAnswers: const {'question-1': 1, 'question-2': 0},
    correctAnswers: 1,
    answeredQuestions: 2,
    earnedXp: 25,
    elapsedTime: const Duration(minutes: 1, seconds: 5),
    autoSubmitted: false,
  );
}

QuizResult _mistakeReviewResult() {
  return QuizResult(
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Konsep Negara',
    mode: QuizMode.practice,
    sessionSource: QuizSessionSource.mistakeReview,
    questions: _questions,
    selectedAnswers: const {'question-1': 1},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 0,
    elapsedTime: const Duration(seconds: 25),
    autoSubmitted: false,
  );
}

QuizResult _autoSubmittedResult() {
  return QuizResult(
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Konsep Negara',
    mode: QuizMode.exam,
    questions: _questions,
    selectedAnswers: const {},
    correctAnswers: 0,
    answeredQuestions: 0,
    earnedXp: 0,
    elapsedTime: const Duration(minutes: 3),
    autoSubmitted: true,
  );
}

final List<QuizQuestion> _questions = [
  QuizQuestion(
    id: 'question-1',
    topicId: 'topic-1',
    questionText: 'Apakah jawapan yang betul?',
    options: ['Pilihan A', 'Pilihan B'],
    correctOptionIndex: 1,
    explanation: 'Pilihan B ialah jawapan betul.',
    shuffleOptions: false,
  ),
  QuizQuestion(
    id: 'question-2',
    topicId: 'topic-1',
    questionText: 'Apakah pilihan kedua?',
    options: ['Pilihan A', 'Pilihan B'],
    correctOptionIndex: 1,
    explanation: 'Pilihan B ialah jawapan betul.',
    shuffleOptions: false,
  ),
];
