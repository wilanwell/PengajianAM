import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_client_provider.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../data/repositories/supabase_quiz_repository.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/exceptions/quiz_failure.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_history_controller.dart';
import 'quiz_session_state.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return SupabaseQuizRepository(ref.read(supabaseClientProvider));
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
      final quizSession = await _repository.startQuiz(
        topicId: topicId,
        mode: mode,
        questionCount: questionCount,
      );

      if (quizSession.questions.isEmpty) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          requestedQuestionCount: questionCount,
          errorMessage: 'Tiada soalan tersedia untuk topik ini.',
        );

        return;
      }

      final startedAt = DateTime.now();

      _startedAt = startedAt;

      final remainingSeconds = mode == QuizMode.exam
          ? (quizSession.questions.length * 1.5 * 60).ceil()
          : null;

      state = QuizSessionState(
        status: QuizSessionStatus.ready,
        sessionId: quizSession.sessionId,
        topicId: quizSession.topicId,
        mode: quizSession.mode,
        requestedQuestionCount: quizSession.questionCount,
        questions: quizSession.questions,
        remainingSeconds: remainingSeconds,
        sessionExpiresAt: quizSession.expiresAt,
      );

      if (remainingSeconds != null) {
        _startTimer();
      }
    } on QuizFailure catch (error) {
      state = QuizSessionState(
        status: QuizSessionStatus.failure,
        topicId: topicId,
        mode: mode,
        requestedQuestionCount: questionCount,
        errorMessage: error.message,
      );
    } catch (_) {
      state = QuizSessionState(
        status: QuizSessionStatus.failure,
        topicId: topicId,
        mode: mode,
        requestedQuestionCount: questionCount,
        errorMessage:
            'Kuiz tidak dapat dimulakan. '
            'Sila cuba semula.',
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
      clearErrorMessage: true,
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

    final sessionId = state.sessionId;

    if (sessionId == null || sessionId.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Sesi kuiz tidak tersedia.');

      return;
    }

    _cancelTimer();

    state = state.copyWith(
      status: QuizSessionStatus.submitting,
      clearErrorMessage: true,
    );

    final startedAt = _startedAt ?? DateTime.now();

    final elapsedTime = DateTime.now().difference(startedAt);

    try {
      final submission = await _repository.submitQuiz(
        sessionId: sessionId,
        selectedAnswers: state.selectedAnswers,
        elapsedTime: elapsedTime,
        autoSubmitted: autoSubmitted,
      );

      /*
       * Supabase ialah sumber kebenaran markah dan XP.
       * SharedPreferences hanya menjadi cache sementara
       * sehingga Progress dipindahkan sepenuhnya.
       */
      try {
        await ref
            .read(userProgressControllerProvider.notifier)
            .recordServerQuizResult(
              result: submission.result,
              earnedXp: submission.earnedXp,
            );
      } catch (_) {
        // Keputusan server masih dianggap berjaya.
      }

      try {
        await ref
            .read(quizHistoryControllerProvider.notifier)
            .recordServerAttempt(
              attemptId: submission.attemptId,
              completedAt: submission.completedAt,
              earnedXp: submission.earnedXp,
              result: submission.result,
            );
      } catch (_) {
        // History server masih tersimpan walaupun
        // cache tempatan gagal dikemas kini.
      }

      state = state.copyWith(
        status: QuizSessionStatus.completed,
        result: submission.result,
        clearErrorMessage: true,
      );
    } on QuizFailure catch (error) {
      state = state.copyWith(
        status: QuizSessionStatus.ready,
        errorMessage: error.message,
      );

      _restartTimerWhenNeeded();
    } catch (_) {
      state = state.copyWith(
        status: QuizSessionStatus.ready,
        errorMessage:
            'Jawapan tidak dapat dihantar. '
            'Sila cuba semula.',
      );

      _restartTimerWhenNeeded();
    }
  }

  void reset() {
    _cancelTimer();
    _startedAt = null;

    state = const QuizSessionState();
  }

  void _restartTimerWhenNeeded() {
    final remainingSeconds = state.remainingSeconds;

    if (remainingSeconds != null && remainingSeconds > 0) {
      _startTimer();
    }
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
