import '../../domain/entities/quiz_attempt.dart';

enum QuizHistoryStatus { initial, loading, success, failure }

class QuizHistoryState {
  const QuizHistoryState({
    this.status = QuizHistoryStatus.initial,
    this.attempts = const [],
    this.errorMessage,
  });

  final QuizHistoryStatus status;
  final List<QuizAttempt> attempts;
  final String? errorMessage;

  int get totalAttempts => attempts.length;

  int get totalEarnedXp {
    return attempts.fold<int>(0, (total, attempt) => total + attempt.earnedXp);
  }

  double get averageScore {
    if (attempts.isEmpty) {
      return 0;
    }

    final totalPercentage = attempts.fold<double>(
      0,
      (total, attempt) => total + attempt.result.percentage,
    );

    return totalPercentage / attempts.length;
  }

  QuizHistoryState copyWith({
    QuizHistoryStatus? status,
    List<QuizAttempt>? attempts,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return QuizHistoryState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
