import '../../domain/entities/quiz_mode.dart';

class QuizSetupState {
  const QuizSetupState({
    this.selectedTopicId,
    this.mode = QuizMode.practice,
    this.questionCount = 10,
  });

  final String? selectedTopicId;
  final QuizMode mode;
  final int questionCount;

  bool get canContinue {
    return selectedTopicId != null && selectedTopicId!.trim().isNotEmpty;
  }

  int? get durationMinutes {
    if (mode == QuizMode.practice) {
      return null;
    }

    return (questionCount * 1.5).ceil();
  }

  QuizSetupState copyWith({
    String? selectedTopicId,
    QuizMode? mode,
    int? questionCount,
    bool clearSelectedTopic = false,
  }) {
    return QuizSetupState(
      selectedTopicId: clearSelectedTopic
          ? null
          : selectedTopicId ?? this.selectedTopicId,
      mode: mode ?? this.mode,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}
