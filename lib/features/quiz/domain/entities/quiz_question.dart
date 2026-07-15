class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  }) : assert(options.length >= 2),
       assert(correctOptionIndex >= 0),
       assert(correctOptionIndex < options.length);

  final String id;
  final String topicId;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  bool isCorrect(int? selectedOptionIndex) {
    return selectedOptionIndex == correctOptionIndex;
  }

  QuizQuestion copyWith({
    String? id,
    String? topicId,
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}
