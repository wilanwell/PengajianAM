import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';
import '../controllers/quiz_session_controller.dart';

class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({required this.result, super.key});

  final QuizResult result;

  String get _elapsedTimeLabel {
    final minutes = result.elapsedTime.inMinutes;
    final seconds = result.elapsedTime.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _retryQuiz(BuildContext context, WidgetRef ref) {
    ref.read(quizSessionControllerProvider.notifier).reset();

    context.goNamed(
      RouteNames.quiz,
      queryParameters: {'topicId': result.topicId},
    );
  }

  void _showReviewPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Semakan jawapan akan dibina pada langkah seterusnya.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final percentage = result.percentage.round();

    return Scaffold(
      appBar: AppBar(title: const Text('Keputusan Kuiz')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Container(
              padding: AppSpacing.largeCardPadding,
              decoration: BoxDecoration(
                color: result.passed
                    ? AppColors.successBackground
                    : AppColors.warningBackground,
                borderRadius: AppRadius.extraLarge,
              ),
              child: Column(
                children: [
                  Container(
                    width: 144,
                    height: 144,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: result.passed
                            ? AppColors.success
                            : AppColors.warning,
                        width: 10,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${result.correctAnswers}/'
                          '${result.totalQuestions}',
                          style: textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    result.passed ? 'Bagus!' : 'Teruskan Berusaha',
                    style: textTheme.headlineSmall?.copyWith(
                      color: result.passed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.autoSubmitted
                        ? 'Masa tamat dan kuiz telah dihantar '
                              'secara automatik.'
                        : 'Kuiz anda telah berjaya dihantar.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpacing.sm;

                final cardWidth = constraints.maxWidth < 420
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _ResultStatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Betul',
                        value: '${result.correctAnswers}',
                        color: AppColors.success,
                        backgroundColor: AppColors.successBackground,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _ResultStatCard(
                        icon: Icons.cancel_rounded,
                        label: 'Salah',
                        value: '${result.incorrectAnswers}',
                        color: AppColors.error,
                        backgroundColor: AppColors.errorBackground,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _ResultStatCard(
                        icon: Icons.help_outline_rounded,
                        label: 'Tidak Dijawab',
                        value: '${result.unansweredQuestions}',
                        color: AppColors.warning,
                        backgroundColor: AppColors.warningBackground,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _ResultStatCard(
                        icon: Icons.timer_outlined,
                        label: 'Masa Digunakan',
                        value: _elapsedTimeLabel,
                        color: AppColors.actionBlue,
                        backgroundColor: AppColors.softBlue,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                _showReviewPlaceholder(context);
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Semak Jawapan'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                _retryQuiz(context, ref);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Lagi'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                context.goNamed(RouteNames.topics);
              },
              child: const Text('Kembali ke Topik'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStatCard extends StatelessWidget {
  const _ResultStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
                Text(value, style: textTheme.titleLarge),
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
