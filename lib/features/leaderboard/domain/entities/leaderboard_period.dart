enum LeaderboardPeriod { weekly, monthly }

extension LeaderboardPeriodDetails on LeaderboardPeriod {
  String get label {
    return switch (this) {
      LeaderboardPeriod.weekly => 'Mingguan',
      LeaderboardPeriod.monthly => 'Bulanan',
    };
  }

  String get description {
    return switch (this) {
      LeaderboardPeriod.weekly =>
        'Kedudukan berdasarkan XP yang diperoleh minggu ini.',
      LeaderboardPeriod.monthly =>
        'Kedudukan berdasarkan XP yang diperoleh bulan ini.',
    };
  }
}
