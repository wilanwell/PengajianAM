import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/shared_preferences_quiz_history_repository.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/repositories/quiz_history_repository.dart';
import 'quiz_history_state.dart';

final quizHistoryRepositoryProvider = Provider<QuizHistoryRepository>((ref) {
  return SharedPreferencesQuizHistoryRepository();
});

final quizHistoryControllerProvider =
    NotifierProvider<QuizHistoryController, QuizHistoryState>(
      QuizHistoryController.new,
    );

class QuizHistoryController extends Notifier<QuizHistoryState> {
  static const int maximumStoredAttempts = 30;

  QuizHistoryRepository get _repository {
    return ref.read(quizHistoryRepositoryProvider);
  }

  @override
  QuizHistoryState build() {
    return const QuizHistoryState();
  }

  Future<void> loadHistory({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == QuizHistoryStatus.loading ||
            state.status == QuizHistoryStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: QuizHistoryStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final attempts = await _repository.loadAttempts();

      state = QuizHistoryState(
        status: QuizHistoryStatus.success,
        attempts: attempts,
      );
    } catch (_) {
      state = const QuizHistoryState(
        status: QuizHistoryStatus.failure,
        errorMessage: 'Sejarah kuiz tidak dapat dimuatkan.',
      );
    }
  }

  Future<void> recordAttempt({
    required QuizResult result,
    required int earnedXp,
  }) async {
    final attempt = QuizAttempt.create(result: result, earnedXp: earnedXp);

    await _storeAttempt(attempt);
  }

  Future<void> recordServerAttempt({
    required String attemptId,
    required DateTime completedAt,
    required int earnedXp,
    required QuizResult result,
  }) async {
    final attempt = QuizAttempt(
      id: attemptId,
      completedAt: completedAt,
      earnedXp: earnedXp,
      result: result,
    );

    await _storeAttempt(attempt);
  }

  Future<void> _storeAttempt(QuizAttempt attempt) async {
    if (state.status != QuizHistoryStatus.success) {
      await loadHistory(
        forceRefresh: state.status == QuizHistoryStatus.failure,
      );
    }

    final updatedAttempts = <QuizAttempt>[
      attempt,
      ...state.attempts.where((existingAttempt) {
        return existingAttempt.id != attempt.id;
      }),
    ];

    final limitedAttempts = updatedAttempts
        .take(maximumStoredAttempts)
        .toList(growable: false);

    state = QuizHistoryState(
      status: QuizHistoryStatus.success,
      attempts: List<QuizAttempt>.unmodifiable(limitedAttempts),
    );

    await _saveSafely();
  }

  Future<void> deleteAttempt(String attemptId) async {
    final updatedAttempts = state.attempts
        .where((attempt) => attempt.id != attemptId)
        .toList(growable: false);

    state = QuizHistoryState(
      status: QuizHistoryStatus.success,
      attempts: List<QuizAttempt>.unmodifiable(updatedAttempts),
    );

    await _saveSafely();
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearAttempts();

      state = const QuizHistoryState(status: QuizHistoryStatus.success);
    } catch (_) {
      state = state.copyWith(
        status: QuizHistoryStatus.failure,
        errorMessage: 'Sejarah kuiz tidak dapat dipadamkan.',
      );
    }
  }

  Future<void> refreshHistory() {
    return loadHistory(forceRefresh: true);
  }

  void reset() {
    state = const QuizHistoryState();
  }

  Future<void> _saveSafely() async {
    try {
      await _repository.saveAttempts(state.attempts);
    } catch (_) {
      // History kekal dalam memori untuk sesi semasa.
    }
  }
}
