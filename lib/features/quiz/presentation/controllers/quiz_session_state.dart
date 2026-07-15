import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_result.dart';

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
    this.topicId,
    this.mode = QuizMode.practice,
    this.requestedQuestionCount = 10,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.flaggedQuestionIds = const {},
    this.remainingSeconds,
    this.result,
    this.errorMessage,
  });

  final QuizSessionStatus status;
  final String? topicId;
  final QuizMode mode;
  final int requestedQuestionCount;
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, int> selectedAnswers;
  final Set<String> flaggedQuestionIds;
  final int? remainingSeconds;
  final QuizResult? result;
  final String? errorMessage;

  QuizQuestion? get currentQuestion {
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

  int get answeredQuestionCount => selectedAnswers.length;

  int get unansweredQuestionCount {
    return questions.length - answeredQuestionCount;
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

  bool get canGoPrevious => currentQuestionIndex > 0;

  bool get isCurrentQuestionFlagged {
    final question = currentQuestion;

    if (question == null) {
      return false;
    }

    return flaggedQuestionIds.contains(question.id);
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
    String? topicId,
    QuizMode? mode,
    int? requestedQuestionCount,
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, int>? selectedAnswers,
    Set<String>? flaggedQuestionIds,
    int? remainingSeconds,
    QuizResult? result,
    String? errorMessage,
    bool clearRemainingSeconds = false,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return QuizSessionState(
      status: status ?? this.status,
      topicId: topicId ?? this.topicId,
      mode: mode ?? this.mode,
      requestedQuestionCount:
          requestedQuestionCount ?? this.requestedQuestionCount,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      flaggedQuestionIds: flaggedQuestionIds ?? this.flaggedQuestionIds,
      remainingSeconds: clearRemainingSeconds
          ? null
          : remainingSeconds ?? this.remainingSeconds,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
