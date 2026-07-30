import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/study_topic.dart';
import '../controllers/topics_state.dart';
import 'topic_card.dart';
import 'topic_filter_bar.dart';

class TopicsPageContent extends StatelessWidget {
  const TopicsPageContent({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
    required this.onRefresh,
    required this.onTopicSelected,
    super.key,
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
        key: const PageStorageKey<String>('topics-page-content'),
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
            key: const Key('topics-search-field'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau kod topik',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('topics-clear-search-button'),
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
                key: const Key('topics-visible-count'),
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
                key: Key('topics-topic-${topic.id}'),
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
      key: const Key('topics-summary-card'),
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
            'Pilih topik untuk memulakan '
            'latihan objektif.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  key: const Key('topics-summary-topic-count'),
                  icon: Icons.menu_book_rounded,
                  value: '$topicCount',
                  label: 'Topik',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  key: const Key('topics-summary-question-count'),
                  icon: Icons.quiz_rounded,
                  value: '$totalQuestions',
                  label: 'Soalan',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  key: const Key('topics-summary-completed-count'),
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
    super.key,
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

class _TopicsEmptyView extends StatelessWidget {
  const _TopicsEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('topics-empty-view'),
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
            'Cuba gunakan kata carian atau '
            'penapis yang lain.',
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
