enum QuizSessionSource {
  standard,
  mistakeReview;

  String get serverValue {
    return switch (this) {
      QuizSessionSource.standard => 'standard',
      QuizSessionSource.mistakeReview => 'mistake_review',
    };
  }

  String get label {
    return switch (this) {
      QuizSessionSource.standard => 'Kuiz',
      QuizSessionSource.mistakeReview => 'Latihan Semula',
    };
  }
}

QuizSessionSource quizSessionSourceFromServerValue(
  String? value, {
  QuizSessionSource fallback = QuizSessionSource.standard,
}) {
  return switch (value?.trim()) {
    'standard' => QuizSessionSource.standard,
    'mistake_review' => QuizSessionSource.mistakeReview,
    null || '' => fallback,
    _ => throw const FormatException('Invalid quiz session source.'),
  };
}
