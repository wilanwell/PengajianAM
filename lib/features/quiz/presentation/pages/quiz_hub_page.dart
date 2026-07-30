import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../settings/presentation/controllers/app_settings_state.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../../topics/presentation/controllers/topics_state.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_setup_controller.dart';
import '../controllers/quiz_setup_state.dart';
import '../coordinators/quiz_hub_coordinator.dart';
import '../widgets/quiz_hub_content.dart';
import '../widgets/quiz_hub_error_view.dart';
import '../widgets/quiz_hub_loading_view.dart';

class QuizHubPage extends ConsumerStatefulWidget {
  const QuizHubPage({this.selectedTopicId, super.key});

  final String? selectedTopicId;

  @override
  ConsumerState<QuizHubPage> createState() {
    return _QuizHubPageState();
  }
}

class _QuizHubPageState extends ConsumerState<QuizHubPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref
          .read(quizHubCoordinatorProvider)
          .initialize(selectedTopicId: widget.selectedTopicId);
    });
  }

  @override
  void didUpdateWidget(covariant QuizHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    Future<void>.microtask(() {
      ref
          .read(quizHubCoordinatorProvider)
          .synchronizeSelectedTopic(
            previousTopicId: oldWidget.selectedTopicId,
            nextTopicId: widget.selectedTopicId,
          );
    });
  }

  void _retryLoadingTopics() {
    unawaited(ref.read(quizHubCoordinatorProvider).retryTopics());
  }

  void _continueToInstructions(QuizSetupState setupState) {
    if (!setupState.canContinue) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Sila pilih topik sebelum '
              'meneruskan.',
            ),
          ),
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
      ref
          .read(quizHubCoordinatorProvider)
          .synchronizeSettings(previous: previous, next: next);
    });

    final topicsState = ref.watch(topicsControllerProvider);

    final setupState = ref.watch(quizSetupControllerProvider);

    final setupController = ref.read(quizSetupControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Kuiz')),
      body: SafeArea(
        child: switch (topicsState.status) {
          TopicsStatus.initial ||
          TopicsStatus.loading => const QuizHubLoadingView(),

          TopicsStatus.failure => QuizHubErrorView(
            message:
                topicsState.errorMessage ??
                'Senarai topik tidak dapat '
                    'dimuatkan.',
            onRetry: _retryLoadingTopics,
          ),

          TopicsStatus.success => QuizHubContent(
            topics: topicsState.topics,
            setupState: setupState,
            questionCounts: QuizSetupController.allowedQuestionCounts,
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
