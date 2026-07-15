enum QuizMode { practice, exam }

extension QuizModeDetails on QuizMode {
  String get label {
    return switch (this) {
      QuizMode.practice => 'Practice Mode',
      QuizMode.exam => 'Exam Mode',
    };
  }

  String get description {
    return switch (this) {
      QuizMode.practice =>
        'Latihan santai tanpa had masa untuk meningkatkan pemahaman.',
      QuizMode.exam =>
        'Simulasi berjangka masa untuk menguji tahap penguasaan.',
    };
  }

  String get routeValue {
    return name;
  }
}

QuizMode quizModeFromRouteValue(String? value) {
  return QuizMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => QuizMode.practice,
  );
}
