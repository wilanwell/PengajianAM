import '../../domain/entities/app_settings.dart';

enum AppSettingsStatus { initial, loading, success, failure }

class AppSettingsState {
  const AppSettingsState({
    this.status = AppSettingsStatus.initial,
    this.settings = AppSettings.defaults,
    this.errorMessage,
  });

  final AppSettingsStatus status;
  final AppSettings settings;
  final String? errorMessage;

  AppSettingsState copyWith({
    AppSettingsStatus? status,
    AppSettings? settings,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AppSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
