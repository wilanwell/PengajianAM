class QuizSessionQuestion {
  const QuizSessionQuestion({
    required this.id,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.questionOrder,
  }) : assert(options.length >= 2),
       assert(questionOrder > 0);

  final String id;
  final String topicId;
  final String questionText;
  final List<String> options;
  final int questionOrder;

  factory QuizSessionQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    if (rawOptions is! List) {
      throw const FormatException('Invalid quiz session options.');
    }

    final options = <String>[];

    for (final option in rawOptions) {
      if (option is! String || option.trim().isEmpty) {
        throw const FormatException('Invalid quiz session option.');
      }

      options.add(option.trim());
    }

    return QuizSessionQuestion(
      id: _readRequiredString(json, 'id'),
      topicId: _readRequiredString(json, 'topicId'),
      questionText: _readRequiredString(json, 'questionText'),
      options: List<String>.unmodifiable(options),
      questionOrder: _readRequiredInt(json, 'questionOrder'),
    );
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid String value for $key.');
  }

  return value.trim();
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  return value.toInt();
}
