import 'quiz_mode.dart';
import 'quiz_session_question.dart';

class QuizDraft {
  QuizDraft({
    required this.sessionId,
    required this.topicId,
    required this.mode,
    required this.questionCount,
    required this.questions,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.flaggedQuestionIds,
    required this.startedAt,
    required this.sessionExpiresAt,
    required this.savedAt,
    this.examDeadlineAt,
  }) {
    _validate();
  }

  static const int currentSchemaVersion = 1;

  final String sessionId;
  final String topicId;
  final QuizMode mode;
  final int questionCount;
  final List<QuizSessionQuestion> questions;

  final int currentQuestionIndex;
  final Map<String, int> selectedAnswers;
  final Set<String> flaggedQuestionIds;

  final DateTime startedAt;
  final DateTime sessionExpiresAt;
  final DateTime? examDeadlineAt;
  final DateTime savedAt;

  DateTime get effectiveExpiresAt {
    final examDeadline = examDeadlineAt;

    if (examDeadline == null) {
      return sessionExpiresAt;
    }

    return examDeadline.isBefore(sessionExpiresAt)
        ? examDeadline
        : sessionExpiresAt;
  }

  bool isExpiredAt(DateTime dateTime) {
    return !effectiveExpiresAt.isAfter(dateTime);
  }

  int? remainingSecondsAt(DateTime dateTime) {
    if (mode != QuizMode.exam) {
      return null;
    }

    final difference = effectiveExpiresAt.difference(dateTime).inSeconds;

    return difference < 0 ? 0 : difference;
  }

  Duration elapsedTimeAt(DateTime dateTime) {
    if (dateTime.isBefore(startedAt)) {
      return Duration.zero;
    }

    return dateTime.difference(startedAt);
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': currentSchemaVersion,
      'sessionId': sessionId,
      'topicId': topicId,
      'mode': mode.name,
      'questionCount': questionCount,
      'questions': [for (final question in questions) question.toJson()],
      'currentQuestionIndex': currentQuestionIndex,
      'selectedAnswers': selectedAnswers,
      'flaggedQuestionIds': flaggedQuestionIds.toList(growable: false),
      'startedAt': startedAt.toUtc().toIso8601String(),
      'sessionExpiresAt': sessionExpiresAt.toUtc().toIso8601String(),
      'examDeadlineAt': examDeadlineAt?.toUtc().toIso8601String(),
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }

  factory QuizDraft.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _readInteger(json, 'schemaVersion', minimum: 1);

    if (schemaVersion != currentSchemaVersion) {
      throw const FormatException('Unsupported quiz draft version.');
    }

    final mode = _readMode(json, 'mode');

    final rawQuestions = json['questions'];

    if (rawQuestions is! List) {
      throw const FormatException('Invalid quiz draft questions.');
    }

