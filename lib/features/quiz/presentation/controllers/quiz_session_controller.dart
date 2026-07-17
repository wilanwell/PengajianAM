import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_client_provider.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../data/repositories/shared_preferences_quiz_draft_repository.dart';
import '../../data/repositories/supabase_quiz_repository.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/exceptions/quiz_failure.dart';
import '../../domain/repositories/quiz_draft_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_history_controller.dart';
import 'quiz_session_state.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return SupabaseQuizRepository(ref.read(supabaseClientProvider));
});

final quizDraftRepositoryProvider = Provider<QuizDraftRepository>((ref) {
  return const SharedPreferencesQuizDraftRepository();
});

/// Provider ini diasingkan supaya unit test boleh
/// menggunakan ID pengguna palsu tanpa Supabase sebenar.
final quizDraftOwnerIdProvider = Provider<String?>((ref) {
  return ref.read(supabaseClientProvider).auth.currentUser?.id;
});

final quizSessionControllerProvider =
    NotifierProvider<QuizSessionController, QuizSessionState>(
      QuizSessionController.new,
    );

class QuizSessionController extends Notifier<QuizSessionState> {
  Timer? _timer;

  DateTime? _startedAt;
  DateTime? _examDeadlineAt;

  /// Semua operasi save disusun supaya save lama
  /// tidak menimpa save yang lebih baharu.
  Future<void> _draftOperationQueue = Future<void>.value();

  QuizRepository get _repository {
    return ref.read(quizRepositoryProvider);
  }

  QuizDraftRepository get _draftRepository {
    return ref.read(quizDraftRepositoryProvider);
  }

  String? get _draftOwnerUserId {
    try {
      final userId = ref.read(quizDraftOwnerIdProvider);

      if (userId == null || userId.trim().isEmpty) {
        return null;
      }

      return userId.trim();
    } catch (_) {
      /*
       * Unit test lama yang tidak menyediakan
       * Supabase masih boleh berjalan.
       */
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
     * Memulakan kuiz baharu bermaksud draft lama
     * tidak lagi diperlukan.
     */
    await _deleteDraftSafely();

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
          errorMessage: 'Tiada soalan tersedia untuk topik ini.',
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
       * Pastikan draft pertama disimpan sebelum
       * pengguna mula menjawab.
       */
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

  /// Membaca draft pengguna semasa tanpa
  /// mengubah state kuiz.
  Future<QuizDraft?> loadAvailableDraft() async {
    final ownerUserId = _draftOwnerUserId;

    if (ownerUserId == null) {
      return null;
    }

    try {
      final draft = await _draftRepository.loadDraft(ownerUserId: ownerUserId);

      if (draft == null) {
        return null;
      }

      final now = DateTime.now();

      /*
       * Jika session Supabase sendiri telah tamat,
       * draft tidak lagi boleh digunakan.
       */
      if (!draft.sessionExpiresAt.isAfter(now)) {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return null;
      }

      return draft;
    } catch (_) {
      /*
       * Draft ialah kemudahan tambahan.
       * Kegagalan membaca draft tidak patut
       * menghalang pengguna membuka aplikasi.
       */
      return null;
    }
  }

  /// Memulihkan state daripada draft yang dipilih
  /// oleh pengguna.
  Future<bool> restoreDraft(QuizDraft draft) async {
    final ownerUserId = _draftOwnerUserId;

    if (ownerUserId == null) {
      return false;
    }

    final now = DateTime.now();

    if (!draft.sessionExpiresAt.isAfter(now)) {
      try {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);
      } catch (_) {
        // Draft tamat tempoh tetap tidak dipulihkan.
      }

      return false;
    }

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
        /*
         * Timer exam telah tamat ketika aplikasi
         * ditutup. Jawapan dihantar secara automatik
         * selagi session Supabase masih aktif.
         */
        await submitQuiz(autoSubmitted: true);

        return true;
      }

      _startTimer();
    }

    return true;
  }

  /// Menyimpan keadaan terkini sebelum pengguna
  /// keluar daripada halaman kuiz.
  ///
  /// Draft dikekalkan supaya boleh disambung
  /// apabila pengguna kembali.
  Future<void> preserveDraftAndReset() async {
    _cancelTimer();

    /*
   * Tunggu autosave terdahulu selesai.
   */
    await _draftOperationQueue;

    /*
   * Simpan snapshot terakhir untuk memastikan
   * jawapan dan kedudukan terkini tidak hilang.
   */
    await _saveCurrentDraftSafely();

    _startedAt = null;
    _examDeadlineAt = null;

    state = const QuizSessionState();
  }

  /// Digunakan apabila pengguna memilih untuk
  /// membuang sesi lama atau keluar daripada kuiz.
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

      /*
       * Tunggu semua autosave selesai dahulu,
       * kemudian padam draft supaya save lama
       * tidak mencipta semula draft selepas submit.
       */
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
         * Keputusan dan progress sudah disimpan
         * oleh server. Kegagalan refresh UI tidak
         * membatalkan submission.
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
         * Attempt sudah tersimpan di Supabase.
         * Cache state sejarah boleh dimuatkan semula.
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

  /// Reset state sahaja. Gunakan discardDraft()
  /// apabila draft juga perlu dipadamkan.
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

      /*
         * Timer tidak disimpan setiap saat.
         * Draft menyimpan examDeadlineAt, jadi masa
         * baki boleh dikira semula ketika restore.
         */
    });
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
       * Autosave tidak boleh menghentikan
       * pengguna daripada menjawab kuiz.
       */
    }
  }

  void _queueDraftSave() {
    final ownerUserId = _draftOwnerUserId;

    final draft = _createDraftSnapshot();

    if (ownerUserId == null || draft == null) {
      return;
    }

    _draftOperationQueue = _draftOperationQueue.then((_) async {
      try {
        await _draftRepository.saveDraft(
          ownerUserId: ownerUserId,
          draft: draft,
        );
      } catch (_) {
        /*
           * Operasi autosave gagal secara senyap.
           * Queue tetap diteruskan untuk save baharu.
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
      /*
       * Pastikan semua autosave terdahulu selesai
       * sebelum delete dijalankan.
       */
      await _draftOperationQueue;

      await _draftRepository.deleteDraft(ownerUserId: ownerUserId);
    } catch (_) {
      /*
       * Keputusan kuiz tidak patut dianggap gagal
       * hanya kerana local draft gagal dipadamkan.
       */
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
