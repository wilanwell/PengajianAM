import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class LegalSectionCard extends StatelessWidget {
  const LegalSectionCard({
    required this.number,
    required this.title,
    required this.children,
    super.key,
  });

  final String number;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: AppRadius.medium,
                ),
                child: Text(
                  number,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._addSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _addSpacing(List<Widget> items) {
    if (items.isEmpty) {
      return const [];
    }

    final spacedItems = <Widget>[];

    for (var index = 0; index < items.length; index++) {
      spacedItems.add(items[index]);

      if (index < items.length - 1) {
        spacedItems.add(const SizedBox(height: AppSpacing.sm));
      }
    }

    return spacedItems;
  }
}

class LegalParagraph extends StatelessWidget {
  const LegalParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.secondaryText,
        height: 1.55,
      ),
    );
  }
}

class LegalBullet extends StatelessWidget {
  const LegalBullet({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.actionBlue,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class LegalContactBox extends StatelessWidget {
  const LegalContactBox({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          SelectableText(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
