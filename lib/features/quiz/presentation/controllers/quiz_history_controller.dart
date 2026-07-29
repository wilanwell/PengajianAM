import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_quiz_history_repository.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/exceptions/quiz_history_failure.dart';
import '../../domain/repositories/quiz_history_repository.dart';
import 'quiz_history_state.dart';

final quizHistoryRepositoryProvider = Provider<QuizHistoryRepository>((ref) {
  return SupabaseQuizHistoryRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final quizHistoryControllerProvider =
    NotifierProvider<QuizHistoryController, QuizHistoryState>(
      QuizHistoryController.new,
    );

class QuizHistoryController extends Notifier<QuizHistoryState> {
  static const int maximumLoadedAttempts = 30;

  Future<void>? _activeRequest;

  int _requestGeneration = 0;

  QuizHistoryRepository get _repository {
    return ref.read(quizHistoryRepositoryProvider);
  }

  @override
  QuizHistoryState build() {
    ref.onDispose(() {
      _requestGeneration++;
      _activeRequest = null;
    });

    return const QuizHistoryState();
  }

  Future<void> loadHistory({bool forceRefresh = false}) {
    final currentRequest = _activeRequest;

    if (!forceRefresh && currentRequest != null) {
      return currentRequest;
    }

    if (!forceRefresh && state.status == QuizHistoryStatus.success) {
      return Future<void>.value();
    }

    late final Future<void> request;

    request = _loadHistoryInternal().whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    });

    _activeRequest = request;

    return request;
  }

  Future<void> _loadHistoryInternal() async {
    final requestGeneration = ++_requestGeneration;

    final existingAttempts = state.attempts;

    final existingTotalCount = state.totalCount;

    final existingLastUpdated = state.lastUpdated;

    state = QuizHistoryState(
      status: QuizHistoryStatus.loading,
      attempts: existingAttempts,
      totalCount: existingTotalCount,
      lastUpdated: existingLastUpdated,
    );

    late final QuizHistoryState resultState;

    try {
      final snapshot = await _repository.fetchHistory(
        limit: maximumLoadedAttempts,
      );

      resultState = QuizHistoryState(
        status: QuizHistoryStatus.success,
        attempts: snapshot.attempts,
        totalCount: snapshot.totalCount,
        lastUpdated: snapshot.generatedAt,
      );
    } on QuizHistoryFailure catch (error) {
      resultState = QuizHistoryState(
        status: QuizHistoryStatus.failure,
        attempts: existingAttempts,
        totalCount: existingTotalCount,
        lastUpdated: existingLastUpdated,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = QuizHistoryState(
        status: QuizHistoryStatus.failure,
        attempts: existingAttempts,
        totalCount: existingTotalCount,
        lastUpdated: existingLastUpdated,
        errorMessage:
            'Sejarah kuiz tidak dapat '
            'dimuatkan.',
      );
    }

    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }
  }

  Future<void> recordAttempt({
    required QuizResult result,
    required int earnedXp,
  }) async {
    final attempt = QuizAttempt.create(result: result, earnedXp: earnedXp);

    _upsertAttemptLocally(attempt);
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

    _upsertAttemptLocally(attempt);
  }

  void _upsertAttemptLocally(QuizAttempt attempt) {
    _invalidatePendingRequest();

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
    final operationGeneration = _beginStateOperation();

    try {
      await _repository.deleteAttempt(attemptId);

      if (operationGeneration == _requestGeneration) {
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
      }

      return true;
    } on QuizHistoryFailure catch (error) {
      if (operationGeneration == _requestGeneration) {
        state = state.copyWith(
          status: QuizHistoryStatus.success,
          errorMessage: error.message,
        );
      }

      return false;
    } catch (_) {
      if (operationGeneration == _requestGeneration) {
        state = state.copyWith(
          status: QuizHistoryStatus.success,
          errorMessage:
              'Rekod kuiz tidak dapat '
              'dipadamkan.',
        );
      }

      return false;
    }
  }

  Future<bool> clearHistory() async {
    final operationGeneration = _beginStateOperation();

    try {
      await _repository.clearHistory();

      if (operationGeneration == _requestGeneration) {
        state = QuizHistoryState(
          status: QuizHistoryStatus.success,
          lastUpdated: DateTime.now(),
        );
      }

      return true;
    } on QuizHistoryFailure catch (error) {
      if (operationGeneration == _requestGeneration) {
        state = state.copyWith(
          status: QuizHistoryStatus.success,
          errorMessage: error.message,
        );
      }

      return false;
    } catch (_) {
      if (operationGeneration == _requestGeneration) {
        state = state.copyWith(
          status: QuizHistoryStatus.success,
          errorMessage:
              'Sejarah kuiz tidak dapat '
              'dipadamkan.',
        );
      }

      return false;
    }
  }

  Future<void> refreshHistory() {
    return loadHistory(forceRefresh: true);
  }

  void reset() {
    _invalidatePendingRequest();

    state = const QuizHistoryState();
  }

  int _beginStateOperation() {
    _requestGeneration++;
    _activeRequest = null;

    return _requestGeneration;
  }

  void _invalidatePendingRequest() {
    _requestGeneration++;
    _activeRequest = null;
  }
}
