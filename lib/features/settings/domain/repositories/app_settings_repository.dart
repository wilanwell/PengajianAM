import '../entities/app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings?> loadSettings();

  Future<void> saveSettings(AppSettings settings);

  Future<void> clearSettings();
}
