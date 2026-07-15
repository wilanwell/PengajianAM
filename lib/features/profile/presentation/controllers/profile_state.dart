import '../../domain/entities/student_profile.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ProfileStatus status;
  final StudentProfile? profile;
  final String? errorMessage;

  bool get isLoading {
    return status == ProfileStatus.loading;
  }

  ProfileState copyWith({
    ProfileStatus? status,
    StudentProfile? profile,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