    final questions = <QuizSessionQuestion>[];

    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map) {
        throw const FormatException('Invalid quiz draft question.');
      }

      questions.add(
        QuizSessionQuestion.fromJson(Map<String, dynamic>.from(rawQuestion)),
      );
    }

    final selectedAnswers = _readSelectedAnswers(json, 'selectedAnswers');

    final flaggedQuestionIds = _readStringSet(json, 'flaggedQuestionIds');

    final rawExamDeadline = json['examDeadlineAt'];

    DateTime? examDeadlineAt;

    if (rawExamDeadline != null) {
      if (rawExamDeadline is! String) {
        throw const FormatException('Invalid exam deadline.');
      }

      examDeadlineAt = DateTime.tryParse(rawExamDeadline);

      if (examDeadlineAt == null) {
        throw const FormatException('Invalid exam deadline.');
      }
    }

    return QuizDraft(
      sessionId: _readRequiredString(json, 'sessionId'),
      topicId: _readRequiredString(json, 'topicId'),
      mode: mode,
      questionCount: _readInteger(json, 'questionCount', minimum: 1),
      questions: List<QuizSessionQuestion>.unmodifiable(questions),
      currentQuestionIndex: _readInteger(
        json,
        'currentQuestionIndex',
        minimum: 0,
      ),
      selectedAnswers: Map<String, int>.unmodifiable(selectedAnswers),
      flaggedQuestionIds: Set<String>.unmodifiable(flaggedQuestionIds),
      startedAt: _readDateTime(json, 'startedAt'),
      sessionExpiresAt: _readDateTime(json, 'sessionExpiresAt'),
      examDeadlineAt: examDeadlineAt,
      savedAt: _readDateTime(json, 'savedAt'),
    );
  }

  void _validate() {
    if (sessionId.trim().isEmpty) {
      throw const FormatException('Quiz draft session ID is empty.');
    }

    if (topicId.trim().isEmpty) {
      throw const FormatException('Quiz draft topic ID is empty.');
    }

    if (questionCount < 1 || questions.length != questionCount) {
      throw const FormatException('Quiz draft question count is invalid.');
    }

    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      throw const FormatException(
        'Quiz draft current question index '
        'is invalid.',
      );
    }

    if (!sessionExpiresAt.isAfter(startedAt)) {
      throw const FormatException('Quiz draft expiry is invalid.');
    }

    if (savedAt.isBefore(startedAt)) {
      throw const FormatException('Quiz draft save time is invalid.');
    }

    if (mode == QuizMode.exam && examDeadlineAt == null) {
      throw const FormatException('Exam draft requires a deadline.');
    }

    if (mode == QuizMode.practice && examDeadlineAt != null) {
      throw const FormatException(
        'Practice draft cannot have an '
        'exam deadline.',
      );
    }

    final questionIds = questions.map((question) => question.id).toSet();

    if (questionIds.length != questions.length) {
      throw const FormatException(
        'Quiz draft contains duplicate '
        'questions.',
      );
    }

    for (final entry in selectedAnswers.entries) {
      if (!questionIds.contains(entry.key)) {
        throw const FormatException(
          'Quiz draft contains an answer '
          'for an unknown question.',
        );
      }

      final question = questions.firstWhere((item) => item.id == entry.key);

      if (entry.value < 0 || entry.value >= question.options.length) {
        throw const FormatException(
          'Quiz draft contains an invalid '
          'answer option.',
        );
      }
    }

    if (!questionIds.containsAll(flaggedQuestionIds)) {
      throw const FormatException(
        'Quiz draft contains an unknown '
        'flagged question.',
      );
    }
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid String value for $key.');
  }

  return value.trim();
}

int _readInteger(
  Map<String, dynamic> json,
  String key, {
  required int minimum,
}) {
  final value = json[key];

  if (value is! num) {
    throw FormatException('Invalid integer value for $key.');
  }

  final result = value.toInt();

  if (result < minimum) {
    throw FormatException(
      'Integer value for $key is outside '
      'the allowed range.',
    );
  }

  return result;
}

DateTime _readDateTime(Map<String, dynamic> json, String key) {
  final rawValue = _readRequiredString(json, key);

  final parsedValue = DateTime.tryParse(rawValue);

  if (parsedValue == null) {
    throw FormatException('Invalid DateTime value for $key.');
  }

  return parsedValue;
}

QuizMode _readMode(Map<String, dynamic> json, String key) {
  final value = _readRequiredString(json, key);

  for (final mode in QuizMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  throw const FormatException('Invalid quiz mode.');
}

Map<String, int> _readSelectedAnswers(Map<String, dynamic> json, String key) {
  final rawValue = json[key];

  if (rawValue is! Map) {
    throw const FormatException('Invalid selected answers.');
  }

  final result = <String, int>{};

  for (final entry in rawValue.entries) {
    final questionId = entry.key;
    final selectedOption = entry.value;

    if (questionId is! String ||
        questionId.trim().isEmpty ||
        selectedOption is! num) {
      throw const FormatException('Invalid selected answer value.');
    }

    result[questionId.trim()] = selectedOption.toInt();
  }

  return result;
}

Set<String> _readStringSet(Map<String, dynamic> json, String key) {
  final rawValue = json[key];

  if (rawValue is! List) {
    throw FormatException('Invalid List value for $key.');
  }

  final result = <String>{};

  for (final item in rawValue) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('Invalid String item in $key.');
    }

    result.add(item.trim());
  }

  return result;
}
