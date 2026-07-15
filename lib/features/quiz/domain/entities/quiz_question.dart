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

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    if (rawOptions is! List) {
      throw const FormatException('Invalid quiz question options.');
    }

    final options = <String>[];

    for (final option in rawOptions) {
      if (option is! String) {
        throw const FormatException('Invalid quiz question option.');
      }

      options.add(option);
    }

    return QuizQuestion(
      id: _readRequiredString(json, 'id'),
      topicId: _readRequiredString(json, 'topicId'),
      questionText: _readRequiredString(json, 'questionText'),
      options: List<String>.unmodifiable(options),
      correctOptionIndex: _readRequiredInt(json, 'correctOptionIndex'),
      explanation: _readRequiredString(json, 'explanation'),
    );
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

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid String value for $key.');
  }

  return value;
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  return value.toInt();
}
