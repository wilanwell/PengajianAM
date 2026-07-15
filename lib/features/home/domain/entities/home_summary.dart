/// Represents the summarized learning information displayed
/// on the student's home dashboard.
class HomeSummary {
  const HomeSummary({
    required this.displayName,
    required this.semesterLabel,
    required this.completedQuizzes,
    required this.averageScore,
    required this.totalXp,
    required this.weeklyRank,
    required this.currentTopic,
    required this.currentTopicProgress,
    required this.completedTopics,
    required this.totalTopics,
  }) : assert(
         currentTopicProgress >= 0 && currentTopicProgress <= 1,
         'Progress must be between 0 and 1.',
       );

  final String displayName;
  final String semesterLabel;
  final int completedQuizzes;
  final double averageScore;
  final int totalXp;
  final int weeklyRank;
  final String currentTopic;
  final double currentTopicProgress;
  final int completedTopics;
  final int totalTopics;
}
