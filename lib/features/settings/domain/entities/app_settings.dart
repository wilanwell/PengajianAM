import '../../../quiz/domain/entities/quiz_mode.dart';

class AppSettings {
  const AppSettings({
    required this.defaultQuizMode,
    required this.defaultQuestionCount,
  }) : assert(defaultQuestionCount == 10 || defaultQuestionCount == 20);

  static const int schemaVersion = 1;

  static const List<int> allowedQuestionCounts = [10, 20];

  static const AppSettings defaults = AppSettings(
    defaultQuizMode: QuizMode.practice,
    defaultQuestionCount: 10,
  );

  final QuizMode defaultQuizMode;
  final int defaultQuestionCount;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'defaultQuizMode': defaultQuizMode.name,
      'defaultQuestionCount': defaultQuestionCount,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];

    if (version is! num || version.toInt() != schemaVersion) {
      throw const FormatException('Unsupported app settings schema version.');
    }

    final modeValue = json['defaultQuizMode'];
    final questionCountValue = json['defaultQuestionCount'];

    if (modeValue is! String || modeValue.trim().isEmpty) {
      throw const FormatException('Invalid default quiz mode.');
    }

    if (questionCountValue is! num) {
      throw const FormatException('Invalid default question count.');
    }

    final questionCount = questionCountValue.toInt();

    if (!allowedQuestionCounts.contains(questionCount)) {
      throw const FormatException('Unsupported default question count.');
    }

    return AppSettings(
      defaultQuizMode: quizModeFromRouteValue(modeValue),
      defaultQuestionCount: questionCount,
    );
  }

  AppSettings copyWith({QuizMode? defaultQuizMode, int? defaultQuestionCount}) {
    return AppSettings(
      defaultQuizMode: defaultQuizMode ?? this.defaultQuizMode,
      defaultQuestionCount: defaultQuestionCount ?? this.defaultQuestionCount,
    );
  }
}
