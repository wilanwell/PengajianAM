class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.rank,
    required this.xp,
    this.previousRank,
    this.isCurrentUser = false,
  }) : assert(rank > 0),
       assert(xp >= 0),
       assert(previousRank == null || previousRank > 0);

  final String userId;
  final String nickname;
  final int rank;
  final int xp;
  final int? previousRank;
  final bool isCurrentUser;

  String get initials {
    final words = nickname
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'PA';
    }

    if (words.length == 1) {
      final word = words.first;

      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Nilai positif bermaksud pengguna naik kedudukan.
  int get movement {
    final oldRank = previousRank;

    if (oldRank == null) {
      return 0;
    }

    return oldRank - rank;
  }

  bool get isMovingUp => movement > 0;

  bool get isMovingDown => movement < 0;
}
