import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_leaderboard_preference_repository.dart';
import '../../domain/entities/leaderboard_preference.dart';
import '../../domain/exceptions/leaderboard_preference_failure.dart';
import '../../domain/repositories/leaderboard_preference_repository.dart';
import 'leaderboard_preference_state.dart';

final leaderboardPreferenceRepositoryProvider =
    Provider<LeaderboardPreferenceRepository>((ref) {
      return SupabaseLeaderboardPreferenceRepository(
        ref.read(supabaseClientProvider),
        ref.read(networkRequestExecutorProvider),
      );
    });

final leaderboardPreferenceControllerProvider =
    NotifierProvider<
      LeaderboardPreferenceController,
      LeaderboardPreferenceState
    >(LeaderboardPreferenceController.new);

class LeaderboardPreferenceController
    extends Notifier<LeaderboardPreferenceState> {
  Future<void>? _loadFuture;

  int _requestGeneration = 0;

  LeaderboardPreferenceRepository get _repository {
    return ref.read(leaderboardPreferenceRepositoryProvider);
  }

  @override
  LeaderboardPreferenceState build() {
    ref.onDispose(() {
      _requestGeneration++;

      _loadFuture = null;
    });

    return const LeaderboardPreferenceState();
  }

  Future<void> loadPreference({bool forceRefresh = false}) {
    if (!forceRefresh && state.status == LeaderboardPreferenceStatus.success) {
      return Future<void>.value();
    }

    final activeRequest = _loadFuture;

    if (!forceRefresh && activeRequest != null) {
      return activeRequest;
    }

    late final Future<void> trackedRequest;

    trackedRequest = _performLoad().whenComplete(() {
      if (identical(_loadFuture, trackedRequest)) {
        _loadFuture = null;
      }
    });

    _loadFuture = trackedRequest;

    return trackedRequest;
  }

  Future<void> _performLoad() async {
    final requestGeneration = ++_requestGeneration;

    state = state.copyWith(
      status: LeaderboardPreferenceStatus.loading,
      isUpdating: false,
      clearErrorMessage: true,
    );

    late final LeaderboardPreferenceState resultState;

    try {
      final preference = await _repository.fetchPreference();

      resultState = LeaderboardPreferenceState(
        status: LeaderboardPreferenceStatus.success,
        preference: preference,
      );
    } on LeaderboardPreferenceFailure catch (error) {
      resultState = LeaderboardPreferenceState(
        status: LeaderboardPreferenceStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = const LeaderboardPreferenceState(
        status: LeaderboardPreferenceStatus.failure,
        errorMessage:
            'Tetapan leaderboard tidak '
            'dapat dimuatkan. Sila cuba '
            'semula.',
      );
    }

    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }
  }

  /// Mengubah penyertaan leaderboard.
  ///
  /// Null bermaksud berjaya.
  /// String bermaksud mesej error.
  Future<String?> updateParticipation(bool optIn) async {
    if (state.isUpdating) {
      return 'Tetapan leaderboard sedang '
          'dikemas kini.';
    }

    if (state.status != LeaderboardPreferenceStatus.success ||
        state.preference == null) {
      await loadPreference(forceRefresh: true);
    }

    final currentPreference = state.preference;

    if (state.status != LeaderboardPreferenceStatus.success ||
        currentPreference == null) {
      return state.errorMessage ??
          'Tetapan leaderboard tidak '
              'tersedia.';
    }

    /*
     * Tiada request diperlukan apabila
     * status sudah sama dan consent masih sah.
     */
    if (currentPreference.isOptedIn == optIn &&
        (!optIn || currentPreference.hasCurrentConsent)) {
      return null;
    }

    final requiredConsentVersion =
        currentPreference.requiredConsentVersion.trim().isEmpty
        ? LeaderboardPreference.fallbackConsentVersion
        : currentPreference.requiredConsentVersion.trim();

    final previousState = state;

    final requestGeneration = ++_requestGeneration;

    state = state.copyWith(isUpdating: true, clearErrorMessage: true);

    try {
      final updatedPreference = await _repository.updateParticipation(
        optIn: optIn,
        consentVersion: requiredConsentVersion,
      );

      if (requestGeneration == _requestGeneration) {
        state = LeaderboardPreferenceState(
          status: LeaderboardPreferenceStatus.success,
          preference: updatedPreference,
        );
      }

      return null;
    } on LeaderboardPreferenceFailure catch (error) {
      if (requestGeneration == _requestGeneration) {
        state = previousState.copyWith(
          isUpdating: false,
          errorMessage: error.message,
        );
      }

      return error.message;
    } catch (_) {
      const errorMessage =
          'Tetapan leaderboard tidak dapat '
          'dikemas kini. Sila cuba semula.';

      if (requestGeneration == _requestGeneration) {
        state = previousState.copyWith(
          isUpdating: false,
          errorMessage: errorMessage,
        );
      }

      return errorMessage;
    }
  }

  Future<void> refreshPreference() {
    return loadPreference(forceRefresh: true);
  }

  void reset() {
    _requestGeneration++;

    _loadFuture = null;

    state = const LeaderboardPreferenceState();
  }
}
