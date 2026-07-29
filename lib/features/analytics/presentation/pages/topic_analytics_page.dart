import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/topic_performance.dart';
import '../controllers/topic_analytics_controller.dart';
import '../controllers/topic_analytics_state.dart';
import '../widgets/topic_performance_card.dart';

class TopicAnalyticsPage extends ConsumerStatefulWidget {
  const TopicAnalyticsPage({super.key});

  @override
  ConsumerState<TopicAnalyticsPage> createState() {
    return _TopicAnalyticsPageState();
  }
}

class _TopicAnalyticsPageState extends ConsumerState<TopicAnalyticsPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref
          .read(topicAnalyticsControllerProvider.notifier)
          .loadAnalytics(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topicAnalyticsControllerProvider);

    final controller = ref.read(topicAnalyticsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Analitik Prestasi')),
      body: SafeArea(
        child: _buildStateContent(
          state: state,
          onRefresh: controller.refreshAnalytics,
          onRetry: () {
            controller.loadAnalytics(forceRefresh: true);
          },
        ),
      ),
    );
  }

  Widget _buildStateContent({
    required TopicAnalyticsState state,
    required Future<void> Function() onRefresh,
    required VoidCallback onRetry,
  }) {
    switch (state.status) {
      case TopicAnalyticsStatus.initial:
        return const _AnalyticsLoadingView();

      case TopicAnalyticsStatus.loading:
        if (state.performances.isEmpty) {
          return const _AnalyticsLoadingView();
        }

        return _AnalyticsContent(
          state: state,
          onRefresh: onRefresh,
          isRefreshing: true,
        );

      case TopicAnalyticsStatus.failure:
        if (state.performances.isEmpty) {
          return _AnalyticsErrorView(
            message: state.errorMessage ?? 'Analitik tidak dapat dimuatkan.',
            onRetry: onRetry,
          );
        }

        return _AnalyticsContent(
          state: state,
          onRefresh: onRefresh,
          staleErrorMessage:
              state.errorMessage ??
              'Data baharu tidak dapat dimuatkan. '
                  'Data terakhir masih dipaparkan.',
        );

      case TopicAnalyticsStatus.success:
        return _AnalyticsContent(state: state, onRefresh: onRefresh);
    }
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.state,
    required this.onRefresh,
    this.isRefreshing = false,
    this.staleErrorMessage,
  });

  final TopicAnalyticsState state;

  final Future<void> Function() onRefresh;

  final bool isRefreshing;

  final String? staleErrorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('topic-analytics-main-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          if (isRefreshing) ...[
            const LinearProgressIndicator(
              key: Key('topic-analytics-refresh-progress'),
              minHeight: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (staleErrorMessage != null) ...[
            _AnalyticsStaleDataWarning(message: staleErrorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          _AnalyticsSummaryCard(state: state),
          const SizedBox(height: AppSpacing.lg),
          if (state.performances.isEmpty)
            const _AnalyticsEmptyView()
          else ...[
            Text('Sorotan Prestasi', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _AnalyticsHighlights(
              strongestTopic: state.strongestTopic!,
              weakestTopic: state.weakestTopic!,
              showWeakest: state.performances.length > 1,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Prestasi Mengikut Topik',
                    style: textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${state.totalTopics} topik',
                  key: const Key('topic-analytics-topic-count'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final performance in state.performances) ...[
              TopicPerformanceCard(
                key: Key(
                  'topic-analytics-performance-'
                  '${performance.topicId}',
                ),
                performance: performance,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (state.lastUpdated != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dikemas kini '
              '${_formatDateTime(state.lastUpdated!)}',
              key: const Key('topic-analytics-last-updated'),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AnalyticsSummaryCard extends StatelessWidget {
  const _AnalyticsSummaryCard({required this.state});

  final TopicAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('topic-analytics-summary'),
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        children: [
          Text(
            'Ringkasan Prestasi',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Berdasarkan rekod kuiz dalam '
            'akaun Supabase anda.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  key: const Key('topic-analytics-summary-topics'),
                  value: '${state.totalTopics}',
                  label: 'Topik',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  key: const Key('topic-analytics-summary-attempts'),
                  value: '${state.totalAttempts}',
                  label: 'Percubaan',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  key: const Key('topic-analytics-summary-average'),
                  value: '${state.overallAverageScore.round()}%',
                  label: 'Purata',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label, super.key});

  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(color: AppColors.accentGold),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _AnalyticsHighlights extends StatelessWidget {
  const _AnalyticsHighlights({
    required this.strongestTopic,
    required this.weakestTopic,
    required this.showWeakest,
  });

  final TopicPerformance strongestTopic;

  final TopicPerformance weakestTopic;

  final bool showWeakest;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final cardWidth = constraints.maxWidth < 520 || !showWeakest
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _HighlightCard(
                key: const Key('topic-analytics-strongest'),
                title: 'Topik Terkuat',
                performance: strongestTopic,
                icon: Icons.workspace_premium_rounded,
                foregroundColor: AppColors.success,
                backgroundColor: AppColors.successBackground,
              ),
            ),
            if (showWeakest)
              SizedBox(
                width: cardWidth,
                child: _HighlightCard(
                  key: const Key('topic-analytics-weakest'),
                  title: 'Perlu Diberi Perhatian',
                  performance: weakestTopic,
                  icon: Icons.priority_high_rounded,
                  foregroundColor: AppColors.warning,
                  backgroundColor: AppColors.warningBackground,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.performance,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    super.key,
  });

  final String title;

  final TopicPerformance performance;

  final IconData icon;

  final Color foregroundColor;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  performance.topicTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${performance.averageScorePercentage}%',
            style: textTheme.titleLarge?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStaleDataWarning extends StatelessWidget {
  const _AnalyticsStaleDataWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('topic-analytics-stale-warning'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Terakhir Dipaparkan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsEmptyView extends StatelessWidget {
  const _AnalyticsEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('topic-analytics-empty'),
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 56,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Belum Ada Data Analitik', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jawab dan hantar sekurang-kurangnya '
            'satu kuiz untuk melihat prestasi '
            'mengikut topik.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLoadingView extends StatelessWidget {
  const _AnalyticsLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _AnalyticsErrorView extends StatelessWidget {
  const _AnalyticsErrorView({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Semula'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final localValue = value.toLocal();

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  final hour = localValue.hour.toString().padLeft(2, '0');

  final minute = localValue.minute.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year} '
      'pada $hour:$minute';
}
