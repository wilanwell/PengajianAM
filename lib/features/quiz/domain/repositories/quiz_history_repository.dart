import '../entities/quiz_attempt.dart';

abstract interface class QuizHistoryRepository {
  Future<List<QuizAttempt>> loadAttempts();

  Future<void> saveAttempts(List<QuizAttempt> attempts);

  Future<void> clearAttempts();
}
