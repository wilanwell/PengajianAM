import 'quiz_mode.dart';
import 'quiz_session_question.dart';
import 'quiz_session_source.dart';

class QuizSession {
  const QuizSession({
    required this.sessionId,
    required this.topicId,
    required this.mode,
    required this.questionCount,
    required this.expiresAt,
    required this.questions,
    this.source = QuizSessionSource.standard,
    this.createdAt,
    this.serverTime,
    this.hardExpiresAt,
    this.examDeadlineAt,
  }) : assert(questionCount > 0);

  final String sessionId;
  final String topicId;
  final QuizMode mode;
  final QuizSessionSource source;
  final int questionCount;

  /// Effective expiry yang diberikan oleh server.
  ///
  /// Practice Mode:
  /// hard session expiry.
  ///
  /// Exam Mode:
  /// exam deadline.
  final DateTime expiresAt;

  /// Masa sesi diwujudkan pada server.
  final DateTime? createdAt;

  /// Masa server ketika response dijana.
  final DateTime? serverTime;

  /// Hard session expiry asal.
  final DateTime? hardExpiresAt;

  /// Deadline khusus Exam Mode.
  final DateTime? examDeadlineAt;

  final List<QuizSessionQuestion> questions;
}
