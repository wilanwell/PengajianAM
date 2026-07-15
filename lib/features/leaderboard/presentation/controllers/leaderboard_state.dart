import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';

enum LeaderboardStatus { initial, loading, success, failure }

class LeaderboardState {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.period = LeaderboardPeriod.weekly,
    this.entries = const [],
    this.lastUpdated,
    this.errorMessage,
  });

  final LeaderboardStatus status;
  final LeaderboardPeriod period;
  final List<LeaderboardEntry> entries;
  final DateTime? lastUpdated;
  final String? errorMessage;

  bool get isLoading => status == LeaderboardStatus.loading;

  LeaderboardEntry? get currentUserEntry {
    for (final entry in entries) {
      if (entry.isCurrentUser) {
        return entry;
      }
    }

    return null;
  }

  List<LeaderboardEntry> get topThree {
    final sortedEntries = [...entries]
      ..sort((first, second) => first.rank.compareTo(second.rank));

    return List<LeaderboardEntry>.unmodifiable(sortedEntries.take(3));
  }

  List<LeaderboardEntry> get remainingEntries {
    final sortedEntries = [...entries]
      ..sort((first, second) => first.rank.compareTo(second.rank));

    return List<LeaderboardEntry>.unmodifiable(sortedEntries.skip(3));
  }

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardPeriod? period,
    List<LeaderboardEntry>? entries,
    DateTime? lastUpdated,
    String? errorMessage,
    bool clearLastUpdated = false,
    bool clearErrorMessage = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      period: period ?? this.period,
      entries: entries ?? this.entries,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
