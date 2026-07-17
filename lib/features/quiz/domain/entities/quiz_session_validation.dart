import 'quiz_mode.dart';

enum QuizSessionServerStatus { active, submitted, expired, notFound }

class QuizSessionValidation {
  const QuizSessionValidation({
    required this.sessionId,
    required this.status,
    required this.canResume,
    required this.serverTime,
    this.topicId,
    this.mode,
    this.questionCount,
    this.createdAt,
    this.expiresAt,
    this.submittedAt,
  });

  final String sessionId;
  final QuizSessionServerStatus status;
  final bool canResume;
  final DateTime serverTime;

  final String? topicId;
  final QuizMode? mode;
  final int? questionCount;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;

  bool get isActive {
    return status == QuizSessionServerStatus.active && canResume;
  }

  factory QuizSessionValidation.fromJson(Map<String, dynamic> json) {
    final sessionId = _readRequiredString(json, 'sessionId');

    final status = _readStatus(json, 'status');

    final canResume = _readRequiredBool(json, 'canResume');

    final serverTime = _readDateTime(json, 'serverTime');

    final expectedCanResume = status == QuizSessionServerStatus.active;

    if (canResume != expectedCanResume) {
      throw const FormatException('Quiz session resume status is invalid.');
    }

    if (status == QuizSessionServerStatus.notFound) {
      return QuizSessionValidation(
        sessionId: sessionId,
        status: status,
        canResume: false,
        serverTime: serverTime,
      );
    }

    final topicId = _readRequiredString(json, 'topicId');

    final mode = _readMode(json, 'mode');

    final questionCount = _readRequiredInt(json, 'questionCount', minimum: 1);

    final createdAt = _readDateTime(json, 'createdAt');

    final expiresAt = _readDateTime(json, 'expiresAt');

    final submittedAt = _readOptionalDateTime(json, 'submittedAt');

    if (!expiresAt.isAfter(createdAt)) {
      throw const FormatException('Quiz session expiry is invalid.');
    }

    if (status == QuizSessionServerStatus.active &&
        !expiresAt.isAfter(serverTime)) {
      throw const FormatException('Active quiz session has expired.');
    }

    if (status == QuizSessionServerStatus.expired &&
        expiresAt.isAfter(serverTime)) {
      throw const FormatException('Expired quiz session is still active.');
    }

    if (status == QuizSessionServerStatus.submitted && submittedAt == null) {
      throw const FormatException(
        'Submitted quiz session has no '
        'submission time.',
      );
    }

    return QuizSessionValidation(
      sessionId: sessionId,
      status: status,
      canResume: canResume,
      serverTime: serverTime,
      topicId: topicId,
      mode: mode,
      questionCount: questionCount,
      createdAt: createdAt,
      expiresAt: expiresAt,
      submittedAt: submittedAt,
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

bool _readRequiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is! bool) {
    throw FormatException('Invalid Boolean value for $key.');
  }

  return value;
}

int _readRequiredInt(
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

  final result = DateTime.tryParse(rawValue);

  if (result == null) {
    throw FormatException('Invalid DateTime value for $key.');
  }

  return result;
}

DateTime? _readOptionalDateTime(Map<String, dynamic> json, String key) {
  final rawValue = json[key];

  if (rawValue == null) {
    return null;
  }

  if (rawValue is! String || rawValue.trim().isEmpty) {
    throw FormatException(
      'Invalid optional DateTime value '
      'for $key.',
    );
  }

  final result = DateTime.tryParse(rawValue);

  if (result == null) {
    throw FormatException(
      'Invalid optional DateTime value '
      'for $key.',
    );
  }

  return result;
}

QuizMode _readMode(Map<String, dynamic> json, String key) {
  final value = _readRequiredString(json, key);

  for (final mode in QuizMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  throw const FormatException('Invalid quiz session mode.');
}

QuizSessionServerStatus _readStatus(Map<String, dynamic> json, String key) {
  final value = _readRequiredString(json, key);

  return switch (value) {
    'active' => QuizSessionServerStatus.active,
    'submitted' => QuizSessionServerStatus.submitted,
    'expired' => QuizSessionServerStatus.expired,
    'not_found' => QuizSessionServerStatus.notFound,
    _ => throw const FormatException('Invalid quiz session status.'),
  };
}
