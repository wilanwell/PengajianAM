import 'quiz_attempt.dart';

class QuizHistorySnapshot {
  const QuizHistorySnapshot({
    required this.generatedAt,
    required this.totalCount,
    required this.attempts,
  }) : assert(totalCount >= 0);

  final DateTime generatedAt;
  final int totalCount;
  final List<QuizAttempt> attempts;
}
