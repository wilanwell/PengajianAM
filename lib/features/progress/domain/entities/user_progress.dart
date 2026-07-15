class UserProgress {
  const UserProgress({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.semesterLabel,
    required this.joinedAt,
    required this.totalXp,
    required this.weeklyXp,
    required this.monthlyXp,
    required this.completedQuizzes,
    required this.totalCorrectAnswers,
    required this.totalQuizQuestions,
    required this.highestScore,
    required this.completedTopics,
    required this.totalTopics,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.weeklyAnsweredQuestions,
  }) : assert(totalXp >= 0),
       assert(weeklyXp >= 0),
       assert(monthlyXp >= 0),
       assert(completedQuizzes >= 0),
       assert(totalCorrectAnswers >= 0),
       assert(totalQuizQuestions >= 0),
       assert(highestScore >= 0 && highestScore <= 100),
       assert(completedTopics >= 0),
       assert(totalTopics >= 0),
       assert(completedTopics <= totalTopics),
       assert(currentStreakDays >= 0),
       assert(bestStreakDays >= 0);

  final String userId;
  final String displayName;
  final String email;
  final String semesterLabel;
  final DateTime joinedAt;

  final int totalXp;
  final int weeklyXp;
  final int monthlyXp;

  final int completedQuizzes;
  final int totalCorrectAnswers;
  final int totalQuizQuestions;
  final double highestScore;

  final int completedTopics;
  final int totalTopics;
  final int currentStreakDays;
  final int bestStreakDays;

  final List<int> weeklyAnsweredQuestions;

  double get averageScore {
    if (totalQuizQuestions == 0) {
      return 0;
    }

    return totalCorrectAnswers / totalQuizQuestions * 100;
  }

  double get topicProgress {
    if (totalTopics == 0) {
      return 0;
    }

    return completedTopics / totalTopics;
  }

  int get topicProgressPercentage {
    return (topicProgress * 100).round();
  }

  UserProgress copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? semesterLabel,
    DateTime? joinedAt,
    int? totalXp,
    int? weeklyXp,
    int? monthlyXp,
    int? completedQuizzes,
    int? totalCorrectAnswers,
    int? totalQuizQuestions,
    double? highestScore,
    int? completedTopics,
    int? totalTopics,
    int? currentStreakDays,
    int? bestStreakDays,
    List<int>? weeklyAnsweredQuestions,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      semesterLabel: semesterLabel ?? this.semesterLabel,
      joinedAt: joinedAt ?? this.joinedAt,
      totalXp: totalXp ?? this.totalXp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      monthlyXp: monthlyXp ?? this.monthlyXp,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalQuizQuestions: totalQuizQuestions ?? this.totalQuizQuestions,
      highestScore: highestScore ?? this.highestScore,
      completedTopics: completedTopics ?? this.completedTopics,
      totalTopics: totalTopics ?? this.totalTopics,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      weeklyAnsweredQuestions:
          weeklyAnsweredQuestions ?? this.weeklyAnsweredQuestions,
    );
  }
}
