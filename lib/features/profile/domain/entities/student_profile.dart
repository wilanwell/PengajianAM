import 'profile_achievement.dart';

class StudentProfile {
  const StudentProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.semesterLabel,
    required this.joinedAt,
    required this.totalXp,
    required this.completedQuizzes,
    required this.averageScore,
    required this.completedTopics,
    required this.totalTopics,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.weeklyAnsweredQuestions,
    required this.achievements,
  }) : assert(totalXp >= 0),
       assert(completedQuizzes >= 0),
       assert(averageScore >= 0 && averageScore <= 100),
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
  final int completedQuizzes;
  final double averageScore;
  final int completedTopics;
  final int totalTopics;
  final int currentStreakDays;
  final int bestStreakDays;

  final List<int> weeklyAnsweredQuestions;
  final List<ProfileAchievement> achievements;

  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'PA';
    }

    if (words.length == 1) {
      final word = words.first;

      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
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

  StudentProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? semesterLabel,
    DateTime? joinedAt,
    int? totalXp,
    int? completedQuizzes,
    double? averageScore,
    int? completedTopics,
    int? totalTopics,
    int? currentStreakDays,
    int? bestStreakDays,
    List<int>? weeklyAnsweredQuestions,
    List<ProfileAchievement>? achievements,
  }) {
    return StudentProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      semesterLabel: semesterLabel ?? this.semesterLabel,
      joinedAt: joinedAt ?? this.joinedAt,
      totalXp: totalXp ?? this.totalXp,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      averageScore: averageScore ?? this.averageScore,
      completedTopics: completedTopics ?? this.completedTopics,
      totalTopics: totalTopics ?? this.totalTopics,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      weeklyAnsweredQuestions:
          weeklyAnsweredQuestions ?? this.weeklyAnsweredQuestions,
      achievements: achievements ?? this.achievements,
    );
  }
}
