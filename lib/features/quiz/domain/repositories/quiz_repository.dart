import '../entities/quiz_mode.dart';
import '../entities/quiz_session.dart';
import '../entities/quiz_session_validation.dart';
import '../entities/quiz_submission.dart';

abstract interface class QuizRepository {
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  });

  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  });

  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  });
}
