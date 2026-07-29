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
      return ref.read(quizHistoryControllerProvider.notifier).loadHistory();
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
            'Rekod ini akan dipadamkan daripada '
            'sejarah dan analitik topik. '
            'XP keseluruhan anda tidak akan ditolak.',
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

    final deleted = await ref
        .read(quizHistoryControllerProvider.notifier)
        .deleteAttempt(attempt.id);

    if (!mounted) {
      return;
    }

    final state = ref.read(quizHistoryControllerProvider);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Rekod kuiz telah dipadamkan.'
                : state.errorMessage ?? 'Rekod kuiz tidak dapat dipadamkan.',
          ),
        ),
      );
  }

  Future<void> _clearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Padam Semua Sejarah?'),
          content: const Text(
            'Semua keputusan kuiz dan analitik '
            'mengikut topik akan dipadamkan. '
            'XP dan progress keseluruhan tidak '
            'akan dikurangkan.',
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

    final cleared = await ref
        .read(quizHistoryControllerProvider.notifier)
        .clearHistory();

    if (!mounted) {
      return;
    }

    final state = ref.read(quizHistoryControllerProvider);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            cleared
                ? 'Semua sejarah kuiz telah dipadamkan.'
                : state.errorMessage ?? 'Sejarah kuiz tidak dapat dipadamkan.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizHistoryControllerProvider);

    final controller = ref.read(quizHistoryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sejarah Kuiz'),
        actions: [
          if (state.attempts.isNotEmpty)
            IconButton(
              key: const Key('quiz-history-clear-button'),
              tooltip: 'Padam semua sejarah',
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildStateContent(
          state: state,
          onRefresh: controller.refreshHistory,
          onRetry: () {
            controller.loadHistory(forceRefresh: true);
          },
        ),
      ),
    );
  }

  Widget _buildStateContent({
    required QuizHistoryState state,
    required Future<void> Function() onRefresh,
    required VoidCallback onRetry,
  }) {
    switch (state.status) {
      case QuizHistoryStatus.initial:
        return const _QuizHistoryLoadingView();

      case QuizHistoryStatus.loading:
        if (state.attempts.isEmpty) {
          return const _QuizHistoryLoadingView();
        }

        return _QuizHistoryContent(
          state: state,
          onRefresh: onRefresh,
          onOpenAttempt: _openAttempt,
          onDeleteAttempt: _deleteAttempt,
          isRefreshing: true,
        );

      case QuizHistoryStatus.failure:
        if (state.attempts.isEmpty) {
          return _QuizHistoryErrorView(
            message:
                state.errorMessage ?? 'Sejarah kuiz tidak dapat dimuatkan.',
            onRetry: onRetry,
          );
        }

        return _QuizHistoryContent(
          state: state,
          onRefresh: onRefresh,
          onOpenAttempt: _openAttempt,
          onDeleteAttempt: _deleteAttempt,
          staleErrorMessage:
              state.errorMessage ??
              'Data baharu tidak dapat dimuatkan. '
                  'Sejarah terakhir masih dipaparkan.',
        );

      case QuizHistoryStatus.success:
        return _QuizHistoryContent(
          state: state,
          onRefresh: onRefresh,
          onOpenAttempt: _openAttempt,
          onDeleteAttempt: _deleteAttempt,
        );
    }
  }
}

class _QuizHistoryContent extends StatelessWidget {
  const _QuizHistoryContent({
    required this.state,
    required this.onRefresh,
    required this.onOpenAttempt,
    required this.onDeleteAttempt,
    this.isRefreshing = false,
    this.staleErrorMessage,
  });

  final QuizHistoryState state;

  final Future<void> Function() onRefresh;

  final ValueChanged<QuizAttempt> onOpenAttempt;

  final ValueChanged<QuizAttempt> onDeleteAttempt;

  final bool isRefreshing;

  final String? staleErrorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('quiz-history-main-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          if (isRefreshing) ...[
            const LinearProgressIndicator(
              key: Key('quiz-history-refresh-progress'),
              minHeight: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (staleErrorMessage != null) ...[
            _QuizHistoryStaleDataWarning(message: staleErrorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          _HistorySummaryCard(state: state),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Percubaan Terdahulu', style: textTheme.titleLarge),
              ),
              Text(
                '${state.totalAttempts} rekod',
                key: const Key('quiz-history-record-count'),
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
                key: Key(
                  'quiz-history-attempt-'
                  '${attempt.id}',
                ),
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
          if (state.lastUpdated != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dikemas kini '
              '${_formatDateTime(state.lastUpdated!)}',
              key: const Key('quiz-history-last-updated'),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
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
      key: const Key('quiz-history-summary'),
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              key: const Key('quiz-history-summary-attempts'),
              icon: Icons.history_rounded,
              value: '${state.totalAttempts}',
              label: 'Percubaan',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              key: const Key('quiz-history-summary-average'),
              icon: Icons.track_changes_rounded,
              value: '${state.averageScore.round()}%',
              label: 'Purata',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              key: const Key('quiz-history-summary-xp'),
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

class _QuizHistoryStaleDataWarning extends StatelessWidget {
  const _QuizHistoryStaleDataWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('quiz-history-stale-warning'),
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

class _QuizHistoryEmptyView extends StatelessWidget {
  const _QuizHistoryEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('quiz-history-empty'),
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

class _QuizHistoryLoadingView extends StatelessWidget {
  const _QuizHistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _QuizHistoryErrorView extends StatelessWidget {
  const _QuizHistoryErrorView({required this.message, required this.onRetry});

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

String _formatDateTime(DateTime value) {
  final localValue = value.toLocal();

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  final hour = localValue.hour.toString().padLeft(2, '0');

  final minute = localValue.minute.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year} '
      'pada $hour:$minute';
}
