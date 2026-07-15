import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/domain/entities/app_settings.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/controllers/app_settings_state.dart';

class _FakeAppSettingsRepository implements AppSettingsRepository {
  AppSettings? storedSettings;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<AppSettings?> loadSettings() async {
    return storedSettings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    storedSettings = settings;
    saveCallCount++;
  }

  @override
  Future<void> clearSettings() async {
    storedSettings = null;
    clearCallCount++;
  }
}

void main() {
  test('memuatkan dan mengemas kini tetapan aplikasi', () async {
    final repository = _FakeAppSettingsRepository();

    repository.storedSettings = const AppSettings(
      defaultQuizMode: QuizMode.exam,
      defaultQuestionCount: 20,
    );

    final container = ProviderContainer(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(appSettingsControllerProvider.notifier);

    await controller.loadSettings();

    var state = container.read(appSettingsControllerProvider);

    expect(state.status, AppSettingsStatus.success);

    expect(state.settings.defaultQuizMode, QuizMode.exam);

    expect(state.settings.defaultQuestionCount, 20);

    final modeError = await controller.updateDefaultQuizMode(QuizMode.practice);

    expect(modeError, isNull);

    final countError = await controller.updateDefaultQuestionCount(10);

    expect(countError, isNull);

    state = container.read(appSettingsControllerProvider);

    expect(state.settings.defaultQuizMode, QuizMode.practice);

    expect(state.settings.defaultQuestionCount, 10);

    expect(repository.saveCallCount, 2);
  });

  test('mengembalikan tetapan kepada nilai asal', () async {
    final repository = _FakeAppSettingsRepository();

    repository.storedSettings = const AppSettings(
      defaultQuizMode: QuizMode.exam,
      defaultQuestionCount: 20,
    );

    final container = ProviderContainer(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(appSettingsControllerProvider.notifier);

    await controller.loadSettings();

    final errorMessage = await controller.resetToDefaults();

    final state = container.read(appSettingsControllerProvider);

    expect(errorMessage, isNull);

    expect(state.settings.defaultQuizMode, QuizMode.practice);

    expect(state.settings.defaultQuestionCount, 10);

    expect(repository.clearCallCount, 1);

    expect(repository.storedSettings, AppSettings.defaults);
  });
}
