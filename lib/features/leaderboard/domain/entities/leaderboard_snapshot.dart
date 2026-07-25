import 'leaderboard_entry.dart';
import 'leaderboard_period.dart';

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.period,
    required this.generatedAt,
    required this.participantCount,
    required this.entries,
    this.periodStartsAt,
    this.periodEndsAt,
    this.timezone = 'Asia/Kuala_Lumpur',
    this.isParticipating = true,
    this.currentUserXp = 0,
  }) : assert(participantCount >= 0),
       assert(currentUserXp >= 0);

  final LeaderboardPeriod period;

  final DateTime generatedAt;

  final DateTime? periodStartsAt;

  final DateTime? periodEndsAt;

  final String timezone;

  final bool isParticipating;

  /// XP sebenar pengguna semasa bagi
  /// tempoh weekly atau monthly yang dipilih.
  ///
  /// Nilai ini masih tersedia walaupun
  /// pengguna memilih opt-out.
  final int currentUserXp;

  final int participantCount;

  final List<LeaderboardEntry> entries;
}
