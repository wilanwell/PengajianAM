import '../entities/quiz_history_snapshot.dart';

abstract interface class QuizHistoryRepository {
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30});

  Future<void> deleteAttempt(String attemptId);

  Future<int> clearHistory();
}
