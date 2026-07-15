import 'quiz_mode.dart';
import 'quiz_question.dart';

class QuizResult {
  const QuizResult({
    required this.topicId,
    required this.mode,
    required this.questions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.answeredQuestions,
    required this.elapsedTime,
    required this.autoSubmitted,
  });

  final String topicId;
  final QuizMode mode;
  final List<QuizQuestion> questions;
  final Map<String, int> selectedAnswers;
  final int correctAnswers;
  final int answeredQuestions;
  final Duration elapsedTime;
  final bool autoSubmitted;

  int get totalQuestions => questions.length;

  int get incorrectAnswers {
    return answeredQuestions - correctAnswers;
  }

  int get unansweredQuestions {
    return totalQuestions - answeredQuestions;
  }

  double get percentage {
    if (totalQuestions == 0) {
      return 0;
    }

    return correctAnswers / totalQuestions * 100;
  }

  bool get passed => percentage >= 50;
}
