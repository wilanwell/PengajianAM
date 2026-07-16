import '../../domain/entities/quiz_attempt.dart';

enum QuizHistoryStatus { initial, loading, success, failure }

class QuizHistoryState {
  const QuizHistoryState({
    this.status = QuizHistoryStatus.initial,
    this.attempts = const [],
    this.totalCount = 0,
    this.lastUpdated,
    this.errorMessage,
  });

  final QuizHistoryStatus status;
  final List<QuizAttempt> attempts;
  final int totalCount;
  final DateTime? lastUpdated;
  final String? errorMessage;

  int get totalAttempts {
    return totalCount;
  }

  int get loadedAttemptCount {
    return attempts.length;
  }

  int get totalEarnedXp {
    return attempts.fold<int>(0, (total, attempt) {
      return total + attempt.earnedXp;
    });
  }

  double get averageScore {
    if (attempts.isEmpty) {
      return 0;
    }

    final totalPercentage = attempts.fold<double>(0, (total, attempt) {
      return total + attempt.result.percentage;
    });

    return totalPercentage / attempts.length;
  }

  QuizHistoryState copyWith({
    QuizHistoryStatus? status,
    List<QuizAttempt>? attempts,
    int? totalCount,
    DateTime? lastUpdated,
    String? errorMessage,
    bool clearLastUpdated = false,
    bool clearErrorMessage = false,
  }) {
    return QuizHistoryState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
