import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/study_topic.dart';
import '../controllers/topics_controller.dart';
import '../controllers/topics_state.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_filter_bar.dart';

class TopicsPage extends ConsumerStatefulWidget {
  const TopicsPage({super.key});

  @override
  ConsumerState<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends ConsumerState<TopicsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(
      () => ref.read(topicsControllerProvider.notifier).loadTopics(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    ref.read(topicsControllerProvider.notifier).clearSearch();
  }

  void _openTopic(StudyTopic topic) {
    context.goNamed(RouteNames.quiz, queryParameters: {'topicId': topic.id});
  }

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsControllerProvider);
    final topicsController = ref.read(topicsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Topik Pembelajaran')),
      body: SafeArea(
        child: switch (topicsState.status) {
          TopicsStatus.initial ||
          TopicsStatus.loading => const _TopicsLoadingView(),

          TopicsStatus.failure => _TopicsErrorView(
            message:
                topicsState.errorMessage ??
                'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {
              topicsController.loadTopics(forceRefresh: true);
            },
          ),

          TopicsStatus.success => _TopicsContent(
            state: topicsState,
            searchController: _searchController,
            onSearchChanged: topicsController.searchChanged,
            onClearSearch: _clearSearch,
            onFilterSelected: topicsController.filterChanged,
            onRefresh: topicsController.refreshTopics,
            onTopicSelected: _openTopic,
          ),
        },
      ),
    );
  }
}

class _TopicsContent extends StatelessWidget {
  const _TopicsContent({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
    required this.onRefresh,
    required this.onTopicSelected,
  });

  final TopicsState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<TopicProgressFilter> onFilterSelected;
  final Future<void> Function() onRefresh;
  final ValueChanged<StudyTopic> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final visibleTopics = state.visibleTopics;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          _TopicSummaryCard(
            topicCount: state.topics.length,
            completedTopics: state.completedTopics,
            totalQuestions: state.totalQuestions,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Cari Topik', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau kod topik',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Kosongkan carian',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TopicFilterBar(
            selectedFilter: state.filter,
            onFilterSelected: onFilterSelected,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Senarai Topik', style: textTheme.titleLarge),
              ),
              Text(
                '${visibleTopics.length} topik',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visibleTopics.isEmpty)
            const _TopicsEmptyView()
          else
            for (final topic in visibleTopics) ...[
              TopicCard(
                topic: topic,
                onTap: () {
                  onTopicSelected(topic);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _TopicSummaryCard extends StatelessWidget {
  const _TopicSummaryCard({
    required this.topicCount,
    required this.completedTopics,
    required this.totalQuestions,
  });

  final int topicCount;
  final int completedTopics;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester 1',
            style: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih topik untuk memulakan latihan objektif.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.menu_book_rounded,
                  value: '$topicCount',
                  label: 'Topik',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.quiz_rounded,
                  value: '$totalQuestions',
                  label: 'Soalan',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.check_circle_rounded,
                  value: '$completedTopics',
                  label: 'Selesai',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _TopicsLoadingView extends StatelessWidget {
  const _TopicsLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TopicsErrorView extends StatelessWidget {
  const _TopicsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              style: textTheme.titleMedium,
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

class _TopicsEmptyView extends StatelessWidget {
  const _TopicsEmptyView();

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
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tiada topik ditemui', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cuba gunakan kata carian atau penapis yang lain.',
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
