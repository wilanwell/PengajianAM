import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_session_question.dart';
import '../../domain/entities/quiz_session_source.dart';

enum QuizSessionStatus {
  initial,
  loading,
  ready,
  submitting,
  completed,
  failure,
}

class QuizSessionState {
  const QuizSessionState({
    this.status = QuizSessionStatus.initial,
    this.sessionId,
    this.topicId,
    this.mode = QuizMode.practice,
    this.source = QuizSessionSource.standard,
    this.requestedQuestionCount = 10,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.flaggedQuestionIds = const {},
    this.remainingSeconds,
    this.sessionExpiresAt,
    this.result,
    this.errorMessage,
  });

  final QuizSessionStatus status;
  final String? sessionId;
  final String? topicId;
  final QuizMode mode;
  final QuizSessionSource source;
  final int requestedQuestionCount;
  final List<QuizSessionQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, int> selectedAnswers;
  final Set<String> flaggedQuestionIds;
  final int? remainingSeconds;
  final DateTime? sessionExpiresAt;
  final QuizResult? result;
  final String? errorMessage;

  QuizSessionQuestion? get currentQuestion {
    if (questions.isEmpty ||
        currentQuestionIndex < 0 ||
        currentQuestionIndex >= questions.length) {
      return null;
    }

    return questions[currentQuestionIndex];
  }

  int? get selectedAnswerForCurrentQuestion {
    final question = currentQuestion;

    if (question == null) {
      return null;
    }

    return selectedAnswers[question.id];
  }

  int get answeredQuestionCount {
    return selectedAnswers.length;
  }

  int get unansweredQuestionCount {
    final count = questions.length - answeredQuestionCount;

    return count < 0 ? 0 : count;
  }

  int get flaggedQuestionCount {
    return flaggedQuestionIds.length;
  }

  double get progress {
    if (questions.isEmpty) {
      return 0;
    }

    return (currentQuestionIndex + 1) / questions.length;
  }

  bool get isLastQuestion {
    return questions.isNotEmpty && currentQuestionIndex == questions.length - 1;
  }

  bool get canGoPrevious {
    return currentQuestionIndex > 0;
  }

  bool get isCurrentQuestionFlagged {
    final question = currentQuestion;

    if (question == null) {
      return false;
    }

    return flaggedQuestionIds.contains(question.id);
  }

  bool isQuestionAnswered(int index) {
    if (index < 0 || index >= questions.length) {
      return false;
    }

    return selectedAnswers.containsKey(questions[index].id);
  }

  bool isQuestionFlagged(int index) {
    if (index < 0 || index >= questions.length) {
      return false;
    }

    return flaggedQuestionIds.contains(questions[index].id);
  }

  String? get formattedRemainingTime {
    final seconds = remainingSeconds;

    if (seconds == null) {
      return null;
    }

    final minutesPart = seconds ~/ 60;
    final secondsPart = seconds % 60;

    return '${minutesPart.toString().padLeft(2, '0')}:'
        '${secondsPart.toString().padLeft(2, '0')}';
  }

  QuizSessionState copyWith({
    QuizSessionStatus? status,
    String? sessionId,
    String? topicId,
    QuizMode? mode,
    QuizSessionSource? source,
    int? requestedQuestionCount,
    List<QuizSessionQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, int>? selectedAnswers,
    Set<String>? flaggedQuestionIds,
    int? remainingSeconds,
    DateTime? sessionExpiresAt,
    QuizResult? result,
    String? errorMessage,
    bool clearSessionId = false,
    bool clearRemainingSeconds = false,
    bool clearSessionExpiresAt = false,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return QuizSessionState(
      status: status ?? this.status,
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      topicId: topicId ?? this.topicId,
      mode: mode ?? this.mode,
      source: source ?? this.source,
      requestedQuestionCount:
          requestedQuestionCount ?? this.requestedQuestionCount,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      flaggedQuestionIds: flaggedQuestionIds ?? this.flaggedQuestionIds,
      remainingSeconds: clearRemainingSeconds
          ? null
          : remainingSeconds ?? this.remainingSeconds,
      sessionExpiresAt: clearSessionExpiresAt
          ? null
          : sessionExpiresAt ?? this.sessionExpiresAt,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
