import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/mistake_book_topic_detail.dart';
import '../../domain/services/mistake_book_review_policy.dart';

class MistakeBookTopicOverviewCard extends StatelessWidget {
  const MistakeBookTopicOverviewCard({required this.detail, super.key});

  final MistakeBookTopicDetail detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('mistake-book-topic-overview'),
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _HeaderLabel(text: detail.topicCode),
              _HeaderLabel(text: 'Semester ${detail.semester}'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            detail.topicTitle,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${detail.totalTrackedCount} soalan direkodkan '
            'dalam Buku Kesilapan.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;

              final cardWidth = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _TopicMetric(
                      key: const Key('mistake-book-topic-reviewable'),
                      icon: Icons.replay_rounded,
                      label: 'Boleh Dilatih',
                      value: detail.reviewableCount,
                      color: AppColors.warning,
                      backgroundColor: AppColors.warningBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _TopicMetric(
                      key: const Key('mistake-book-topic-mastered'),
                      icon: Icons.verified_rounded,
                      label: 'Dikuasai',
                      value: detail.masteredCount,
                      color: AppColors.success,
                      backgroundColor: AppColors.successBackground,
                    ),
                  ),
                  if (detail.archivedNeedsReviewCount > 0)
                    SizedBox(
                      width: cardWidth,
                      child: _TopicMetric(
                        key: const Key('mistake-book-topic-archived'),
                        icon: Icons.inventory_2_outlined,
                        label: 'Diarkibkan',
                        value: detail.archivedNeedsReviewCount,
                        color: AppColors.secondaryText,
                        backgroundColor: AppColors.surfaceMuted,
                      ),
                    ),
                  SizedBox(
                    width: cardWidth,
                    child: _TopicMetric(
                      key: const Key('mistake-book-topic-needs-review'),
                      icon: Icons.pending_actions_rounded,
                      label: 'Perlu Dijawab Semula',
                      value: detail.needsReviewCount,
                      color: AppColors.info,
                      backgroundColor: AppColors.infoBackground,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Penguasaan',
                style: textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '${(detail.masteryProgress * 100).round()}%',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                'Penguasaan ${detail.topicTitle} '
                '${(detail.masteryProgress * 100).round()} peratus',
            child: ClipRRect(
              borderRadius: AppRadius.fullyRounded,
              child: LinearProgressIndicator(
                value: detail.masteryProgress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: AppColors.successBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MistakeBookTopicReviewAction extends StatelessWidget {
  const MistakeBookTopicReviewAction({
    required this.detail,
    required this.onStartReview,
    super.key,
  });

  final MistakeBookTopicDetail detail;

  /// Menerima jumlah soalan sebenar yang perlu dimasukkan
  /// ke dalam sesi latihan semula.
  final ValueChanged<int> onStartReview;

  @override
  Widget build(BuildContext context) {
    final reviewableCount = detail.reviewableCount;

    if (reviewableCount < 1) {
      if (detail.needsReviewCount < 1) {
        return const _AllMistakesMasteredNotice();
      }

      return _NoReviewableQuestionsNotice(
        archivedCount: detail.archivedNeedsReviewCount,
      );
    }

    final sessionQuestionCount = MistakeBookReviewPolicy.resolveQuestionCount(
      reviewableCount,
    );

    final usesBatch = reviewableCount > sessionQuestionCount;

    final buttonLabel = usesBatch
        ? 'Latih Semula $sessionQuestionCount '
              'daripada $reviewableCount'
        : 'Latih Semula Semua '
              '($sessionQuestionCount)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('mistake-book-start-review'),
          onPressed: () {
            onStartReview(sessionQuestionCount);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(buttonLabel),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        if (usesBatch) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Satu sesi dihadkan kepada '
            '${MistakeBookReviewPolicy.maxQuestionsPerSession} '
            'soalan supaya latihan lebih fokus. '
            'Baki soalan boleh dilatih dalam sesi seterusnya.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
          ),
        ],
        if (detail.archivedNeedsReviewCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _ArchivedCountNotice(archivedCount: detail.archivedNeedsReviewCount),
        ],
      ],
    );
  }
}

class MistakeBookTopicExplanationCard extends StatelessWidget {
  const MistakeBookTopicExplanationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mistake-book-topic-explanation'),
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '“Jawapan Anda” ialah jawapan daripada '
              'percubaan salah yang paling terkini. '
              'Gunakan jawapan betul dan penerangan '
              'untuk memahami kesilapan tersebut.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class MistakeBookStaleDataWarning extends StatelessWidget {
  const MistakeBookStaleDataWarning({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mistake-book-stale-data-warning'),
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

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.fullyRounded,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _TopicMetric extends StatelessWidget {
  const _TopicMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
    super.key,
  });

  final IconData icon;

  final String label;

  final int value;

  final Color color;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: textTheme.titleLarge),
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

class _AllMistakesMasteredNotice extends StatelessWidget {
  const _AllMistakesMasteredNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mistake-book-all-mastered'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Semua kesilapan telah dikuasai.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoReviewableQuestionsNotice extends StatelessWidget {
  const _NoReviewableQuestionsNotice({required this.archivedCount});

  final int archivedCount;

  @override
  Widget build(BuildContext context) {
    final countText = archivedCount == 1
        ? '1 soalan telah diarkibkan'
        : '$archivedCount soalan telah diarkibkan';

    return Container(
      key: const Key('mistake-book-no-reviewable-questions'),
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$countText dan tidak lagi tersedia '
              'untuk latihan semula. Rekod tersebut '
              'masih boleh dilihat di bawah.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedCountNotice extends StatelessWidget {
  const _ArchivedCountNotice({required this.archivedCount});

  final int archivedCount;

  @override
  Widget build(BuildContext context) {
    final countText = archivedCount == 1
        ? '1 rekod diarkibkan'
        : '$archivedCount rekod diarkibkan';

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$countText masih dipaparkan sebagai '
              'sejarah pembelajaran tetapi tidak '
              'dimasukkan ke dalam latihan.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
