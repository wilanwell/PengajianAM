import 'quiz_result.dart';

class QuizSubmission {
  const QuizSubmission({
    required this.attemptId,
    required this.earnedXp,
    required this.completedAt,
    required this.result,
  }) : assert(earnedXp >= 0);

  final String attemptId;
  final int earnedXp;
  final DateTime completedAt;
  final QuizResult result;
}
