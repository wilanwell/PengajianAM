import 'quiz_mode.dart';
import 'quiz_session_question.dart';

class QuizSession {
  const QuizSession({
    required this.sessionId,
    required this.topicId,
    required this.mode,
    required this.questionCount,
    required this.expiresAt,
    required this.questions,
  }) : assert(questionCount > 0);

  final String sessionId;
  final String topicId;
  final QuizMode mode;
  final int questionCount;
  final DateTime expiresAt;
  final List<QuizSessionQuestion> questions;
}
