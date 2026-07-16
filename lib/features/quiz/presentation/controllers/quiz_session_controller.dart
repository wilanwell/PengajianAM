import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../data/repositories/mock_quiz_repository.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/services/quiz_randomizer.dart';
import 'quiz_history_controller.dart';
import 'quiz_session_state.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return const MockQuizRepository();
});

final quizRandomizerProvider = Provider<QuizRandomizer>((ref) {
  return const QuizRandomizer();
});

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

  QuizRandomizer get _randomizer {
    return ref.read(quizRandomizerProvider);
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
      final rawQuestions = await _repository.getQuestions(
        topicId: topicId,
        limit: questionCount,
      );

      if (rawQuestions.isEmpty) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          requestedQuestionCount: questionCount,
          errorMessage: 'Tiada soalan tersedia untuk topik ini.',
        );

        return;
      }

      if (rawQuestions.length < questionCount) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          requestedQuestionCount: questionCount,
          errorMessage:
              'Hanya ${rawQuestions.length} soalan unik tersedia '
              'untuk topik ini.',
        );

        return;
      }

      final uniqueQuestionIds = rawQuestions
          .map((question) => question.id)
          .toSet();

      if (uniqueQuestionIds.length != rawQuestions.length) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          requestedQuestionCount: questionCount,
          errorMessage: 'Bank soalan mengandungi rekod yang berulang.',
        );

        return;
      }

      final startedAt = DateTime.now();

      final currentUser = ref.read(userProgressControllerProvider);

      final shuffleSeed = Object.hash(
        currentUser.userId,
        topicId,
        mode.name,
        questionCount,
        startedAt.microsecondsSinceEpoch,
      );

      final randomizedQuestions = _randomizer.randomize(
        questions: rawQuestions,
        seed: shuffleSeed,
      );

      _startedAt = startedAt;

      final remainingSeconds = mode == QuizMode.exam
          ? (randomizedQuestions.length * 1.5 * 60).ceil()
          : null;

      state = QuizSessionState(
        status: QuizSessionStatus.ready,
        topicId: topicId,
        mode: mode,
        requestedQuestionCount: questionCount,
        questions: randomizedQuestions,
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
    if (state.status != QuizSessionStatus.ready) {
      return;
    }

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
    if (state.status != QuizSessionStatus.ready ||
        index < 0 ||
        index >= state.questions.length) {
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

    var topicCode = '';
    var topicTitle = 'Topik Pengajian AM';

    final topicsState = ref.read(topicsControllerProvider);

    for (final topic in topicsState.topics) {
      if (topic.id == state.topicId) {
        topicCode = topic.code;
        topicTitle = topic.title;
        break;
      }
    }

    final result = QuizResult(
      topicId: state.topicId ?? '',
      topicCode: topicCode,
      topicTitle: topicTitle,
      mode: state.mode,
      questions: List.unmodifiable(state.questions),
      selectedAnswers: selectedAnswers,
      correctAnswers: correctAnswers,
      answeredQuestions: selectedAnswers.length,
      elapsedTime: DateTime.now().difference(startedAt),
      autoSubmitted: autoSubmitted,
    );

    final progressController = ref.read(
      userProgressControllerProvider.notifier,
    );

    final earnedXp = progressController.calculateEarnedXp(result);

    await progressController.recordQuizResult(result);

    await ref
        .read(quizHistoryControllerProvider.notifier)
        .recordAttempt(result: result, earnedXp: earnedXp);

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
