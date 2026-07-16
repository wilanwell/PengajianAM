import '../entities/quiz_mode.dart';
import '../entities/quiz_session.dart';
import '../entities/quiz_submission.dart';

abstract interface class QuizRepository {
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  });

  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  });
}
