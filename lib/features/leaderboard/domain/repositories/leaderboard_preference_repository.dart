import '../entities/leaderboard_preference.dart';

abstract interface class LeaderboardPreferenceRepository {
  Future<LeaderboardPreference> fetchPreference();

  Future<LeaderboardPreference> updateParticipation({
    required bool optIn,
    required String consentVersion,
  });
}
