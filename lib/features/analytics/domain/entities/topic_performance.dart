enum TopicMasteryLevel { needsImprovement, developing, strong }

extension TopicMasteryLevelDetails on TopicMasteryLevel {
  String get label {
    return switch (this) {
      TopicMasteryLevel.needsImprovement => 'Perlu Diberi Perhatian',
      TopicMasteryLevel.developing => 'Sedang Berkembang',
      TopicMasteryLevel.strong => 'Kuat',
    };
  }
}

class TopicPerformance {
  const TopicPerformance({
    required this.topicId,
    required this.topicCode,
    required this.topicTitle,
    required this.attemptCount,
    required this.totalQuestions,
    required this.totalCorrectAnswers,
    required this.bestScore,
    required this.totalEarnedXp,
  }) : assert(attemptCount >= 0),
       assert(totalQuestions >= 0),
       assert(totalCorrectAnswers >= 0),
       assert(totalCorrectAnswers <= totalQuestions),
       assert(bestScore >= 0 && bestScore <= 100),
       assert(totalEarnedXp >= 0);

  final String topicId;
  final String topicCode;
  final String topicTitle;

  final int attemptCount;
  final int totalQuestions;
  final int totalCorrectAnswers;
  final double bestScore;
  final int totalEarnedXp;

  double get averageScore {
    if (totalQuestions == 0) {
      return 0;
    }

    return totalCorrectAnswers / totalQuestions * 100;
  }

  int get averageScorePercentage {
    return averageScore.round();
  }

  TopicMasteryLevel get masteryLevel {
    if (averageScore >= 80) {
      return TopicMasteryLevel.strong;
    }

    if (averageScore >= 50) {
      return TopicMasteryLevel.developing;
    }

    return TopicMasteryLevel.needsImprovement;
  }
}
