import '../../domain/entities/leaderboard_preference.dart';

enum LeaderboardPreferenceStatus { initial, loading, success, failure }

class LeaderboardPreferenceState {
  const LeaderboardPreferenceState({
    this.status = LeaderboardPreferenceStatus.initial,
    this.preference,
    this.isUpdating = false,
    this.errorMessage,
  });

  final LeaderboardPreferenceStatus status;

  final LeaderboardPreference? preference;

  final bool isUpdating;

  final String? errorMessage;

  bool get isLoading {
    return status == LeaderboardPreferenceStatus.loading;
  }

  bool get isBusy {
    return isLoading || isUpdating;
  }

  bool get isOptedIn {
    return preference?.isOptedIn ?? false;
  }

  bool get canUpdate {
    return status == LeaderboardPreferenceStatus.success &&
        preference != null &&
        !isUpdating;
  }

  LeaderboardPreferenceState copyWith({
    LeaderboardPreferenceStatus? status,
    LeaderboardPreference? preference,
    bool? isUpdating,
    String? errorMessage,
    bool clearPreference = false,
    bool clearErrorMessage = false,
  }) {
    return LeaderboardPreferenceState(
      status: status ?? this.status,
      preference: clearPreference ? null : preference ?? this.preference,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
