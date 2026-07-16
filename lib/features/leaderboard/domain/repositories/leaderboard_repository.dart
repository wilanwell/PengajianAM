import '../entities/leaderboard_period.dart';
import '../entities/leaderboard_snapshot.dart';

abstract interface class LeaderboardRepository {
  Future<LeaderboardSnapshot> fetchLeaderboard({
    required LeaderboardPeriod period,
    int limit = 100,
  });
}
