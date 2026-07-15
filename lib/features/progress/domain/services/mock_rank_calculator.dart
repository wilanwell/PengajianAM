abstract final class MockRankCalculator {
  static const List<int> weeklyCompetitorXp = [
    2450,
    2260,
    2050,
    1900,
    1700,
    1600,
    1490,
    1370,
    1250,
  ];

  static const List<int> monthlyCompetitorXp = [
    8450,
    8120,
    7750,
    7380,
    6900,
    6280,
    5990,
    5500,
    5100,
  ];

  static int weeklyRank(int userXp) {
    return calculateRank(userXp: userXp, competitorXp: weeklyCompetitorXp);
  }

  static int monthlyRank(int userXp) {
    return calculateRank(userXp: userXp, competitorXp: monthlyCompetitorXp);
  }

  static int calculateRank({
    required int userXp,
    required List<int> competitorXp,
  }) {
    var higherScoreCount = 0;

    for (final xp in competitorXp) {
      if (xp > userXp) {
        higherScoreCount++;
      }
    }

    return higherScoreCount + 1;
  }

  const MockRankCalculator._();
}
