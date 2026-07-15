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

  static const int schemaVersion = 1;

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

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'semesterLabel': semesterLabel,
      'joinedAt': joinedAt.toIso8601String(),
      'totalXp': totalXp,
      'weeklyXp': weeklyXp,
      'monthlyXp': monthlyXp,
      'completedQuizzes': completedQuizzes,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalQuizQuestions': totalQuizQuestions,
      'highestScore': highestScore,
      'completedTopics': completedTopics,
      'totalTopics': totalTopics,
      'currentStreakDays': currentStreakDays,
      'bestStreakDays': bestStreakDays,
      'weeklyAnsweredQuestions': weeklyAnsweredQuestions,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final version = _readInt(json, 'schemaVersion');

    if (version != schemaVersion) {
      throw const FormatException('Unsupported user progress schema version.');
    }

    final joinedAtString = _readString(json, 'joinedAt');

    final joinedAt = DateTime.tryParse(joinedAtString);

    if (joinedAt == null) {
      throw const FormatException('Invalid joinedAt value.');
    }

    final weeklyActivity = _readIntList(json, 'weeklyAnsweredQuestions');

    return UserProgress(
      userId: _readString(json, 'userId'),
      displayName: _readString(json, 'displayName'),
      email: _readString(json, 'email'),
      semesterLabel: _readString(json, 'semesterLabel'),
      joinedAt: joinedAt,
      totalXp: _readInt(json, 'totalXp'),
      weeklyXp: _readInt(json, 'weeklyXp'),
      monthlyXp: _readInt(json, 'monthlyXp'),
      completedQuizzes: _readInt(json, 'completedQuizzes'),
      totalCorrectAnswers: _readInt(json, 'totalCorrectAnswers'),
      totalQuizQuestions: _readInt(json, 'totalQuizQuestions'),
      highestScore: _readDouble(json, 'highestScore'),
      completedTopics: _readInt(json, 'completedTopics'),
      totalTopics: _readInt(json, 'totalTopics'),
      currentStreakDays: _readInt(json, 'currentStreakDays'),
      bestStreakDays: _readInt(json, 'bestStreakDays'),
      weeklyAnsweredQuestions: List<int>.unmodifiable(
        _normalizeWeeklyActivity(weeklyActivity),
      ),
    );
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

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid String value for $key.');
  }

  return value;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  return value.toInt();
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid double value for $key.');
  }

  return value.toDouble();
}

List<int> _readIntList(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! List) {
    throw FormatException('Invalid list value for $key.');
  }

  final result = <int>[];

  for (final item in value) {
    if (item is! num) {
      throw FormatException('Invalid item inside $key.');
    }

    result.add(item.toInt());
  }

  return result;
}

List<int> _normalizeWeeklyActivity(List<int> values) {
  final normalized = List<int>.filled(7, 0);

  for (
    var index = 0;
    index < values.length && index < normalized.length;
    index++
  ) {
    normalized[index] = values[index] < 0 ? 0 : values[index];
  }

  return normalized;
}
