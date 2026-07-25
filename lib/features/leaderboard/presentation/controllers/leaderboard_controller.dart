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
  Future<LeaderboardState>? _inFlightRequest;

  LeaderboardPeriod? _inFlightPeriod;

  int _requestGeneration = 0;

  LeaderboardRepository get _repository {
    return ref.read(leaderboardRepositoryProvider);
  }

  @override
  LeaderboardState build() {
    ref.onDispose(() {
      /*
       * Halang request lama daripada menulis
       * state selepas provider telah dibuang,
       * contohnya ketika logout.
       */
      _requestGeneration++;
      _inFlightRequest = null;
      _inFlightPeriod = null;
    });

    return const LeaderboardState();
  }

  Future<void> loadLeaderboard({
    LeaderboardPeriod? period,
    bool forceRefresh = false,
  }) async {
    await loadLeaderboardState(period: period, forceRefresh: forceRefresh);
  }

  /// Memuatkan leaderboard dan mengembalikan
  /// keputusan request ini secara langsung.
  ///
  /// HomeController menggunakan method ini
  /// supaya tidak bergantung pada shared state
  /// yang mungkin berubah akibat request lain.
  Future<LeaderboardState> loadLeaderboardState({
    LeaderboardPeriod? period,
    bool forceRefresh = false,
  }) {
    final selectedPeriod = period ?? state.period;

    if (!forceRefresh &&
        state.status == LeaderboardStatus.success &&
        state.period == selectedPeriod) {
      return Future<LeaderboardState>.value(state);
    }

    /*
     * Dua pemanggil yang meminta tempoh sama
     * akan menunggu request yang sama.
     *
     * Ini mengelakkan Home dan halaman Ranking
     * memulakan dua request serentak.
     */
    final activeRequest = _inFlightRequest;

    if (!forceRefresh &&
        activeRequest != null &&
        _inFlightPeriod == selectedPeriod) {
      return activeRequest;
    }

    late final Future<LeaderboardState> trackedRequest;

    trackedRequest = _performLoad(selectedPeriod: selectedPeriod).whenComplete(
      () {
        if (identical(_inFlightRequest, trackedRequest)) {
          _inFlightRequest = null;
          _inFlightPeriod = null;
        }
      },
    );

    _inFlightRequest = trackedRequest;
    _inFlightPeriod = selectedPeriod;

    return trackedRequest;
  }

  Future<LeaderboardState> _performLoad({
    required LeaderboardPeriod selectedPeriod,
  }) async {
    final requestGeneration = ++_requestGeneration;

    state = state.copyWith(
      status: LeaderboardStatus.loading,
      period: selectedPeriod,
      clearErrorMessage: true,
    );

    late final LeaderboardState resultState;

    try {
      final snapshot = await _repository.fetchLeaderboard(
        period: selectedPeriod,
        limit: 100,
      );

      resultState = LeaderboardState(
        status: LeaderboardStatus.success,
        period: snapshot.period,
        entries: snapshot.entries,
        participantCount: snapshot.participantCount,
        isParticipating: snapshot.isParticipating,
        currentUserXp: snapshot.currentUserXp,
        periodStartsAt: snapshot.periodStartsAt,
        periodEndsAt: snapshot.periodEndsAt,
        timezone: snapshot.timezone,
        lastUpdated: snapshot.generatedAt,
      );
    } on LeaderboardFailure catch (error) {
      resultState = LeaderboardState(
        status: LeaderboardStatus.failure,
        period: selectedPeriod,
        errorMessage: error.message,
      );
    } catch (_) {
      resultState = LeaderboardState(
        status: LeaderboardStatus.failure,
        period: selectedPeriod,
        errorMessage:
            'Leaderboard tidak dapat '
            'dimuatkan. Sila cuba semula.',
      );
    }

    /*
     * Hanya request terbaru dibenarkan
     * mengubah shared provider state.
     *
     * Keputusan request lama masih
     * dikembalikan kepada pemanggilnya.
     */
    if (requestGeneration == _requestGeneration) {
      state = resultState;
    }

    return resultState;
  }

  Future<void> changePeriod(LeaderboardPeriod period) {
    return loadLeaderboard(period: period, forceRefresh: true);
  }

  Future<void> refreshLeaderboard() {
    return loadLeaderboard(period: state.period, forceRefresh: true);
  }

  void reset() {
    /*
     * Batalkan hak request lama untuk
     * mengubah state selepas reset.
     */
    _requestGeneration++;
    _inFlightRequest = null;
    _inFlightPeriod = null;

    state = const LeaderboardState();
  }
}
