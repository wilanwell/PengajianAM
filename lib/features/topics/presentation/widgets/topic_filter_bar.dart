import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../controllers/topics_state.dart';

class TopicFilterBar extends StatelessWidget {
  const TopicFilterBar({
    required this.selectedFilter,
    required this.onFilterSelected,
    super.key,
  });

  final TopicProgressFilter selectedFilter;
  final ValueChanged<TopicProgressFilter> onFilterSelected;

  String _labelForFilter(TopicProgressFilter filter) {
    return switch (filter) {
      TopicProgressFilter.all => 'Semua',
      TopicProgressFilter.notStarted => 'Belum Mula',
      TopicProgressFilter.inProgress => 'Sedang Belajar',
      TopicProgressFilter.completed => 'Selesai',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TopicProgressFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(_labelForFilter(filter)),
                selected: selectedFilter == filter,
                onSelected: (_) {
                  onFilterSelected(filter);
                },
              ),
            ),
        ],
      ),
    );
  }
}
