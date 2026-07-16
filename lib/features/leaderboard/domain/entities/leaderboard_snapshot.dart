import 'leaderboard_entry.dart';
import 'leaderboard_period.dart';

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.period,
    required this.generatedAt,
    required this.participantCount,
    required this.entries,
  }) : assert(participantCount >= 0);

  final LeaderboardPeriod period;
  final DateTime generatedAt;
  final int participantCount;
  final List<LeaderboardEntry> entries;
}
