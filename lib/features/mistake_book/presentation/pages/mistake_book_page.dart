import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/mistake_book_snapshot.dart';
import '../../domain/entities/mistake_book_topic_summary.dart';
import '../controllers/mistake_book_controller.dart';
import '../controllers/mistake_book_state.dart';

class MistakeBookPage extends ConsumerStatefulWidget {
  const MistakeBookPage({super.key});

  @override
  ConsumerState<MistakeBookPage> createState() {
    return _MistakeBookPageState();
  }
}

class _MistakeBookPageState extends ConsumerState<MistakeBookPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref
          .read(mistakeBookControllerProvider.notifier)
          .refreshMistakeBook();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mistakeBookControllerProvider);

    final controller = ref.read(mistakeBookControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }

            context.goNamed(RouteNames.home);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Buku Kesilapan'),
      ),
      body: SafeArea(
        child: _buildContent(
          state: state,
          onRefresh: controller.refreshMistakeBook,
        ),
      ),
    );
  }

  Widget _buildContent({
    required MistakeBookState state,
    required Future<void> Function() onRefresh,
  }) {
    switch (state.status) {
      case MistakeBookStatus.initial:
        return const _MistakeBookLoadingView();

      case MistakeBookStatus.loading:
        final snapshot = state.snapshot;

        if (snapshot == null) {
          return const _MistakeBookLoadingView();
        }

        return _MistakeBookContent(
          snapshot: snapshot,
          onRefresh: onRefresh,
          isRefreshing: true,
        );

      case MistakeBookStatus.failure:
        final snapshot = state.snapshot;

        if (snapshot == null) {
          return _MistakeBookErrorView(
            message:
                state.errorMessage ?? 'Buku Kesilapan tidak dapat dimuatkan.',
            onRetry: onRefresh,
          );
        }

        return _MistakeBookContent(
          snapshot: snapshot,
          onRefresh: onRefresh,
          staleErrorMessage:
              state.errorMessage ??
              'Data baharu tidak dapat dimuatkan. '
                  'Data terakhir masih dipaparkan.',
        );

      case MistakeBookStatus.success:
        final snapshot = state.snapshot;

        if (snapshot == null) {
          return _MistakeBookErrorView(
            message: 'Data Buku Kesilapan tidak tersedia.',
            onRetry: onRefresh,
          );
        }

        return _MistakeBookContent(snapshot: snapshot, onRefresh: onRefresh);
    }
  }
}

class _MistakeBookContent extends StatelessWidget {
  const _MistakeBookContent({
    required this.snapshot,
    required this.onRefresh,
    this.isRefreshing = false,
    this.staleErrorMessage,
  });

  final MistakeBookSnapshot snapshot;

  final Future<void> Function() onRefresh;

  final bool isRefreshing;

  final String? staleErrorMessage;

