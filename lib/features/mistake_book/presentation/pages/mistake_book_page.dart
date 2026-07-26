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
      return ref.read(mistakeBookControllerProvider.notifier).loadMistakeBook();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mistakeBookControllerProvider);
    final controller = ref.read(mistakeBookControllerProvider.notifier);

    if (state.status == MistakeBookStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final latestState = ref.read(mistakeBookControllerProvider);

        if (latestState.status != MistakeBookStatus.initial) {
          return;
        }

        ref.read(mistakeBookControllerProvider.notifier).loadMistakeBook();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Buku Kesilapan'),
        actions: [
          IconButton(
            tooltip: 'Muat semula Buku Kesilapan',
            onPressed: state.isLoading ? null : controller.refreshMistakeBook,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          MistakeBookStatus.initial => const _MistakeBookLoadingView(),

          MistakeBookStatus.loading =>
            state.snapshot == null
                ? const _MistakeBookLoadingView()
                : _MistakeBookContent(
                    snapshot: state.snapshot!,
                    onRefresh: controller.refreshMistakeBook,
                  ),

          MistakeBookStatus.failure => _MistakeBookErrorView(
            message:
                state.errorMessage ?? 'Buku Kesilapan tidak dapat dimuatkan.',
            onRetry: controller.refreshMistakeBook,
          ),

          MistakeBookStatus.success =>
            state.snapshot == null
                ? _MistakeBookErrorView(
                    message: 'Data Buku Kesilapan tidak tersedia.',
                    onRetry: controller.refreshMistakeBook,
                  )
                : _MistakeBookContent(
                    snapshot: state.snapshot!,
                    onRefresh: controller.refreshMistakeBook,
                  ),
        },
      ),
    );
  }
}

class _MistakeBookContent extends StatelessWidget {
  const _MistakeBookContent({required this.snapshot, required this.onRefresh});

  final MistakeBookSnapshot snapshot;

  final Future<void> Function() onRefresh;

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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
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
            'Dikemas kini ${_formatDateTime(snapshot.generatedAt)}',
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
                      '${snapshot.totalTrackedCount} soalan sedang dijejaki.',
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
                      key: const Key('mistake-book-needs-review'),
                      icon: Icons.replay_rounded,
                      label: 'Perlu Disemak',
                      value: snapshot.needsReviewCount,
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
              'Soalan yang dijawab salah ditambah secara automatik. '
              'Jawapan betul dalam latihan semula akan menandakan '
              'soalan sebagai dikuasai.',
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

    return Container(
      key: Key('mistake-book-topic-${topic.topicId}'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
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
                child: Text(topic.topicTitle, style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TopicCount(
                  icon: Icons.replay_rounded,
                  label: 'Perlu disemak',
                  value: topic.needsReviewCount,
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
                style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                'Penguasaan ${topic.topicTitle} '
                '${(topic.masteryProgress * 100).round()} peratus',
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
            'Kesilapan terakhir: ${_formatDate(topic.lastMistakeAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
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
                maxLines: 1,
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
            'Soalan yang dijawab salah selepas anda menghantar '
            'kuiz akan muncul di sini.',
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

  return '${_formatDate(localValue)} pada $hour:$minute';
}
