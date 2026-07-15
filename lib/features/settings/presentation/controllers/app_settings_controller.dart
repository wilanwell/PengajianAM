import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../quiz/domain/entities/quiz_mode.dart';
import '../../data/repositories/shared_preferences_app_settings_repository.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import 'app_settings_state.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return SharedPreferencesAppSettingsRepository();
});

final appSettingsControllerProvider =
    NotifierProvider<AppSettingsController, AppSettingsState>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettingsState> {
  AppSettingsRepository get _repository {
    return ref.read(appSettingsRepositoryProvider);
  }

  @override
  AppSettingsState build() {
    return const AppSettingsState();
  }

  Future<void> loadSettings({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == AppSettingsStatus.loading ||
            state.status == AppSettingsStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: AppSettingsStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final storedSettings = await _repository.loadSettings();

      state = AppSettingsState(
        status: AppSettingsStatus.success,
        settings: storedSettings ?? AppSettings.defaults,
      );
    } catch (_) {
      state = const AppSettingsState(
        status: AppSettingsStatus.failure,
        settings: AppSettings.defaults,
        errorMessage: 'Tetapan aplikasi tidak dapat dimuatkan.',
      );
    }
  }

  Future<String?> updateDefaultQuizMode(QuizMode mode) async {
    await _ensureLoaded();

    final previousSettings = state.settings;

    final updatedSettings = previousSettings.copyWith(defaultQuizMode: mode);

    state = AppSettingsState(
      status: AppSettingsStatus.success,
      settings: updatedSettings,
    );

    try {
      await _repository.saveSettings(updatedSettings);

      return null;
    } catch (_) {
      state = AppSettingsState(
        status: AppSettingsStatus.success,
        settings: previousSettings,
      );

      return 'Mode kuiz lalai tidak dapat disimpan.';
    }
  }

  Future<String?> updateDefaultQuestionCount(int questionCount) async {
    if (!AppSettings.allowedQuestionCounts.contains(questionCount)) {
      return 'Jumlah soalan tidak disokong.';
    }

    await _ensureLoaded();

    final previousSettings = state.settings;

    final updatedSettings = previousSettings.copyWith(
      defaultQuestionCount: questionCount,
    );

    state = AppSettingsState(
      status: AppSettingsStatus.success,
      settings: updatedSettings,
    );

    try {
      await _repository.saveSettings(updatedSettings);

      return null;
    } catch (_) {
      state = AppSettingsState(
        status: AppSettingsStatus.success,
        settings: previousSettings,
      );

      return 'Jumlah soalan lalai tidak dapat disimpan.';
    }
  }

  Future<String?> resetToDefaults() async {
    final previousSettings = state.settings;

    state = const AppSettingsState(
      status: AppSettingsStatus.success,
      settings: AppSettings.defaults,
    );

    try {
      await _repository.clearSettings();

      await _repository.saveSettings(AppSettings.defaults);

      return null;
    } catch (_) {
      state = AppSettingsState(
        status: AppSettingsStatus.success,
        settings: previousSettings,
      );

      return 'Tetapan aplikasi tidak dapat direset.';
    }
  }

  void resetState() {
    state = const AppSettingsState();
  }

  Future<void> _ensureLoaded() async {
    if (state.status == AppSettingsStatus.initial ||
        state.status == AppSettingsStatus.failure) {
      await loadSettings(forceRefresh: true);
    }
  }
}
