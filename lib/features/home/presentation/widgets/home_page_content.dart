import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/home_summary.dart';
import 'home_header.dart';
import 'home_stat_card.dart';
import 'quick_action_card.dart';
import 'semester_overview_card.dart';

class HomePageContent extends StatelessWidget {
  const HomePageContent({
    required this.summary,
    required this.onRefresh,
    required this.onOpenTopics,
    required this.onStartQuiz,
    required this.onOpenLeaderboard,
    required this.onOpenMistakeBook,
    super.key,
  });

  final HomeSummary summary;

  final Future<void> Function() onRefresh;

  final VoidCallback onOpenTopics;

  final VoidCallback onStartQuiz;

  final VoidCallback onOpenLeaderboard;

  final VoidCallback onOpenMistakeBook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('home-page-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          HomeHeader(
            displayName: summary.displayName,
            semesterLabel: summary.semesterLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          SemesterOverviewCard(
            key: const Key('home-semester-overview'),
            semesterLabel: summary.semesterLabel,
            currentTopic: summary.currentTopic,
            progress: summary.currentTopicProgress,
            completedTopics: summary.completedTopics,
            totalTopics: summary.totalTopics,
            onTap: onOpenTopics,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ringkasan Prestasi', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _PerformanceSummaryGrid(
            summary: summary,
            onOpenLeaderboard: onOpenLeaderboard,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Akses Pantas', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _QuickActionsGrid(
            onOpenTopics: onOpenTopics,
            onStartQuiz: onStartQuiz,
            onOpenLeaderboard: onOpenLeaderboard,
            onOpenMistakeBook: onOpenMistakeBook,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PerformanceSummaryGrid extends StatelessWidget {
  const _PerformanceSummaryGrid({
    required this.summary,
    required this.onOpenLeaderboard,
  });

  final HomeSummary summary;

  final VoidCallback onOpenLeaderboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final columnCount = constraints.maxWidth < 360 ? 1 : 2;

        final cardWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        final weeklyRank = summary.weeklyRank;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                key: const Key('home-completed-quizzes-card'),
                icon: Icons.quiz_outlined,
                label: 'Kuiz Disiapkan',
                value: '${summary.completedQuizzes}',
                iconColor: AppColors.actionBlue,
                iconBackgroundColor: AppColors.softBlue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                key: const Key('home-average-score-card'),
                icon: Icons.track_changes_rounded,
                label: 'Purata Markah',
                value: '${summary.averageScore.round()}%',
                iconColor: AppColors.success,
                iconBackgroundColor: AppColors.successBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                key: const Key('home-total-xp-card'),
                icon: Icons.star_outline_rounded,
                label: 'Jumlah XP',
                value: '${summary.totalXp}',
                iconColor: AppColors.accentGold,
                iconBackgroundColor: AppColors.warningBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                key: const Key('home-weekly-ranking-card'),
                icon: Icons.emoji_events_outlined,
                label: 'Ranking Mingguan',
                value: weeklyRank == null ? 'Sertai' : '#$weeklyRank',
                iconColor: AppColors.bronze,
                iconBackgroundColor: AppColors.warningBackground,
                semanticLabel: weeklyRank == null
                    ? 'Sertai leaderboard '
                          'untuk mendapatkan '
                          'ranking mingguan'
                    : 'Buka leaderboard. '
                          'Ranking mingguan '
                          'anda ialah nombor '
                          '$weeklyRank',
                onTap: onOpenLeaderboard,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onOpenTopics,
    required this.onStartQuiz,
    required this.onOpenLeaderboard,
    required this.onOpenMistakeBook,
  });

  final VoidCallback onOpenTopics;

  final VoidCallback onStartQuiz;

  final VoidCallback onOpenLeaderboard;

  final VoidCallback onOpenMistakeBook;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final columnCount = constraints.maxWidth < 360 ? 1 : 2;

        final cardWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                key: const Key('home-quick-topics'),
                icon: Icons.menu_book_rounded,
                title: 'Topik',
                description: 'Pilih topik pembelajaran',
                onTap: onOpenTopics,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                key: const Key('home-quick-quiz'),
                icon: Icons.quiz_rounded,
                title: 'Mula Kuiz',
                description: 'Uji penguasaan anda',
                onTap: onStartQuiz,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                key: const Key('home-quick-leaderboard'),
                icon: Icons.emoji_events_rounded,
                title: 'Ranking',
                description: 'Lihat kedudukan mingguan',
                onTap: onOpenLeaderboard,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                key: const Key('home-quick-mistake-book'),
                icon: Icons.fact_check_rounded,
                title: 'Buku Kesilapan',
                description:
                    'Semak soalan yang '
                    'perlu diulang kaji',
                onTap: onOpenMistakeBook,
              ),
            ),
          ],
        );
      },
    );
  }
}
