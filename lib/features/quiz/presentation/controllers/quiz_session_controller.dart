import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../data/repositories/shared_preferences_quiz_draft_repository.dart';
import '../../data/repositories/supabase_quiz_repository.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../../domain/exceptions/quiz_failure.dart';
import '../../domain/repositories/quiz_draft_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_history_controller.dart';
import 'quiz_session_state.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return SupabaseQuizRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final quizDraftRepositoryProvider = Provider<QuizDraftRepository>((ref) {
  return const SharedPreferencesQuizDraftRepository();
});

final quizDraftOwnerIdProvider = Provider<String?>((ref) {
  try {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    if (userId == null || userId.trim().isEmpty) {
      return null;
    }

    return userId.trim();
  } catch (_) {
    /*
       * Supabase mungkin belum dimulakan
       * dalam sesetengah widget/unit test.
       */
    return null;
  }
});

final quizSessionControllerProvider =
    NotifierProvider<QuizSessionController, QuizSessionState>(
      QuizSessionController.new,
    );

class QuizSessionController extends Notifier<QuizSessionState> {
  Timer? _timer;

  DateTime? _startedAt;
  DateTime? _examDeadlineAt;

  Future<void> _draftOperationQueue = Future<void>.value();

  QuizRepository get _repository {
    return ref.read(quizRepositoryProvider);
  }

  QuizDraftRepository get _draftRepository {
    return ref.read(quizDraftRepositoryProvider);
  }

  String? get _draftOwnerUserId {
    try {
      /*
     * refresh memaksa provider membaca semula
     * currentUser daripada sesi Supabase.
     *
     * Ini mengelakkan ID akaun terdahulu
     * kekal dicache selepas logout dan login
     * menggunakan akaun yang berbeza.
     *
     * Provider masih boleh dioverride dalam
     * unit dan widget test.
     */
      final userId = ref.refresh(quizDraftOwnerIdProvider);

      if (userId == null || userId.trim().isEmpty) {
        return null;
      }

      return userId.trim();
    } catch (_) {
      return null;
    }
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

    /*
     * Draft lama tidak dipadamkan sebelum
     * Supabase berjaya mencipta sesi baharu.
     *
     * Jika request gagal kerana offline,
     * draft lama masih kekal pada peranti.
     */
    _startedAt = null;
    _examDeadlineAt = null;

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
          errorMessage:
              'Tiada soalan tersedia '
              'untuk topik ini.',
        );

