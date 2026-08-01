import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_result.dart';

enum QuizReviewFilter { all, correct, incorrect, unanswered }

class QuizReviewCoordinator {
  const QuizReviewCoordinator();

  List<int> visibleQuestionIndexes({
    required QuizResult result,
    required QuizReviewFilter filter,
  }) {
    final indexes = <int>[];

    for (var index = 0; index < result.questions.length; index++) {
      final question = result.questions[index];

      final selectedOptionIndex = result.selectedAnswers[question.id];

      if (matchesFilter(
        question: question,
        selectedOptionIndex: selectedOptionIndex,
        filter: filter,
      )) {
        indexes.add(index);
      }
    }

    return List<int>.unmodifiable(indexes);
  }

  bool matchesFilter({
    required QuizQuestion question,
    required int? selectedOptionIndex,
    required QuizReviewFilter filter,
  }) {
    final isAnswered = selectedOptionIndex != null;

    final isCorrect = question.isCorrect(selectedOptionIndex);

    return switch (filter) {
      QuizReviewFilter.all => true,
      QuizReviewFilter.correct => isCorrect,
      QuizReviewFilter.incorrect => isAnswered && !isCorrect,
      QuizReviewFilter.unanswered => !isAnswered,
    };
  }

  String filterLabel(QuizReviewFilter filter) {
    return switch (filter) {
      QuizReviewFilter.all => 'Semua',
      QuizReviewFilter.correct => 'Betul',
      QuizReviewFilter.incorrect => 'Salah',
      QuizReviewFilter.unanswered => 'Tidak Dijawab',
    };
  }
}
