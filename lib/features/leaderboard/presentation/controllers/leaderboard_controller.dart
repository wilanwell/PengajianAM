import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_leaderboard_repository.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../../domain/exceptions/leaderboard_failure.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_state.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return SupabaseLeaderboardRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final leaderboardControllerProvider =
    NotifierProvider<LeaderboardController, LeaderboardState>(
      LeaderboardController.new,
    );

class LeaderboardController extends Notifier<LeaderboardState> {
  LeaderboardRepository get _repository {
    return ref.read(leaderboardRepositoryProvider);
  }

  @override
  LeaderboardState build() {
    return const LeaderboardState();
  }

  Future<void> loadLeaderboard({
    LeaderboardPeriod? period,
    bool forceRefresh = false,
  }) async {
    final selectedPeriod = period ?? state.period;

    if (!forceRefresh &&
        state.status == LeaderboardStatus.success &&
        state.period == selectedPeriod) {
      return;
    }

    state = state.copyWith(
      status: LeaderboardStatus.loading,
      period: selectedPeriod,
      clearErrorMessage: true,
    );

    try {
      final snapshot = await _repository.fetchLeaderboard(
        period: selectedPeriod,
        limit: 100,
      );

      state = LeaderboardState(
        status: LeaderboardStatus.success,
        period: snapshot.period,
        entries: snapshot.entries,
        participantCount: snapshot.participantCount,
        lastUpdated: snapshot.generatedAt,
      );
    } on LeaderboardFailure catch (error) {
      state = LeaderboardState(
        status: LeaderboardStatus.failure,
        period: selectedPeriod,
        errorMessage: error.message,
      );
    } catch (_) {
      state = LeaderboardState(
        status: LeaderboardStatus.failure,
        period: selectedPeriod,
        errorMessage:
            'Leaderboard tidak dapat '
            'dimuatkan. Sila cuba semula.',
      );
    }
  }

  Future<void> changePeriod(LeaderboardPeriod period) {
    return loadLeaderboard(period: period, forceRefresh: true);
  }

  Future<void> refreshLeaderboard() {
    return loadLeaderboard(period: state.period, forceRefresh: true);
  }

  void reset() {
    state = const LeaderboardState();
  }
}