        return;
      }

      final startedAt = DateTime.now();

      _startedAt = startedAt;

      final remainingSeconds = mode == QuizMode.exam
          ? (quizSession.questions.length * 1.5 * 60).ceil()
          : null;

      _examDeadlineAt = remainingSeconds == null
          ? null
          : startedAt.add(Duration(seconds: remainingSeconds));

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

      /*
       * Sesi baharu sudah berjaya diwujudkan.
       * Sekarang barulah draft lama boleh
       * dipadamkan dan digantikan.
       */
      await _deleteDraftSafely();
      await _saveCurrentDraftSafely();

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

    _queueDraftSave();
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

    _queueDraftSave();
  }

  void goToQuestion(int index) {
    if (state.status != QuizSessionStatus.ready ||
        index < 0 ||
        index >= state.questions.length) {
      return;
    }

    state = state.copyWith(currentQuestionIndex: index);

    _queueDraftSave();
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

  Future<QuizDraft?> loadAvailableDraft() async {
    final ownerUserId = _draftOwnerUserId;

    if (ownerUserId == null) {
      return null;
    }

    QuizDraft? draft;

    try {
      draft = await _draftRepository.loadDraft(ownerUserId: ownerUserId);
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure(
        'Draft kuiz tidak dapat dibaca '
        'daripada peranti.',
      );
    }

    /*
     * Null hanya bermaksud draft memang
     * tidak wujud.
     */
    if (draft == null) {
      return null;
    }

    try {
      final canResume = await _isDraftResumableOnServer(draft);

      if (!canResume) {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return null;
      }

      return draft;
    } on QuizFailure catch (error) {
      /*
       * Kegagalan rangkaian tidak memadamkan
       * draft dan tidak dianggap sebagai null.
       */
      throw QuizDraftFailure(
        '${error.message} '
        'Sesi tersimpan anda masih selamat '
        'pada peranti.',
      );
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure(
        'Sesi kuiz tersimpan tidak dapat '
        'disahkan sekarang. Draft anda masih '
        'selamat pada peranti.',
      );
    }
  }

  Future<bool> restoreDraft(QuizDraft draft) async {
    final ownerUserId = _draftOwnerUserId;

    if (ownerUserId == null) {
      return false;
    }

    try {
      final canResume = await _isDraftResumableOnServer(draft);

      if (!canResume) {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return false;
      }
    } on QuizFailure catch (error) {
      throw QuizDraftFailure(
        '${error.message} '
        'Sesi tersimpan anda masih selamat '
        'pada peranti.',
      );
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure(
        'Sesi kuiz tersimpan tidak dapat '
        'disahkan sekarang. Draft anda masih '
        'selamat pada peranti.',
      );
    }

    final now = DateTime.now();

    _cancelTimer();

    _startedAt = draft.startedAt;
    _examDeadlineAt = draft.examDeadlineAt;

    final remainingSeconds = draft.remainingSecondsAt(now);

    state = QuizSessionState(
      status: QuizSessionStatus.ready,
      sessionId: draft.sessionId,
      topicId: draft.topicId,
      mode: draft.mode,
      requestedQuestionCount: draft.questionCount,
      questions: draft.questions,
      currentQuestionIndex: draft.currentQuestionIndex,
      selectedAnswers: draft.selectedAnswers,
      flaggedQuestionIds: draft.flaggedQuestionIds,
      remainingSeconds: remainingSeconds,
      sessionExpiresAt: draft.sessionExpiresAt,
    );

    if (draft.mode == QuizMode.exam) {
      if (remainingSeconds == null || remainingSeconds <= 0) {
        await submitQuiz(autoSubmitted: true);

        return true;
      }

      _startTimer();
    }

    return true;
  }

  Future<void> preserveDraftAndReset() async {
    _cancelTimer();

    /*
     * Tunggu semua autosave yang sedang
     * beratur sebelum snapshot terakhir
     * disimpan.
     */
    await _draftOperationQueue;

    /*
     * Operasi ini berlaku sebelum logout,
     * maka ID pengguna semasa masih tersedia.
     */
    await _saveCurrentDraftSafely();

    _startedAt = null;
    _examDeadlineAt = null;

    state = const QuizSessionState();
  }

  Future<void> discardDraft() async {
    _cancelTimer();

    await _deleteDraftSafely();

    _startedAt = null;
    _examDeadlineAt = null;

    state = const QuizSessionState();
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

      await _deleteDraftSafely();

      try {
        await ref
            .read(userProgressControllerProvider.notifier)
            .recordServerQuizResult(
              result: submission.result,
              earnedXp: submission.earnedXp,
            );
      } catch (_) {
        /*
         * Progress sudah disimpan
         * oleh server.
         */
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
        /*
         * Attempt sudah disimpan
         * oleh server.
         */
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

      _queueDraftSave();
      _restartTimerWhenNeeded();
    } catch (_) {
      state = state.copyWith(
        status: QuizSessionStatus.ready,
        errorMessage:
            'Jawapan tidak dapat dihantar. '
            'Sila cuba semula.',
      );

      _queueDraftSave();
      _restartTimerWhenNeeded();
    }
  }

  void reset() {
    _cancelTimer();

    _startedAt = null;
    _examDeadlineAt = null;

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

  Future<bool> _isDraftResumableOnServer(QuizDraft draft) async {
    final validation = await _repository.validateQuizSession(
      sessionId: draft.sessionId,
    );

    if (!validation.isActive) {
      return false;
    }

    if (validation.topicId != draft.topicId) {
      return false;
    }

    if (validation.mode != draft.mode) {
      return false;
    }

    if (validation.questionCount != draft.questionCount) {
      return false;
    }

    return true;
  }

  QuizDraft? _createDraftSnapshot() {
    if (state.status != QuizSessionStatus.ready) {
      return null;
    }

    final sessionId = state.sessionId;

    final topicId = state.topicId;

    final startedAt = _startedAt;

    final sessionExpiresAt = state.sessionExpiresAt;

    if (sessionId == null ||
        sessionId.trim().isEmpty ||
        topicId == null ||
        topicId.trim().isEmpty ||
        startedAt == null ||
        sessionExpiresAt == null ||
        state.questions.isEmpty) {
      return null;
    }

    try {
      return QuizDraft(
        sessionId: sessionId,
        topicId: topicId,
        mode: state.mode,
        questionCount: state.questions.length,
        questions: List.unmodifiable(state.questions),
        currentQuestionIndex: state.currentQuestionIndex,
        selectedAnswers: Map<String, int>.unmodifiable(state.selectedAnswers),
        flaggedQuestionIds: Set<String>.unmodifiable(state.flaggedQuestionIds),
        startedAt: startedAt,
        sessionExpiresAt: sessionExpiresAt,
        examDeadlineAt: _examDeadlineAt,
        savedAt: DateTime.now(),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _saveCurrentDraftSafely() async {
    final ownerUserId = _draftOwnerUserId;

    final draft = _createDraftSnapshot();

    if (ownerUserId == null || draft == null) {
      return;
    }

    try {
      await _draftRepository.saveDraft(ownerUserId: ownerUserId, draft: draft);
    } catch (_) {
      /*
       * Kegagalan autosave tidak
       * menghentikan kuiz atau logout.
       */
    }
  }

  void _queueDraftSave() {
    final ownerUserId = _draftOwnerUserId;

    final draft = _createDraftSnapshot();

    if (ownerUserId == null || draft == null) {
      return;
    }

    /*
     * Owner ID dan snapshot diambil ketika
     * operasi dimasukkan ke dalam queue.
     *
     * Queue mesti diselesaikan sebelum logout
     * supaya tiada save akaun lama berlaku
     * selepas akaun baharu log masuk.
     */
    _draftOperationQueue = _draftOperationQueue.then((_) async {
      try {
        await _draftRepository.saveDraft(
          ownerUserId: ownerUserId,
          draft: draft,
        );
      } catch (_) {
        /*
           * Queue diteruskan untuk
           * operasi save yang seterusnya.
           */
      }
    });
  }

  Future<void> _deleteDraftSafely() async {
    final ownerUserId = _draftOwnerUserId;

    if (ownerUserId == null) {
      return;
    }

    try {
      await _draftOperationQueue;

      await _draftRepository.deleteDraft(ownerUserId: ownerUserId);
    } catch (_) {
      /*
       * Kegagalan draft tidak
       * membatalkan operasi kuiz.
       */
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
