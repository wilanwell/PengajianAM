import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_state.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';

class _FakeUserProgressRepository implements UserProgressRepository {
  UserProgress progress = UserProgress(
    userId: 'user-1',
    displayName: 'PelajarPA',
    email: 'student@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime(2026, 1, 10),
    totalXp: 1820,
    weeklyXp: 1820,
    monthlyXp: 6540,
    completedQuizzes: 8,
    totalCorrectAnswers: 122,
    totalQuizQuestions: 160,
    highestScore: 82,
    completedTopics: 3,
    totalTopics: 7,
    currentStreakDays: 4,
    bestStreakDays: 9,
    weeklyAnsweredQuestions: List<int>.unmodifiable([
      12,
      18,
      8,
      24,
      20,
      30,
      16,
    ]),
  );

  @override
  Future<UserProgress?> loadProgress() async {
    return progress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    this.progress = progress;
  }

  @override
  Future<void> clearProgress() async {
    progress = progress.copyWith(
      totalXp: 0,
      weeklyXp: 0,
      monthlyXp: 0,
      completedQuizzes: 0,
      totalCorrectAnswers: 0,
      totalQuizQuestions: 0,
      highestScore: 0,
      completedTopics: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
      weeklyAnsweredQuestions: List<int>.unmodifiable([0, 0, 0, 0, 0, 0, 0]),
    );
  }
}

void main() {
  test('memuatkan dan mengemas kini profil pengguna', () async {
    final repository = _FakeUserProgressRepository();

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(profileControllerProvider.notifier);

    await controller.loadProfile();

    var state = container.read(profileControllerProvider);

    expect(state.status, ProfileStatus.success);

    expect(state.profile, isNotNull);

    expect(state.profile!.displayName, 'PelajarPA');

    expect(state.profile!.achievements, hasLength(4));

    expect(state.profile!.topicProgressPercentage, 43);

    final invalidNameError = await controller.updateDisplayName('A');

    expect(invalidNameError, isNotNull);

    final validNameError = await controller.updateDisplayName(
      'Welljoel Walter',
    );

    expect(validNameError, isNull);

    state = container.read(profileControllerProvider);

    expect(state.profile!.displayName, 'Welljoel Walter');

    expect(state.profile!.initials, 'WW');

    expect(repository.progress.displayName, 'Welljoel Walter');
  });
}
