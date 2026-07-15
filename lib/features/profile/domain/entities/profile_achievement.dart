enum AchievementType { firstQuiz, highScore, sevenDayStreak, topicMaster }

class ProfileAchievement {
  const ProfileAchievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
  }) : assert(progress >= 0),
       assert(target > 0),
       assert(progress <= target);

  final String id;
  final AchievementType type;
  final String title;
  final String description;
  final int progress;
  final int target;

  bool get isUnlocked {
    return progress >= target;
  }

  double get progressValue {
    return progress / target;
  }
}
