import 'quiz_mode.dart';
import 'quiz_question.dart';

class QuizResult {
  const QuizResult({
    required this.topicId,
    required this.mode,
    required this.questions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.answeredQuestions,
    required this.elapsedTime,
    required this.autoSubmitted,
    this.topicCode = '',
    this.topicTitle = 'Topik Pengajian AM',
  });

  final String topicId;
  final String topicCode;
  final String topicTitle;
  final QuizMode mode;
  final List<QuizQuestion> questions;
  final Map<String, int> selectedAnswers;
  final int correctAnswers;
  final int answeredQuestions;
  final Duration elapsedTime;
  final bool autoSubmitted;

  int get totalQuestions => questions.length;

  int get incorrectAnswers {
    return answeredQuestions - correctAnswers;
  }

  int get unansweredQuestions {
    return totalQuestions - answeredQuestions;
  }

  double get percentage {
    if (totalQuestions == 0) {
      return 0;
    }

    return correctAnswers / totalQuestions * 100;
  }

  bool get passed => percentage >= 50;

  Map<String, Object?> toJson() {
    return {
      'topicId': topicId,
      'topicCode': topicCode,
      'topicTitle': topicTitle,
      'mode': mode.name,
      'questions': [for (final question in questions) question.toJson()],
      'selectedAnswers': selectedAnswers,
      'correctAnswers': correctAnswers,
      'answeredQuestions': answeredQuestions,
      'elapsedTimeMilliseconds': elapsedTime.inMilliseconds,
      'autoSubmitted': autoSubmitted,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];

    if (rawQuestions is! List) {
      throw const FormatException('Invalid quiz result questions.');
    }

    final questions = <QuizQuestion>[];

    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map) {
        throw const FormatException('Invalid quiz question data.');
      }

      questions.add(
        QuizQuestion.fromJson(Map<String, dynamic>.from(rawQuestion)),
      );
    }

    final rawSelectedAnswers = json['selectedAnswers'];

    if (rawSelectedAnswers is! Map) {
      throw const FormatException('Invalid selected answers.');
    }

    final selectedAnswers = <String, int>{};

    for (final entry in rawSelectedAnswers.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key is! String || value is! num) {
        throw const FormatException('Invalid selected answer value.');
      }

      selectedAnswers[key] = value.toInt();
    }

    final modeValue = _readString(json, 'mode');

    return QuizResult(
      topicId: _readString(json, 'topicId'),
      topicCode: _readOptionalString(json, 'topicCode'),
      topicTitle: _readOptionalString(
        json,
        'topicTitle',
        fallback: 'Topik Pengajian AM',
      ),
      mode: quizModeFromRouteValue(modeValue),
      questions: List<QuizQuestion>.unmodifiable(questions),
      selectedAnswers: Map<String, int>.unmodifiable(selectedAnswers),
      correctAnswers: _readInt(json, 'correctAnswers'),
      answeredQuestions: _readInt(json, 'answeredQuestions'),
      elapsedTime: Duration(
        milliseconds: _readInt(json, 'elapsedTimeMilliseconds'),
      ),
      autoSubmitted: _readBool(json, 'autoSubmitted'),
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

String _readOptionalString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];

  if (value == null) {
    return fallback;
  }

  if (value is! String) {
    throw FormatException('Invalid optional String value for $key.');
  }

  return value.trim().isEmpty ? fallback : value;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  return value.toInt();
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! bool) {
    throw FormatException('Invalid Boolean value for $key.');
  }

  return value;
}
