import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quiz_mode.dart';
import 'quiz_setup_state.dart';

final quizSetupControllerProvider =
    NotifierProvider<QuizSetupController, QuizSetupState>(
      QuizSetupController.new,
    );

class QuizSetupController extends Notifier<QuizSetupState> {
  static const List<int> allowedQuestionCounts = [10, 20];

  @override
  QuizSetupState build() {
    return const QuizSetupState();
  }

  void selectTopic(String? topicId) {
    final normalizedTopicId = topicId?.trim();

    if (normalizedTopicId == null || normalizedTopicId.isEmpty) {
      state = state.copyWith(clearSelectedTopic: true);

      return;
    }

    state = state.copyWith(selectedTopicId: normalizedTopicId);
  }

  void selectMode(QuizMode mode) {
    state = state.copyWith(mode: mode);
  }

  void selectQuestionCount(int count) {
    if (!allowedQuestionCounts.contains(count)) {
      return;
    }

    state = state.copyWith(questionCount: count);
  }

  void applyDefaults({required QuizMode mode, required int questionCount}) {
    if (!allowedQuestionCounts.contains(questionCount)) {
      return;
    }

    state = state.copyWith(mode: mode, questionCount: questionCount);
  }

  void reset() {
    state = const QuizSetupState();
  }
}