  @override
  Widget build(BuildContext context) {
    final topicsBySemester = <int, List<MistakeBookTopicSummary>>{};

    for (final topic in snapshot.topics) {
      topicsBySemester.putIfAbsent(topic.semester, () => []).add(topic);
    }

    final semesters = topicsBySemester.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('mistake-book-main-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          if (isRefreshing) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (staleErrorMessage != null) ...[
            _MistakeBookStaleDataWarning(message: staleErrorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          _MistakeBookOverview(snapshot: snapshot),
          const SizedBox(height: AppSpacing.lg),
          const _MistakeBookExplanation(),
          const SizedBox(height: AppSpacing.lg),
          if (snapshot.isEmpty)
            const _MistakeBookEmptyView()
          else ...[
            Text(
              'Ringkasan Mengikut Topik',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final semester in semesters) ...[
              _SemesterHeader(semester: semester),
              const SizedBox(height: AppSpacing.sm),
              for (final topic in topicsBySemester[semester]!) ...[
                _MistakeBookTopicCard(topic: topic),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          Text(
            'Dikemas kini '
            '${_formatDateTime(snapshot.generatedAt)}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MistakeBookOverview extends StatelessWidget {
  const _MistakeBookOverview({required this.snapshot});

  final MistakeBookSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('mistake-book-overview'),
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.textOnPrimary,
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belajar daripada kesilapan',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${snapshot.totalTrackedCount} '
                      'soalan sedang dijejaki.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    child: _SummaryMetric(
                      key: const Key('mistake-book-reviewable'),
                      icon: Icons.replay_rounded,
                      label: 'Boleh Dilatih',
                      value: snapshot.reviewableCount,
                      foregroundColor: AppColors.warning,
                      backgroundColor: AppColors.warningBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetric(
                      key: const Key('mistake-book-mastered'),
                      icon: Icons.verified_rounded,
                      label: 'Dikuasai',
                      value: snapshot.masteredCount,
                      foregroundColor: AppColors.success,
                      backgroundColor: AppColors.successBackground,
                    ),
                  ),
                  if (snapshot.archivedNeedsReviewCount > 0)
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryMetric(
                        key: const Key('mistake-book-archived'),
                        icon: Icons.inventory_2_outlined,
                        label: 'Diarkibkan',
                        value: snapshot.archivedNeedsReviewCount,
                        foregroundColor: AppColors.secondaryText,
                        backgroundColor: AppColors.surfaceMuted,
                      ),
                    ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetric(
                      key: const Key('mistake-book-needs-review'),
                      icon: Icons.pending_actions_rounded,
                      label: 'Belum Dikuasai',
                      value: snapshot.needsReviewCount,
                      foregroundColor: AppColors.info,
                      backgroundColor: AppColors.infoBackground,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
            child: Icon(icon, color: foregroundColor),
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

class _MistakeBookExplanation extends StatelessWidget {
  const _MistakeBookExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Soalan yang dijawab salah ditambah '
              'secara automatik. Soalan aktif boleh '
              'dilatih semula sehingga dikuasai. '
              'Soalan yang tidak lagi aktif disimpan '
              'sebagai rekod diarkibkan.',
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

class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({required this.semester});

  final int semester;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Semester $semester',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
    );
  }
}

class _MistakeBookTopicCard extends StatelessWidget {
  const _MistakeBookTopicCard({required this.topic});

  final MistakeBookTopicSummary topic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label:
          'Buka soalan kesilapan bagi '
          '${topic.topicTitle}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: Key('mistake-book-topic-${topic.topicId}'),
          borderRadius: AppRadius.large,
          onTap: () {
            context.pushNamed(
              RouteNames.mistakeBookTopic,
              pathParameters: {'topicId': topic.topicId},
            );
          },
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Text(
                        topic.topicCode,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        topic.topicTitle,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _TopicCount(
                        icon: Icons.replay_rounded,
                        label: 'Boleh Dilatih',
                        value: topic.reviewableCount,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TopicCount(
                        icon: Icons.verified_rounded,
                        label: 'Dikuasai',
                        value: topic.masteredCount,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (topic.archivedNeedsReviewCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ArchivedTopicNotice(
                    archivedCount: topic.archivedNeedsReviewCount,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      'Penguasaan',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(topic.masteryProgress * 100).round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  label:
                      'Penguasaan '
                      '${topic.topicTitle} '
                      '${(topic.masteryProgress * 100).round()} '
                      'peratus',
                  child: ClipRRect(
                    borderRadius: AppRadius.fullyRounded,
                    child: LinearProgressIndicator(
                      value: topic.masteryProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceMuted,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kesilapan terakhir: '
                  '${_formatDate(topic.lastMistakeAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCount extends StatelessWidget {
  const _TopicCount({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;

  final String label;

  final int value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: textTheme.titleSmall),
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
    );
  }
}

class _ArchivedTopicNotice extends StatelessWidget {
  const _ArchivedTopicNotice({required this.archivedCount});

  final int archivedCount;

  @override
  Widget build(BuildContext context) {
    final text = archivedCount == 1
        ? '1 soalan diarkibkan'
        : '$archivedCount soalan diarkibkan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$text dan tidak dimasukkan '
              'ke dalam latihan.',
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

class _MistakeBookStaleDataWarning extends StatelessWidget {
  const _MistakeBookStaleDataWarning({required this.message});

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

class _MistakeBookEmptyView extends StatelessWidget {
  const _MistakeBookEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            size: 56,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum Ada Kesilapan Direkodkan',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Soalan yang dijawab salah selepas '
            'anda menghantar kuiz akan muncul '
            'di sini.',
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

class _MistakeBookLoadingView extends StatelessWidget {
  const _MistakeBookLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MistakeBookErrorView extends StatelessWidget {
  const _MistakeBookErrorView({required this.message, required this.onRetry});

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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

String _formatDate(DateTime value) {
  final localValue = value.toLocal();

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year}';
}

String _formatDateTime(DateTime value) {
  final localValue = value.toLocal();

  final hour = localValue.hour.toString().padLeft(2, '0');

  final minute = localValue.minute.toString().padLeft(2, '0');

  return '${_formatDate(localValue)} '
      'pada $hour:$minute';
}
