import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../../mistake_book/presentation/controllers/mistake_book_controller.dart';
import '../../../mistake_book/presentation/controllers/mistake_book_topic_controller.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../data/repositories/shared_preferences_quiz_draft_repository.dart';
import '../../data/repositories/supabase_quiz_repository.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/quiz_session_source.dart';
import '../../domain/entities/quiz_session_validation.dart';
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

/*
 * Provider ini dikekalkan sebagai test seam.
 *
 * Unit dan widget test boleh memberikan ID
 * pengguna palsu melalui overrideWithValue().
 *
 * Production akan membaca currentUser semasa
 * daripada Supabase.
 */
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
       * dalam sesetengah unit atau widget test.
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
  }) {
    return _startSession(
      topicId: topicId,
      mode: mode,
      source: QuizSessionSource.standard,
      questionCount: questionCount,
      loadSession: () {
        return _repository.startQuiz(
          topicId: topicId,
          mode: mode,
          questionCount: questionCount,
        );
      },
      emptyMessage:
          'Tiada soalan tersedia '
          'untuk topik ini.',
      failureMessage:
          'Kuiz tidak dapat dimulakan. '
          'Sila cuba semula.',
    );
  }

  Future<void> startMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    return _startSession(
      topicId: topicId,
      mode: QuizMode.practice,
      source: QuizSessionSource.mistakeReview,
      questionCount: questionCount,
      loadSession: () {
        return _repository.startMistakeReview(
          topicId: topicId,
          questionCount: questionCount,
        );
      },
      emptyMessage:
          'Tiada soalan yang perlu '
          'dijawab semula untuk topik ini.',
      failureMessage:
          'Latihan semula tidak dapat '
          'dimulakan. Sila cuba semula.',
    );
  }

  Future<void> _startSession({
    required String topicId,
    required QuizMode mode,
    required QuizSessionSource source,
    required int questionCount,
    required Future<QuizSession> Function() loadSession,
    required String emptyMessage,
    required String failureMessage,
  }) async {
    _cancelTimer();

    /*
     * Draft lama tidak dipadam sebelum server
     * berjaya mewujudkan sesi baharu.
     *
     * Jika request gagal, draft sebelumnya
     * masih selamat pada peranti.
     */
    _startedAt = null;
    _examDeadlineAt = null;

    state = QuizSessionState(
      status: QuizSessionStatus.loading,
      topicId: topicId,
      mode: mode,
      source: source,
      requestedQuestionCount: questionCount,
    );

    try {
      final quizSession = await loadSession();

      if (quizSession.questions.isEmpty) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          source: source,
          requestedQuestionCount: questionCount,
          errorMessage: emptyMessage,
        );

        return;
      }

      if (quizSession.source != source) {
        state = QuizSessionState(
          status: QuizSessionStatus.failure,
          topicId: topicId,
          mode: mode,
          source: source,
          requestedQuestionCount: questionCount,
          errorMessage:
              'Sumber sesi daripada server '
              'tidak sepadan.',
        );

        return;
      }

      final localNow = DateTime.now();

      /*
       * Dalam production v2, kedua-dua masa
       * ini datang daripada server.
       *
       * localNow hanya digunakan sebagai
       * fallback untuk fake repository lama
       * dalam unit test.
       */
      final serverTime = quizSession.serverTime ?? localNow;

      final startedAt = quizSession.createdAt ?? serverTime;

      final hasServerTiming =
          quizSession.serverTime != null && quizSession.createdAt != null;

      /*
       * Exam Mode mesti menggunakan deadline
       * daripada server.
       *
       * expiresAt untuk response v2 juga ialah
       * effective Exam Mode deadline.
       *
       * Pengiraan 90 saat setiap soalan hanya
       * dikekalkan sebagai fallback untuk fake
       * repository lama dalam tests.
       */
      final examDeadlineAt = mode == QuizMode.exam
          ? (quizSession.examDeadlineAt ??
                (hasServerTiming
                    ? quizSession.expiresAt
                    : startedAt.add(
                        Duration(seconds: quizSession.questions.length * 90),
                      )))
          : null;

      final remainingSeconds = examDeadlineAt == null
          ? null
          : _remainingSecondsBetween(
              deadline: examDeadlineAt,
              currentTime: serverTime,
            );

      _startedAt = startedAt;
      _examDeadlineAt = examDeadlineAt;

      state = QuizSessionState(
        status: QuizSessionStatus.ready,
        sessionId: quizSession.sessionId,
        topicId: quizSession.topicId,
        mode: quizSession.mode,
        source: quizSession.source,
        requestedQuestionCount: quizSession.questionCount,
        questions: quizSession.questions,
        remainingSeconds: remainingSeconds,
        sessionExpiresAt: quizSession.expiresAt,
      );

      /*
       * Sesi baharu sudah berjaya diwujudkan.
       * Draft lama kini boleh digantikan dengan
       * snapshot sesi baharu.
       */
      await _deleteDraftSafely();
      await _saveCurrentDraftSafely();

      if (remainingSeconds != null) {
        if (remainingSeconds <= 0) {
          /*
           * Kes luar biasa apabila response
           * diterima selepas deadline tamat.
           */
          await submitQuiz(autoSubmitted: true);
        } else {
          _startTimer();
        }
      }
    } on QuizFailure catch (error) {
      state = QuizSessionState(
        status: QuizSessionStatus.failure,
        topicId: topicId,
        mode: mode,
        source: source,
        requestedQuestionCount: questionCount,
        errorMessage: error.message,
      );
    } catch (_) {
      state = QuizSessionState(
        status: QuizSessionStatus.failure,
        topicId: topicId,
        mode: mode,
        source: source,
        requestedQuestionCount: questionCount,
        errorMessage: failureMessage,
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
     * Null bermaksud pengguna memang tidak
     * mempunyai draft pada peranti.
     */
    if (draft == null) {
      return null;
    }

    try {
      final validation = await _loadResumableValidation(draft);

      if (validation == null) {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return null;
      }

      return draft;
    } on QuizFailure catch (error) {
      /*
       * Kegagalan rangkaian tidak memadamkan
       * draft pengguna.
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

    late final QuizSessionValidation validation;

    try {
      final resolvedValidation = await _loadResumableValidation(draft);

      if (resolvedValidation == null) {
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return false;
      }

      validation = resolvedValidation;
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

    _cancelTimer();

    /*
     * createdAt dan expiresAt daripada server
     * menjadi autoriti apabila tersedia.
     */
    final effectiveStartedAt = validation.createdAt ?? draft.startedAt;

    final serverExpiresAt = validation.expiresAt ?? draft.sessionExpiresAt;

    DateTime? effectiveExamDeadlineAt;

    if (draft.mode == QuizMode.exam) {
      final draftDeadline = draft.examDeadlineAt;

      /*
       * Jangan benarkan data draft memanjangkan
       * deadline server.
       *
       * Jika deadline draft lebih awal, gunakan
       * nilai lebih awal itu. Jika lebih lewat,
       * gunakan expiry server.
       */
      if (draftDeadline != null && draftDeadline.isBefore(serverExpiresAt)) {
        effectiveExamDeadlineAt = draftDeadline;
      } else {
        effectiveExamDeadlineAt = serverExpiresAt;
      }
    }

    final remainingSeconds = effectiveExamDeadlineAt == null
        ? null
        : _remainingSecondsBetween(
            deadline: effectiveExamDeadlineAt,
            currentTime: validation.serverTime,
          );

    _startedAt = effectiveStartedAt;
    _examDeadlineAt = effectiveExamDeadlineAt;

    state = QuizSessionState(
      status: QuizSessionStatus.ready,
      sessionId: draft.sessionId,
      topicId: draft.topicId,
      mode: draft.mode,
      source: draft.source,
      requestedQuestionCount: draft.questionCount,
      questions: draft.questions,
      currentQuestionIndex: draft.currentQuestionIndex,
      selectedAnswers: draft.selectedAnswers,
      flaggedQuestionIds: draft.flaggedQuestionIds,
      remainingSeconds: remainingSeconds,
      sessionExpiresAt: serverExpiresAt,
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
     * Tunggu semua operasi autosave yang telah
     * dimasukkan ke dalam queue.
     */
    await _draftOperationQueue;

    /*
     * Simpan snapshot terakhir sebelum logout.
     * User ID masih tersedia pada tahap ini.
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

    /*
     * elapsedTime masih diberikan kepada
     * repository interface untuk compatibility
     * dengan fake repositories dan tests.
     *
     * SupabaseQuizRepository v2 tidak lagi
     * menghantar nilai ini kepada server.
     */
    final startedAt = _startedAt ?? DateTime.now();

    final elapsedTime = DateTime.now().difference(startedAt);

    try {
      final submission = await _repository.submitQuiz(
        sessionId: sessionId,
        sessionSource: state.source,
        selectedAnswers: state.selectedAnswers,
        elapsedTime: elapsedTime,
        autoSubmitted: autoSubmitted,
      );

      if (submission.result.sessionSource != state.source) {
        throw const QuizFailure(
          'Sumber keputusan daripada server '
          'tidak sepadan.',
        );
      }

      ref.invalidate(mistakeBookControllerProvider);
      ref.invalidate(mistakeBookTopicControllerProvider);

      await _deleteDraftSafely();

      if (state.source == QuizSessionSource.standard) {
        try {
          await ref
              .read(userProgressControllerProvider.notifier)
              .recordServerQuizResult(
                result: submission.result,
                earnedXp: submission.earnedXp,
              );
        } catch (_) {
          /*
           * Progress sebenar telah disimpan
           * secara transaction pada server.
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
           * Attempt sebenar telah disimpan
           * secara transaction pada server.
           */
        }
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

        /*
           * Server v2 akan menentukan sendiri
           * sama ada submission benar-benar
           * auto-submitted berdasarkan deadline
           * server.
           */
        unawaited(submitQuiz(autoSubmitted: true));

        return;
      }

      state = state.copyWith(remainingSeconds: nextValue);
    });
  }

  Future<QuizSessionValidation?> _loadResumableValidation(
    QuizDraft draft,
  ) async {
    final validation = await _repository.validateQuizSession(
      sessionId: draft.sessionId,
    );

    if (!validation.isActive) {
      return null;
    }

    if (validation.topicId != draft.topicId) {
      return null;
    }

    if (validation.mode != draft.mode) {
      return null;
    }

    if (validation.source != draft.source) {
      return null;
    }

    if (validation.questionCount != draft.questionCount) {
      return null;
    }

    return validation;
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
        source: state.source,
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
       * Kegagalan autosave tidak menghentikan
       * kuiz atau proses logout.
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
     * Owner ID dan snapshot ditentukan ketika
     * operasi dimasukkan ke queue.
     *
     * Ini mengelakkan pertukaran akaun menukar
     * pemilik operasi save yang telah beratur.
     */
    _draftOperationQueue = _draftOperationQueue.then((_) async {
      try {
        await _draftRepository.saveDraft(
          ownerUserId: ownerUserId,
          draft: draft,
        );
      } catch (_) {
        /*
           * Queue diteruskan walaupun satu
           * operasi autosave gagal.
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
       * Kegagalan operasi draft tidak
       * membatalkan submission kuiz.
       */
    }
  }

  int _remainingSecondsBetween({
    required DateTime deadline,
    required DateTime currentTime,
  }) {
    final remainingMilliseconds = deadline
        .difference(currentTime)
        .inMilliseconds;

    if (remainingMilliseconds <= 0) {
      return 0;
    }

    /*
     * Gunakan ceiling supaya baki 1–999 ms
     * masih dipaparkan sebagai satu saat.
     */
    return (remainingMilliseconds + 999) ~/ 1000;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
