import 'quiz_mode.dart';
import 'quiz_question.dart';
import 'quiz_session_source.dart';

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
    this.sessionSource = QuizSessionSource.standard,
    this.topicCode = '',
    this.topicTitle = 'Topik Pengajian AM',
    this.earnedXp = 0,
  }) : assert(earnedXp >= 0);

  final String topicId;
  final String topicCode;
  final String topicTitle;

  final QuizMode mode;
  final QuizSessionSource sessionSource;
  final List<QuizQuestion> questions;
  final Map<String, int> selectedAnswers;

  final int correctAnswers;
  final int answeredQuestions;
  final int earnedXp;

  final Duration elapsedTime;
  final bool autoSubmitted;

  int get totalQuestions {
    return questions.length;
  }

  int get incorrectAnswers {
    return answeredQuestions - correctAnswers;
  }

  int get unansweredQuestions {
    final count = totalQuestions - answeredQuestions;

    return count < 0 ? 0 : count;
  }

  double get percentage {
    if (totalQuestions == 0) {
      return 0;
    }

    return correctAnswers / totalQuestions * 100;
  }

  bool get passed {
    return percentage >= 50;
  }

  Map<String, Object?> toJson() {
    return {
      'topicId': topicId,
      'topicCode': topicCode,
      'topicTitle': topicTitle,
      'mode': mode.name,
      'sessionSource': sessionSource.serverValue,
      'questions': [for (final question in questions) question.toJson()],
      'selectedAnswers': selectedAnswers,
      'correctAnswers': correctAnswers,
      'answeredQuestions': answeredQuestions,
      'earnedXp': earnedXp,
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
      sessionSource: quizSessionSourceFromServerValue(
        _readOptionalString(json, 'sessionSource'),
      ),
      questions: List<QuizQuestion>.unmodifiable(questions),
      selectedAnswers: Map<String, int>.unmodifiable(selectedAnswers),
      correctAnswers: _readInt(json, 'correctAnswers'),
      answeredQuestions: _readInt(json, 'answeredQuestions'),
      earnedXp: _readOptionalInt(json, 'earnedXp'),
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

  return value.trim();
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

  return value.trim().isEmpty ? fallback : value.trim();
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  return value.toInt();
}

int _readOptionalInt(
  Map<String, dynamic> json,
  String key, {
  int fallback = 0,
}) {
  final value = json[key];

  if (value == null) {
    return fallback;
  }

  if (value is! num) {
    throw FormatException('Invalid optional integer value for $key.');
  }

  final result = value.toInt();

  return result < 0 ? fallback : result;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! bool) {
    throw FormatException('Invalid Boolean value for $key.');
  }

  return value;
}
