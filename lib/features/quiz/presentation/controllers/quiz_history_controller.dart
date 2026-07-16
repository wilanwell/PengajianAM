import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_quiz_history_repository.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/exceptions/quiz_history_failure.dart';
import '../../domain/repositories/quiz_history_repository.dart';
import 'quiz_history_state.dart';

final quizHistoryRepositoryProvider = Provider<QuizHistoryRepository>((ref) {
  return SupabaseQuizHistoryRepository(ref.read(supabaseClientProvider));
});

final quizHistoryControllerProvider =
    NotifierProvider<QuizHistoryController, QuizHistoryState>(
      QuizHistoryController.new,
    );

class QuizHistoryController extends Notifier<QuizHistoryState> {
  static const int maximumLoadedAttempts = 30;

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
      final snapshot = await _repository.fetchHistory(
        limit: maximumLoadedAttempts,
      );

      state = QuizHistoryState(
        status: QuizHistoryStatus.success,
        attempts: snapshot.attempts,
        totalCount: snapshot.totalCount,
        lastUpdated: snapshot.generatedAt,
      );
    } on QuizHistoryFailure catch (error) {
      state = QuizHistoryState(
        status: QuizHistoryStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = const QuizHistoryState(
        status: QuizHistoryStatus.failure,
        errorMessage: 'Sejarah kuiz tidak dapat dimuatkan.',
      );
    }
  }

  /// Digunakan untuk flow bukan Supabase atau test.
  /// Percubaan hanya dimasukkan ke state semasa.
  Future<void> recordAttempt({
    required QuizResult result,
    required int earnedXp,
  }) async {
    final attempt = QuizAttempt.create(result: result, earnedXp: earnedXp);

    _upsertAttemptLocally(attempt);
  }

  /// Attempt sudah disimpan oleh submit_quiz_attempt RPC.
  /// Method ini hanya menyegerakkan halaman sejarah
  /// tanpa menulis rekod yang sama untuk kali kedua.
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

    _upsertAttemptLocally(attempt);
  }

  void _upsertAttemptLocally(QuizAttempt attempt) {
    final alreadyExists = state.attempts.any((existingAttempt) {
      return existingAttempt.id == attempt.id;
    });

    final updatedAttempts = <QuizAttempt>[
      attempt,
      ...state.attempts.where((existingAttempt) {
        return existingAttempt.id != attempt.id;
      }),
    ];

    updatedAttempts.sort((first, second) {
      return second.completedAt.compareTo(first.completedAt);
    });

    final limitedAttempts = updatedAttempts
        .take(maximumLoadedAttempts)
        .toList(growable: false);

    final existingTotal = state.totalCount < state.attempts.length
        ? state.attempts.length
        : state.totalCount;

    final updatedTotal = alreadyExists ? existingTotal : existingTotal + 1;

    state = QuizHistoryState(
      status: QuizHistoryStatus.success,
      attempts: List<QuizAttempt>.unmodifiable(limitedAttempts),
      totalCount: updatedTotal,
      lastUpdated: DateTime.now(),
    );
  }

  Future<bool> deleteAttempt(String attemptId) async {
    try {
      await _repository.deleteAttempt(attemptId);

      final updatedAttempts = state.attempts
          .where((attempt) {
            return attempt.id != attemptId;
          })
          .toList(growable: false);

      final updatedTotal = state.totalCount > 0 ? state.totalCount - 1 : 0;

      state = QuizHistoryState(
        status: QuizHistoryStatus.success,
        attempts: List<QuizAttempt>.unmodifiable(updatedAttempts),
        totalCount: updatedTotal,
        lastUpdated: DateTime.now(),
      );

      return true;
    } on QuizHistoryFailure catch (error) {
      state = state.copyWith(
        status: QuizHistoryStatus.success,
        errorMessage: error.message,
      );

      return false;
    } catch (_) {
      state = state.copyWith(
        status: QuizHistoryStatus.success,
        errorMessage: 'Rekod kuiz tidak dapat dipadamkan.',
      );

      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      await _repository.clearHistory();

      state = QuizHistoryState(
        status: QuizHistoryStatus.success,
        lastUpdated: DateTime.now(),
      );

      return true;
    } on QuizHistoryFailure catch (error) {
      state = state.copyWith(
        status: QuizHistoryStatus.success,
        errorMessage: error.message,
      );

      return false;
    } catch (_) {
      state = state.copyWith(
        status: QuizHistoryStatus.success,
        errorMessage: 'Sejarah kuiz tidak dapat dipadamkan.',
      );

      return false;
    }
  }

  Future<void> refreshHistory() {
    return loadHistory(forceRefresh: true);
  }

  void reset() {
    state = const QuizHistoryState();
  }
}
