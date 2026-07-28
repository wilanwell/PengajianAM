import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/mistake_book_topic_detail.dart';
import '../controllers/mistake_book_topic_controller.dart';
import '../controllers/mistake_book_topic_state.dart';
import '../widgets/mistake_book_question_card.dart';
import '../widgets/mistake_book_topic_sections.dart';

enum _MistakeBookTopicFilter { all, needsReview, archived, mastered }

class MistakeBookTopicPage extends ConsumerStatefulWidget {
  const MistakeBookTopicPage({required this.topicId, super.key});

  final String topicId;

  @override
  ConsumerState<MistakeBookTopicPage> createState() {
    return _MistakeBookTopicPageState();
  }
}

class _MistakeBookTopicPageState extends ConsumerState<MistakeBookTopicPage> {
  _MistakeBookTopicFilter _selectedFilter = _MistakeBookTopicFilter.all;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref
          .read(mistakeBookTopicControllerProvider.notifier)
          .refreshTopic(widget.topicId);
    });
  }

  @override
  void didUpdateWidget(covariant MistakeBookTopicPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.topicId == widget.topicId) {
      return;
    }

    _selectedFilter = _MistakeBookTopicFilter.all;

    Future<void>.microtask(() {
      return ref
          .read(mistakeBookTopicControllerProvider.notifier)
          .refreshTopic(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTopicId = widget.topicId.trim();

    final state = ref.watch(mistakeBookTopicControllerProvider);

    final controller = ref.read(mistakeBookTopicControllerProvider.notifier);

    final stateMatchesTopic = state.topicId == normalizedTopicId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _returnToMistakeBook,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Soalan Kesilapan'),
      ),
      body: SafeArea(
        child: !stateMatchesTopic
            ? const _TopicLoadingView()
            : _buildStateContent(
                state: state,
                normalizedTopicId: normalizedTopicId,
                onRefresh: () {
                  return controller.refreshTopic(normalizedTopicId);
                },
              ),
      ),
    );
  }

  Widget _buildStateContent({
    required MistakeBookTopicState state,
    required String normalizedTopicId,
    required Future<void> Function() onRefresh,
  }) {
    switch (state.status) {
      case MistakeBookTopicStatus.initial:
        return const _TopicLoadingView();

      case MistakeBookTopicStatus.loading:
        final detail = state.detail;

        if (detail == null) {
          return const _TopicLoadingView();
        }

        return _buildContent(
          detail: detail,
          onRefresh: onRefresh,
          isRefreshing: true,
        );

      case MistakeBookTopicStatus.failure:
        final detail = state.detail;

        if (detail == null) {
          return _TopicErrorView(
            message:
                state.errorMessage ?? 'Butiran topik tidak dapat dimuatkan.',
            onRetry: () {
              ref
                  .read(mistakeBookTopicControllerProvider.notifier)
                  .refreshTopic(normalizedTopicId);
            },
          );
        }

        return _buildContent(
          detail: detail,
          onRefresh: onRefresh,
          staleErrorMessage:
              state.errorMessage ??
              'Data baharu tidak dapat dimuatkan. '
                  'Data terakhir masih dipaparkan.',
        );

      case MistakeBookTopicStatus.success:
        final detail = state.detail;

        if (detail == null) {
          return _TopicErrorView(
            message:
                'Data soalan Buku Kesilapan '
                'tidak tersedia.',
            onRetry: () {
              ref
                  .read(mistakeBookTopicControllerProvider.notifier)
                  .refreshTopic(normalizedTopicId);
            },
          );
        }

        return _buildContent(detail: detail, onRefresh: onRefresh);
    }
  }

  Widget _buildContent({
    required MistakeBookTopicDetail detail,
    required Future<void> Function() onRefresh,
    bool isRefreshing = false,
    String? staleErrorMessage,
  }) {
    final visibleItems = detail.items
        .where((item) {
          return switch (_selectedFilter) {
            _MistakeBookTopicFilter.all => true,
            _MistakeBookTopicFilter.needsReview =>
              item.needsReview && item.isReviewable,
            _MistakeBookTopicFilter.archived => item.isArchived,
            _MistakeBookTopicFilter.mastered => item.isMastered,
          };
        })
        .toList(growable: false);

    final itemCount = visibleItems.length + 2;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        key: const PageStorageKey<String>('mistake-book-topic-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(
              detail: detail,
              visibleItemCount: visibleItems.length,
              isRefreshing: isRefreshing,
              staleErrorMessage: staleErrorMessage,
            );
          }

          if (index == itemCount - 1) {
            return _TopicFooter(generatedAt: detail.generatedAt);
          }

          final itemIndex = index - 1;
          final item = visibleItems[itemIndex];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MistakeBookQuestionCard(
              questionNumber: itemIndex + 1,
              item: item,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required MistakeBookTopicDetail detail,
    required int visibleItemCount,
    required bool isRefreshing,
    required String? staleErrorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRefreshing) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (staleErrorMessage != null) ...[
          MistakeBookStaleDataWarning(message: staleErrorMessage),
          const SizedBox(height: AppSpacing.md),
        ],
        MistakeBookTopicOverviewCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        MistakeBookTopicReviewAction(
          detail: detail,
          onStartReview: (questionCount) {
            context.pushNamed(
              RouteNames.mistakeReviewSession,
              pathParameters: {'topicId': detail.topicId},
              queryParameters: {'questionCount': questionCount.toString()},
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const MistakeBookTopicExplanationCard(),
        const SizedBox(height: AppSpacing.lg),
        Text('Tapis Soalan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _MistakeBookTopicFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    key: Key(
                      'mistake-book-topic-filter-'
                      '${filter.name}',
                    ),
                    avatar: Icon(_filterIcon(filter), size: 18),
                    label: Text(_filterLabel(filter, detail)),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Senarai Soalan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '$visibleItemCount soalan',
              key: const Key('mistake-book-visible-count'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visibleItemCount == 0) ...[
          const _TopicFilterEmptyView(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  String _filterLabel(
    _MistakeBookTopicFilter filter,
    MistakeBookTopicDetail detail,
  ) {
    return switch (filter) {
      _MistakeBookTopicFilter.all => 'Semua (${detail.totalTrackedCount})',
      _MistakeBookTopicFilter.needsReview =>
        'Perlu Dijawab Semula '
            '(${detail.reviewableCount})',
      _MistakeBookTopicFilter.archived =>
        'Diarkibkan '
            '(${detail.archivedNeedsReviewCount})',
      _MistakeBookTopicFilter.mastered => 'Dikuasai (${detail.masteredCount})',
    };
  }

  IconData _filterIcon(_MistakeBookTopicFilter filter) {
    return switch (filter) {
      _MistakeBookTopicFilter.all => Icons.list_alt_rounded,
      _MistakeBookTopicFilter.needsReview => Icons.replay_rounded,
      _MistakeBookTopicFilter.archived => Icons.inventory_2_outlined,
      _MistakeBookTopicFilter.mastered => Icons.verified_rounded,
    };
  }

  void _returnToMistakeBook() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed(RouteNames.mistakeBook);
  }
}

class _TopicFilterEmptyView extends StatelessWidget {
  const _TopicFilterEmptyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mistake-book-filter-empty'),
      width: double.infinity,
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 52,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tiada soalan dalam kategori ini',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih penapis lain untuk melihat soalan.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _TopicFooter extends StatelessWidget {
  const _TopicFooter({required this.generatedAt});

  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      child: Text(
        'Dikemas kini '
        '${_formatDateTime(generatedAt)}',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
      ),
    );
  }
}

class _TopicLoadingView extends StatelessWidget {
  const _TopicLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TopicErrorView extends StatelessWidget {
  const _TopicErrorView({required this.message, required this.onRetry});

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

String _formatDateTime(DateTime value) {
  final localValue = value.toLocal();

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  final hour = localValue.hour.toString().padLeft(2, '0');

  final minute = localValue.minute.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year} '
      'pada $hour:$minute';
}
