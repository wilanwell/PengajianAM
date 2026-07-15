import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({required this.values, super.key});

  final List<int> values;

  static const List<String> _dayLabels = ['I', 'S', 'R', 'K', 'J', 'S', 'A'];

  int get _maximumValue {
    var maximum = 1;

    for (final value in values) {
      if (value > maximum) {
        maximum = value;
      }
    }

    return maximum;
  }

  int get _totalAnswered {
    return values.fold<int>(0, (total, value) => total + value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Aktiviti Mingguan', style: textTheme.titleLarge),
              ),
              Text(
                '$_totalAnswered soalan',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.actionBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jumlah soalan yang dijawab sepanjang minggu ini.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (values.isEmpty)
            const Center(child: Text('Tiada aktiviti direkodkan.'))
          else
            SizedBox(
              height: 138,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < values.length; index++)
                    Expanded(
                      child: _ActivityBar(
                        value: values[index],
                        maximumValue: _maximumValue,
                        dayLabel: index < _dayLabels.length
                            ? _dayLabels[index]
                            : '${index + 1}',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Teruskan belajar setiap hari untuk '
                  'mengekalkan streak anda.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.value,
    required this.maximumValue,
    required this.dayLabel,
  });

  final int value;
  final int maximumValue;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final heightFactor = maximumValue == 0
        ? 0.08
        : (value / maximumValue).clamp(0.08, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        children: [
          Text(
            '$value',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                widthFactor: 0.65,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.actionBlue,
                    borderRadius: AppRadius.fullyRounded,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(dayLabel, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
