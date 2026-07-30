import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_hub_coordinator.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/domain/entities/app_settings.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/controllers/app_settings_state.dart';

void main() {
  group('QuizHubCoordinator', () {
    test(
      'initialize memuatkan data dan menggunakan default settings',
      () async {
        final calls = <String>[];

        final coordinator = _createCoordinator(
          calls: calls,
          settingsState: const AppSettingsState(
            status: AppSettingsStatus.success,
            settings: AppSettings(
              defaultQuizMode: QuizMode.exam,
              defaultQuestionCount: 20,
            ),
          ),
        );

        await coordinator.initialize(selectedTopicId: 'topic-1');

        expect(calls, [
          'loadTopics:false',
          'loadSettings:false',
          'readSettingsState',
          'applyDefaults:exam:20',
          'selectTopic:topic-1',
        ]);
      },
    );

    test('initialize tidak memilih topik apabila route topic null', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.initialize();

      expect(calls, [
        'loadTopics:false',
        'loadSettings:false',
        'readSettingsState',
        'applyDefaults:practice:10',
      ]);
    });

    test('retryTopics menggunakan force refresh', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.retryTopics();

      expect(calls, ['loadTopics:true']);
    });

    test('synchronizeSelectedTopic memilih topic id baharu', () {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      coordinator.synchronizeSelectedTopic(
        previousTopicId: 'topic-1',
        nextTopicId: 'topic-2',
      );

      expect(calls, ['selectTopic:topic-2']);
    });

    test('synchronizeSelectedTopic mengabaikan nilai sama dan null', () {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      coordinator.synchronizeSelectedTopic(
        previousTopicId: 'topic-1',
        nextTopicId: 'topic-1',
      );

      coordinator.synchronizeSelectedTopic(
        previousTopicId: 'topic-1',
        nextTopicId: null,
      );

      expect(calls, isEmpty);
    });

    test('synchronizeSettings menggunakan settings baharu apabila berjaya', () {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      coordinator.synchronizeSettings(
        previous: const AppSettingsState(
          status: AppSettingsStatus.success,
          settings: AppSettings(
            defaultQuizMode: QuizMode.practice,
            defaultQuestionCount: 10,
          ),
        ),
        next: const AppSettingsState(
          status: AppSettingsStatus.success,
          settings: AppSettings(
            defaultQuizMode: QuizMode.exam,
            defaultQuestionCount: 20,
          ),
        ),
      );

      expect(calls, ['applyDefaults:exam:20']);
    });

    test('synchronizeSettings mengabaikan settings yang tidak berubah', () {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      coordinator.synchronizeSettings(
        previous: const AppSettingsState(status: AppSettingsStatus.success),
        next: const AppSettingsState(status: AppSettingsStatus.success),
      );

      expect(calls, isEmpty);
    });

    test('synchronizeSettings mengabaikan state failure', () {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      coordinator.synchronizeSettings(
        previous: null,
        next: const AppSettingsState(
          status: AppSettingsStatus.failure,
          settings: AppSettings(
            defaultQuizMode: QuizMode.exam,
            defaultQuestionCount: 20,
          ),
        ),
      );

      expect(calls, isEmpty);
    });
  });
}

QuizHubCoordinator _createCoordinator({
  required List<String> calls,
  AppSettingsState settingsState = const AppSettingsState(
    status: AppSettingsStatus.success,
  ),
}) {
  return QuizHubCoordinator(
    loadTopicsAction: (forceRefresh) async {
      calls.add('loadTopics:$forceRefresh');
    },
    loadSettingsAction: (forceRefresh) async {
      calls.add('loadSettings:$forceRefresh');
    },
    readSettingsState: () {
      calls.add('readSettingsState');

      return settingsState;
    },
    applyDefaultsAction: ({required mode, required questionCount}) {
      calls.add(
        'applyDefaults:'
        '${mode.name}:'
        '$questionCount',
      );
    },
    selectTopicAction: (topicId) {
      calls.add('selectTopic:$topicId');
    },
  );
}
