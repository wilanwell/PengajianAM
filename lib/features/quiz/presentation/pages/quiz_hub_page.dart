import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../../topics/presentation/controllers/topics_state.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../settings/presentation/controllers/app_settings_state.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_setup_controller.dart';
import '../controllers/quiz_setup_state.dart';
import '../widgets/quiz_mode_card.dart';

class QuizHubPage extends ConsumerStatefulWidget {
  const QuizHubPage({this.selectedTopicId, super.key});

  final String? selectedTopicId;

  @override
  ConsumerState<QuizHubPage> createState() => _QuizHubPageState();
}

class _QuizHubPageState extends ConsumerState<QuizHubPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_initializeQuizHub);
  }

  Future<void> _initializeQuizHub() async {
    await Future.wait<void>([
      ref.read(topicsControllerProvider.notifier).loadTopics(),
      ref.read(appSettingsControllerProvider.notifier).loadSettings(),
    ]);

    if (!mounted) {
      return;
    }

    final appSettingsState = ref.read(appSettingsControllerProvider);

    final setupController = ref.read(quizSetupControllerProvider.notifier);

    setupController.applyDefaults(
      mode: appSettingsState.settings.defaultQuizMode,
      questionCount: appSettingsState.settings.defaultQuestionCount,
    );

    if (widget.selectedTopicId != null) {
      setupController.selectTopic(widget.selectedTopicId);
    }
  }

  @override
  void didUpdateWidget(covariant QuizHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTopicId != widget.selectedTopicId &&
        widget.selectedTopicId != null) {
      Future<void>.microtask(() {
        ref
            .read(quizSetupControllerProvider.notifier)
            .selectTopic(widget.selectedTopicId);
      });
    }
  }

  void _continueToInstructions(QuizSetupState setupState) {
    if (!setupState.canContinue) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Sila pilih topik sebelum meneruskan.')),
        );

      return;
    }

    context.pushNamed(
      RouteNames.quizInstruction,
      queryParameters: {
        'topicId': setupState.selectedTopicId!,
        'mode': setupState.mode.routeValue,
        'questionCount': setupState.questionCount.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettingsState>(appSettingsControllerProvider, (
      previous,
      next,
    ) {
      final previousSettings = previous?.settings;
      final nextSettings = next.settings;

      final settingsChanged =
          previousSettings == null ||
          previousSettings.defaultQuizMode != nextSettings.defaultQuizMode ||
          previousSettings.defaultQuestionCount !=
              nextSettings.defaultQuestionCount;

      if (next.status == AppSettingsStatus.success && settingsChanged) {
        ref
            .read(quizSetupControllerProvider.notifier)
            .applyDefaults(
              mode: nextSettings.defaultQuizMode,
              questionCount: nextSettings.defaultQuestionCount,
            );
      }
    });

    final topicsState = ref.watch(topicsControllerProvider);

    final setupState = ref.watch(quizSetupControllerProvider);

    final setupController = ref.read(quizSetupControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Kuiz')),
      body: SafeArea(
        child: switch (topicsState.status) {
          TopicsStatus.initial || TopicsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),

          TopicsStatus.failure => _QuizHubErrorView(
            message:
                topicsState.errorMessage ??
                'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {
              ref
                  .read(topicsControllerProvider.notifier)
                  .loadTopics(forceRefresh: true);
            },
          ),

          TopicsStatus.success => _QuizHubContent(
            topics: topicsState.topics,
            setupState: setupState,
            onTopicChanged: setupController.selectTopic,
            onModeChanged: setupController.selectMode,
            onQuestionCountChanged: setupController.selectQuestionCount,
            onContinue: () {
              _continueToInstructions(setupState);
            },
          ),
        },
      ),
    );
  }
}

class _QuizHubContent extends StatelessWidget {
  const _QuizHubContent({
    required this.topics,
    required this.setupState,
    required this.onTopicChanged,
    required this.onModeChanged,
    required this.onQuestionCountChanged,
    required this.onContinue,
  });

  final List<StudyTopic> topics;
  final QuizSetupState setupState;
  final ValueChanged<String?> onTopicChanged;
  final ValueChanged<QuizMode> onModeChanged;
  final ValueChanged<int> onQuestionCountChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final topicIds = topics.map((topic) => topic.id).toSet();

    final selectedTopicId = topicIds.contains(setupState.selectedTopicId)
        ? setupState.selectedTopicId
        : null;

    final selectedTopic = selectedTopicId == null
        ? null
        : topics.firstWhere((topic) => topic.id == selectedTopicId);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Container(
          padding: AppSpacing.largeCardPadding,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: AppRadius.extraLarge,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.textOnPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sediakan Kuiz',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Pilih topik dan tetapan kuiz anda.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Pilih Topik', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          key: ValueKey(selectedTopicId),
          initialValue: selectedTopicId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Topik Semester 1',
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          hint: const Text('Pilih satu topik'),
          items: [
            for (final topic in topics)
              DropdownMenuItem<String>(
                value: topic.id,
                child: Text(
                  '${topic.code} · ${topic.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onTopicChanged,
        ),
        if (selectedTopic != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            selectedTopic.description,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Pilih Mode', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
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
                  child: QuizModeCard(
                    mode: QuizMode.practice,
                    isSelected: setupState.mode == QuizMode.practice,
                    onTap: () {
                      onModeChanged(QuizMode.practice);
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuizModeCard(
                    mode: QuizMode.exam,
                    isSelected: setupState.mode == QuizMode.exam,
                    onTap: () {
                      onModeChanged(QuizMode.exam);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Jumlah Soalan', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final count in QuizSetupController.allowedQuestionCounts)
              ChoiceChip(
                label: Text('$count soalan'),
                selected: setupState.questionCount == count,
                onSelected: (_) {
                  onQuestionCountChanged(count);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _QuizSetupSummaryCard(
          setupState: setupState,
          selectedTopic: selectedTopic,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: setupState.canContinue ? onContinue : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Lihat Arahan Kuiz'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _QuizSetupSummaryCard extends StatelessWidget {
  const _QuizSetupSummaryCard({
    required this.setupState,
    required this.selectedTopic,
  });

  final QuizSetupState setupState;
  final StudyTopic? selectedTopic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final durationLabel = setupState.durationMinutes == null
        ? 'Tiada had masa'
        : '${setupState.durationMinutes} minit';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Tetapan', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            icon: Icons.menu_book_outlined,
            label: 'Topik',
            value: selectedTopic?.title ?? 'Belum dipilih',
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.school_outlined,
            label: 'Mode',
            value: setupState.mode.label,
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.quiz_outlined,
            label: 'Soalan',
            value: '${setupState.questionCount} soalan',
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Masa',
            value: durationLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _QuizHubErrorView extends StatelessWidget {
  const _QuizHubErrorView({required this.message, required this.onRetry});

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
