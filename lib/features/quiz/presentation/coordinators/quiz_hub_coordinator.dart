import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../settings/presentation/controllers/app_settings_state.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_setup_controller.dart';

typedef QuizHubLoadAction = Future<void> Function(bool forceRefresh);

typedef QuizHubSettingsReader = AppSettingsState Function();

typedef QuizHubApplyDefaultsAction =
    void Function({required QuizMode mode, required int questionCount});

typedef QuizHubSelectTopicAction = void Function(String? topicId);

final quizHubCoordinatorProvider = Provider<QuizHubCoordinator>((ref) {
  return QuizHubCoordinator(
    loadTopicsAction: (forceRefresh) {
      return ref
          .read(topicsControllerProvider.notifier)
          .loadTopics(forceRefresh: forceRefresh);
    },
    loadSettingsAction: (forceRefresh) {
      return ref
          .read(appSettingsControllerProvider.notifier)
          .loadSettings(forceRefresh: forceRefresh);
    },
    readSettingsState: () {
      return ref.read(appSettingsControllerProvider);
    },
    applyDefaultsAction: ({required mode, required questionCount}) {
      ref
          .read(quizSetupControllerProvider.notifier)
          .applyDefaults(mode: mode, questionCount: questionCount);
    },
    selectTopicAction: (topicId) {
      ref.read(quizSetupControllerProvider.notifier).selectTopic(topicId);
    },
  );
});

class QuizHubCoordinator {
  const QuizHubCoordinator({
    required this.loadTopicsAction,
    required this.loadSettingsAction,
    required this.readSettingsState,
    required this.applyDefaultsAction,
    required this.selectTopicAction,
  });

  final QuizHubLoadAction loadTopicsAction;

  final QuizHubLoadAction loadSettingsAction;

  final QuizHubSettingsReader readSettingsState;

  final QuizHubApplyDefaultsAction applyDefaultsAction;

  final QuizHubSelectTopicAction selectTopicAction;

  Future<void> initialize({String? selectedTopicId}) async {
    await Future.wait<void>([
      loadTopicsAction(false),
      loadSettingsAction(false),
    ]);

    final settings = readSettingsState().settings;

    applyDefaultsAction(
      mode: settings.defaultQuizMode,
      questionCount: settings.defaultQuestionCount,
    );

    if (selectedTopicId != null) {
      selectTopicAction(selectedTopicId);
    }
  }

  Future<void> retryTopics() {
    return loadTopicsAction(true);
  }

  void synchronizeSelectedTopic({
    required String? previousTopicId,
    required String? nextTopicId,
  }) {
    if (previousTopicId == nextTopicId || nextTopicId == null) {
      return;
    }

    selectTopicAction(nextTopicId);
  }

  void synchronizeSettings({
    required AppSettingsState? previous,
    required AppSettingsState next,
  }) {
    final previousSettings = previous?.settings;

    final nextSettings = next.settings;

    final settingsChanged =
        previousSettings == null ||
        previousSettings.defaultQuizMode != nextSettings.defaultQuizMode ||
        previousSettings.defaultQuestionCount !=
            nextSettings.defaultQuestionCount;

    if (next.status != AppSettingsStatus.success || !settingsChanged) {
      return;
    }

    applyDefaultsAction(
      mode: nextSettings.defaultQuizMode,
      questionCount: nextSettings.defaultQuestionCount,
    );
  }
}
