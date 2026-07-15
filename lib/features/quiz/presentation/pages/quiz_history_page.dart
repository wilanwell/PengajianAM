import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../controllers/quiz_history_controller.dart';
import '../controllers/quiz_history_state.dart';
import '../widgets/quiz_history_tile.dart';

class QuizHistoryPage extends ConsumerStatefulWidget {
  const QuizHistoryPage({super.key});

  @override
  ConsumerState<QuizHistoryPage> createState() {
    return _QuizHistoryPageState();
  }
}

class _QuizHistoryPageState extends ConsumerState<QuizHistoryPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(quizHistoryControllerProvider.notifier).loadHistory();
    });
  }

  void _openAttempt(QuizAttempt attempt) {
    context.pushNamed(RouteNames.quizResult, extra: attempt.result);
  }

  Future<void> _deleteAttempt(QuizAttempt attempt) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Padam Rekod?'),
          content: const Text(
            'Keputusan kuiz ini akan dipadamkan '
            'daripada sejarah kuiz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Padam'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref
        .read(quizHistoryControllerProvider.notifier)
        .deleteAttempt(attempt.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Rekod kuiz telah dipadamkan.')),
      );
  }

  Future<void> _clearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Padam Semua Sejarah?'),
          content: const Text(
            'Semua keputusan kuiz terdahulu akan '
            'dipadamkan secara kekal.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Padam Semua'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    await ref.read(quizHistoryControllerProvider.notifier).clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizHistoryControllerProvider);

    final controller = ref.read(quizHistoryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sejarah Kuiz'),
        actions: [
          if (state.status == QuizHistoryStatus.success &&
              state.attempts.isNotEmpty)
            IconButton(
              tooltip: 'Padam semua sejarah',
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          QuizHistoryStatus.initial || QuizHistoryStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          QuizHistoryStatus.failure => _QuizHistoryErrorView(
            message:
                state.errorMessage ?? 'Sejarah kuiz tidak dapat dimuatkan.',
            onRetry: () {
              controller.loadHistory(forceRefresh: true);
            },
          ),

          QuizHistoryStatus.success => _QuizHistoryContent(
            state: state,
            onRefresh: controller.refreshHistory,
            onOpenAttempt: _openAttempt,
            onDeleteAttempt: _deleteAttempt,
          ),
        },
      ),
    );
  }
}

class _QuizHistoryContent extends StatelessWidget {
  const _QuizHistoryContent({
    required this.state,
    required this.onRefresh,
    required this.onOpenAttempt,
    required this.onDeleteAttempt,
  });

  final QuizHistoryState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<QuizAttempt> onOpenAttempt;
  final ValueChanged<QuizAttempt> onDeleteAttempt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          _HistorySummaryCard(state: state),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Percubaan Terdahulu', style: textTheme.titleLarge),
              ),
              Text(
                '${state.totalAttempts} rekod',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.attempts.isEmpty)
            const _QuizHistoryEmptyView()
          else
            for (final attempt in state.attempts) ...[
              QuizHistoryTile(
                attempt: attempt,
                onTap: () {
                  onOpenAttempt(attempt);
                },
                onDelete: () {
                  onDeleteAttempt(attempt);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({required this.state});

  final QuizHistoryState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.history_rounded,
              value: '${state.totalAttempts}',
              label: 'Percubaan',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.track_changes_rounded,
              value: '${state.averageScore.round()}%',
              label: 'Purata',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.star_rounded,
              value: '${state.totalEarnedXp}',
              label: 'XP Diperoleh',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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

class _QuizHistoryEmptyView extends StatelessWidget {
  const _QuizHistoryEmptyView();

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
            Icons.history_toggle_off_rounded,
            size: 56,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Belum Ada Sejarah Kuiz', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Keputusan kuiz yang dihantar akan '
            'dipaparkan di halaman ini.',
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

class _QuizHistoryErrorView extends StatelessWidget {
  const _QuizHistoryErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
            Text(message, textAlign: TextAlign.center),
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
