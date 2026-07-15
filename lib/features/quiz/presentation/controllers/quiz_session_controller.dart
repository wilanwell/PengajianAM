import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_quiz_repository.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import 'quiz_session_state.dart';

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => const MockQuizRepository(),
);

final quizSessionControllerProvider =
    NotifierProvider<QuizSessionController, QuizSessionState>(
      QuizSessionController.new,
    );

class QuizSessionController extends Notifier<QuizSessionState> {
  Timer? _timer;
  DateTime? _startedAt;

  QuizRepository get _repository {
    return ref.read(quizRepositoryProvider);
  }

  @override
  QuizSessionState build() {
    ref.onDispose(_cancelTimer);

    return const QuizSessionState();
  }

  Future<void> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    _cancelTimer();

    state = QuizSessionState(
      status: QuizSessionStatus.loading,
      topicId: topicId,
      mode: mode,
      requestedQuestionCount: questionCount,
    );

    try {
      final questions = await _repository.getQuestions(
        topicId: topicId,
        limit: questionCount,
      );

      if (questions.isEmpty) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          requestedQuestionCount: questionCount,
          errorMessage: 'Tiada soalan tersedia untuk topik ini.',
        );

        return;
      }

      _startedAt = DateTime.now();

      final remainingSeconds = mode == QuizMode.exam
          ? (questionCount * 1.5 * 60).ceil()
          : null;

      state = QuizSessionState(
        status: QuizSessionStatus.ready,
        topicId: topicId,
        mode: mode,
        requestedQuestionCount: questionCount,
        questions: questions,
        remainingSeconds: remainingSeconds,
      );

      if (remainingSeconds != null) {
        _startTimer();
      }
    } catch (_) {
      state = QuizSessionState(
        status: QuizSessionStatus.failure,
        topicId: topicId,
        mode: mode,
        requestedQuestionCount: questionCount,
        errorMessage: 'Kuiz tidak dapat dimulakan. Sila cuba semula.',
      );
    }
  }

  void selectAnswer(int optionIndex) {
    if (state.status != QuizSessionStatus.ready) {
      return;
    }

    final question = state.currentQuestion;

    if (question == null ||
        optionIndex < 0 ||
        optionIndex >= question.options.length) {
      return;
    }

    final updatedAnswers = Map<String, int>.from(state.selectedAnswers);

    updatedAnswers[question.id] = optionIndex;

    state = state.copyWith(
      selectedAnswers: Map<String, int>.unmodifiable(updatedAnswers),
    );
  }

  void toggleFlagCurrentQuestion() {
    final question = state.currentQuestion;

    if (question == null) {
      return;
    }

    final updatedFlags = Set<String>.from(state.flaggedQuestionIds);

    if (!updatedFlags.add(question.id)) {
      updatedFlags.remove(question.id);
    }

    state = state.copyWith(
      flaggedQuestionIds: Set<String>.unmodifiable(updatedFlags),
    );
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= state.questions.length) {
      return;
    }

    state = state.copyWith(currentQuestionIndex: index);
  }

  void previousQuestion() {
    if (!state.canGoPrevious) {
      return;
    }

    goToQuestion(state.currentQuestionIndex - 1);
  }

  void nextQuestion() {
    if (state.isLastQuestion) {
      return;
    }

    goToQuestion(state.currentQuestionIndex + 1);
  }

  Future<void> submitQuiz({bool autoSubmitted = false}) async {
    if (state.status != QuizSessionStatus.ready) {
      return;
    }

    _cancelTimer();

    state = state.copyWith(
      status: QuizSessionStatus.submitting,
      clearErrorMessage: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final selectedAnswers = Map<String, int>.unmodifiable(
      state.selectedAnswers,
    );

    final correctAnswers = state.questions.where((question) {
      return question.isCorrect(selectedAnswers[question.id]);
    }).length;

    final startedAt = _startedAt ?? DateTime.now();

    final result = QuizResult(
      topicId: state.topicId ?? '',
      mode: state.mode,
      questions: List.unmodifiable(state.questions),
      selectedAnswers: selectedAnswers,
      correctAnswers: correctAnswers,
      answeredQuestions: selectedAnswers.length,
      elapsedTime: DateTime.now().difference(startedAt),
      autoSubmitted: autoSubmitted,
    );

    await ref
        .read(userProgressControllerProvider.notifier)
        .recordQuizResult(result);

    state = state.copyWith(status: QuizSessionStatus.completed, result: result);
  }

  void reset() {
    _cancelTimer();
    _startedAt = null;
    state = const QuizSessionState();
  }

  void _startTimer() {
    _cancelTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != QuizSessionStatus.ready ||
          state.remainingSeconds == null) {
        _cancelTimer();
        return;
      }

      final nextValue = state.remainingSeconds! - 1;

      if (nextValue <= 0) {
        state = state.copyWith(remainingSeconds: 0);

        unawaited(submitQuiz(autoSubmitted: true));

        return;
      }

      state = state.copyWith(remainingSeconds: nextValue);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
