import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_view.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: const SafeArea(
        child: FeaturePlaceholderView(
          icon: Icons.emoji_events_rounded,
          title: 'Leaderboard Mingguan',
          description:
              'Kedudukan pelajar berdasarkan XP akan dipaparkan di sini.',
        ),
      ),
    );
  }
}
