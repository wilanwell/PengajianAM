import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';

enum LeaderboardStatus { initial, loading, success, failure }

class LeaderboardState {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.period = LeaderboardPeriod.weekly,
    this.entries = const [],
    this.participantCount = 0,
    this.isParticipating = false,
    this.currentUserXp = 0,
    this.periodStartsAt,
    this.periodEndsAt,
    this.timezone = 'Asia/Kuala_Lumpur',
    this.lastUpdated,
    this.errorMessage,
  });

  final LeaderboardStatus status;

  final LeaderboardPeriod period;

  final List<LeaderboardEntry> entries;

  final int participantCount;

  /// True apabila pengguna telah memberikan
  /// consent untuk menyertai leaderboard.
  final bool isParticipating;

  /// XP pengguna semasa bagi tempoh yang
  /// sedang dipaparkan.
  final int currentUserXp;

  final DateTime? periodStartsAt;

  final DateTime? periodEndsAt;

  final String timezone;

  final DateTime? lastUpdated;

  final String? errorMessage;

  bool get isLoading {
    return status == LeaderboardStatus.loading;
  }

  LeaderboardEntry? get currentUserEntry {
    for (final entry in entries) {
      if (entry.isCurrentUser) {
        return entry;
      }
    }

    return null;
  }

  bool get hasCurrentUserRanking {
    return isParticipating && currentUserEntry != null;
  }

  List<LeaderboardEntry> get topThree {
    final sortedEntries = [...entries]
      ..sort((first, second) {
        return first.rank.compareTo(second.rank);
      });

    return List<LeaderboardEntry>.unmodifiable(sortedEntries.take(3));
  }

  List<LeaderboardEntry> get remainingEntries {
    final sortedEntries = [...entries]
      ..sort((first, second) {
        return first.rank.compareTo(second.rank);
      });

    return List<LeaderboardEntry>.unmodifiable(sortedEntries.skip(3));
  }

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardPeriod? period,
    List<LeaderboardEntry>? entries,
    int? participantCount,
    bool? isParticipating,
    int? currentUserXp,
    DateTime? periodStartsAt,
    DateTime? periodEndsAt,
    String? timezone,
    DateTime? lastUpdated,
    String? errorMessage,
    bool clearPeriodWindow = false,
    bool clearLastUpdated = false,
    bool clearErrorMessage = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      period: period ?? this.period,
      entries: entries ?? this.entries,
      participantCount: participantCount ?? this.participantCount,
      isParticipating: isParticipating ?? this.isParticipating,
      currentUserXp: currentUserXp ?? this.currentUserXp,
      periodStartsAt: clearPeriodWindow
          ? null
          : periodStartsAt ?? this.periodStartsAt,
      periodEndsAt: clearPeriodWindow
          ? null
          : periodEndsAt ?? this.periodEndsAt,
      timezone: timezone ?? this.timezone,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
