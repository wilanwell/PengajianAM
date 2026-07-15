import 'quiz_result.dart';

class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.completedAt,
    required this.earnedXp,
    required this.result,
  }) : assert(earnedXp >= 0);

  static const int schemaVersion = 1;

  final String id;
  final DateTime completedAt;
  final int earnedXp;
  final QuizResult result;

  factory QuizAttempt.create({
    required QuizResult result,
    required int earnedXp,
    DateTime? completedAt,
  }) {
    final completionTime = completedAt ?? DateTime.now();

    return QuizAttempt(
      id: 'attempt-${completionTime.microsecondsSinceEpoch}',
      completedAt: completionTime,
      earnedXp: earnedXp,
      result: result,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'earnedXp': earnedXp,
      'result': result.toJson(),
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];

    if (version is! num || version.toInt() != schemaVersion) {
      throw const FormatException('Unsupported quiz attempt schema version.');
    }

    final completedAtValue = json['completedAt'];

    if (completedAtValue is! String) {
      throw const FormatException('Invalid quiz attempt completion date.');
    }

    final completedAt = DateTime.tryParse(completedAtValue);

    if (completedAt == null) {
      throw const FormatException('Invalid quiz attempt completion date.');
    }

    final rawResult = json['result'];

    if (rawResult is! Map) {
      throw const FormatException('Invalid quiz result data.');
    }

    final id = json['id'];
    final earnedXp = json['earnedXp'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Invalid quiz attempt ID.');
    }

    if (earnedXp is! num) {
      throw const FormatException('Invalid quiz attempt XP.');
    }

    return QuizAttempt(
      id: id,
      completedAt: completedAt,
      earnedXp: earnedXp.toInt(),
      result: QuizResult.fromJson(Map<String, dynamic>.from(rawResult)),
    );
  }
}
