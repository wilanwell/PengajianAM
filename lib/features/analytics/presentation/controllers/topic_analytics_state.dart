import '../../domain/entities/topic_performance.dart';

enum TopicAnalyticsStatus { initial, loading, success, failure }

class TopicAnalyticsState {
  const TopicAnalyticsState({
    this.status = TopicAnalyticsStatus.initial,
    this.performances = const [],
    this.errorMessage,
  });

  final TopicAnalyticsStatus status;
  final List<TopicPerformance> performances;
  final String? errorMessage;

  int get totalTopics {
    return performances.length;
  }

  int get totalAttempts {
    return performances.fold<int>(
      0,
      (total, performance) => total + performance.attemptCount,
    );
  }

  int get totalQuestions {
    return performances.fold<int>(
      0,
      (total, performance) => total + performance.totalQuestions,
    );
  }

  int get totalCorrectAnswers {
    return performances.fold<int>(
      0,
      (total, performance) => total + performance.totalCorrectAnswers,
    );
  }

  double get overallAverageScore {
    if (totalQuestions == 0) {
      return 0;
    }

    return totalCorrectAnswers / totalQuestions * 100;
  }

  TopicPerformance? get strongestTopic {
    if (performances.isEmpty) {
      return null;
    }

    return performances.first;
  }

  TopicPerformance? get weakestTopic {
    if (performances.isEmpty) {
      return null;
    }

    return performances.last;
  }

  TopicAnalyticsState copyWith({
    TopicAnalyticsStatus? status,
    List<TopicPerformance>? performances,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TopicAnalyticsState(
      status: status ?? this.status,
      performances: performances ?? this.performances,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
