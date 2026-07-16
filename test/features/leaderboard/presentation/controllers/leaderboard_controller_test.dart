import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_state.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';

class _FakeUserProgressRepository implements UserProgressRepository {
  UserProgress progress = UserProgress(
    userId: 'current-user',
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
  test('memuatkan dan menukar tempoh leaderboard', () async {
    final repository = _FakeUserProgressRepository();

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(leaderboardControllerProvider.notifier);

    await controller.loadLeaderboard();

    var state = container.read(leaderboardControllerProvider);

    expect(state.status, LeaderboardStatus.success);

    expect(state.period, LeaderboardPeriod.weekly);

    expect(state.entries, hasLength(10));

    expect(state.currentUserEntry?.rank, 5);

    expect(state.currentUserEntry?.xp, 1820);

    expect(state.topThree, hasLength(3));

    await controller.changePeriod(LeaderboardPeriod.monthly);

    state = container.read(leaderboardControllerProvider);

    expect(state.period, LeaderboardPeriod.monthly);

    expect(state.currentUserEntry?.rank, 6);

    expect(state.currentUserEntry?.xp, 6540);
  });
}
