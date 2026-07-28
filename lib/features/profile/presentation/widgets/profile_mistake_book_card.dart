import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mistake_book/domain/entities/mistake_book_snapshot.dart';

class ProfileMistakeBookCard extends StatelessWidget {
  const ProfileMistakeBookCard({
    required this.onOpen,
    required this.onRetry,
    this.snapshot,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final MistakeBookSnapshot? snapshot;

  final bool isLoading;

  final String? errorMessage;

  final VoidCallback onOpen;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final currentSnapshot = snapshot;

    return Container(
      key: const Key('profile-mistake-book-card'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading && currentSnapshot != null)
            const LinearProgressIndicator(minHeight: 3),
          Padding(
            padding: AppSpacing.largeCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MistakeBookHeader(),
                const SizedBox(height: AppSpacing.md),
                if (currentSnapshot == null)
                  _buildUnavailableContent(context)
                else
                  _MistakeBookSummaryContent(
                    snapshot: currentSnapshot,
                    errorMessage: errorMessage,
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (errorMessage != null) ...[
                      TextButton.icon(
                        key: const Key('profile-mistake-book-retry'),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Cuba Semula'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('profile-mistake-book-open'),
                        onPressed: onOpen,
                        icon: const Icon(Icons.auto_stories_rounded),
                        label: const Text('Buka Buku Kesilapan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableContent(BuildContext context) {
    if (isLoading) {
      return const _MistakeBookLoadingContent();
    }

    final currentErrorMessage = errorMessage;

    if (currentErrorMessage != null) {
      return _MistakeBookErrorContent(message: currentErrorMessage);
    }

    return const _MistakeBookLoadingContent();
  }
}

class _MistakeBookHeader extends StatelessWidget {
  const _MistakeBookHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.warningBackground,
            borderRadius: AppRadius.large,
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buku Kesilapan', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Lihat kelemahan dan latih semula '
                'soalan yang pernah dijawab salah.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MistakeBookSummaryContent extends StatelessWidget {
  const _MistakeBookSummaryContent({
    required this.snapshot,
    required this.errorMessage,
  });

  final MistakeBookSnapshot snapshot;

  final String? errorMessage;

  double get _masteryProgress {
    if (snapshot.totalTrackedCount == 0) {
      return 0;
    }

    return snapshot.masteredCount / snapshot.totalTrackedCount;
  }

  int get _masteryPercentage {
    return (_masteryProgress * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          _MistakeBookStaleWarning(message: errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (snapshot.isEmpty)
          const _MistakeBookEmptySummary()
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.xs;

              final columnCount = constraints.maxWidth < 420 ? 1 : 3;

              final cardWidth = columnCount == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (gap * (columnCount - 1))) /
                        columnCount;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MistakeBookMetric(
                      key: const Key('profile-mistake-book-reviewable'),
                      icon: Icons.replay_rounded,
                      label: 'Boleh Dilatih',
                      value: snapshot.reviewableCount,
                      foregroundColor: AppColors.warning,
                      backgroundColor: AppColors.warningBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MistakeBookMetric(
                      key: const Key('profile-mistake-book-mastered'),
                      icon: Icons.verified_rounded,
                      label: 'Dikuasai',
                      value: snapshot.masteredCount,
                      foregroundColor: AppColors.success,
                      backgroundColor: AppColors.successBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MistakeBookMetric(
                      key: const Key('profile-mistake-book-archived'),
                      icon: Icons.inventory_2_outlined,
                      label: 'Diarkibkan',
                      value: snapshot.archivedNeedsReviewCount,
                      foregroundColor: AppColors.secondaryText,
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Penguasaan kesilapan',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Text(
                '$_masteryPercentage%',
                key: const Key('profile-mistake-book-mastery'),
                style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                'Penguasaan Buku Kesilapan '
                '$_masteryPercentage peratus',
            child: ClipRRect(
              borderRadius: AppRadius.fullyRounded,
              child: LinearProgressIndicator(
                value: _masteryProgress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${snapshot.masteredCount} daripada '
            '${snapshot.totalTrackedCount} soalan '
            'telah dikuasai.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}

class _MistakeBookMetric extends StatelessWidget {
  const _MistakeBookMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.foregroundColor,
    required this.backgroundColor,
    super.key,
  });

  final IconData icon;

  final String label;

  final int value;

  final Color foregroundColor;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, size: 21, color: foregroundColor),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: textTheme.titleMedium),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeBookLoadingContent extends StatelessWidget {
  const _MistakeBookLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Memuatkan ringkasan Buku Kesilapan...')),
        ],
      ),
    );
  }
}

class _MistakeBookErrorContent extends StatelessWidget {
  const _MistakeBookErrorContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-mistake-book-error'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeBookStaleWarning extends StatelessWidget {
  const _MistakeBookStaleWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-mistake-book-stale-warning'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$message Data terakhir masih dipaparkan.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeBookEmptySummary extends StatelessWidget {
  const _MistakeBookEmptySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-mistake-book-empty'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Belum ada kesilapan direkodkan. '
              'Teruskan menjawab kuiz.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
