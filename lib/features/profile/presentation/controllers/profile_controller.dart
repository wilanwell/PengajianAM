import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../domain/entities/profile_achievement.dart';
import '../../domain/entities/student_profile.dart';
import 'profile_state.dart';

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == ProfileStatus.loading ||
            state.status == ProfileStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: ProfileStatus.loading,
      clearErrorMessage: true,
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final progress = ref.read(userProgressControllerProvider);

      state = ProfileState(
        status: ProfileStatus.success,
        profile: _buildStudentProfile(progress),
      );
    } catch (_) {
      state = const ProfileState(
        status: ProfileStatus.failure,
        errorMessage: 'Profil tidak dapat dimuatkan. Sila cuba semula.',
      );
    }
  }

  String? updateDisplayName(String value) {
    final errorMessage = ref
        .read(userProgressControllerProvider.notifier)
        .updateDisplayName(value);

    if (errorMessage != null) {
      return errorMessage;
    }

    final progress = ref.read(userProgressControllerProvider);

    state = ProfileState(
      status: ProfileStatus.success,
      profile: _buildStudentProfile(progress),
    );

    return null;
  }

  Future<void> refreshProfile() {
    return loadProfile(forceRefresh: true);
  }

  void reset() {
    state = const ProfileState();
  }

  StudentProfile _buildStudentProfile(UserProgress progress) {
    return StudentProfile(
      userId: progress.userId,
      displayName: progress.displayName,
      email: progress.email,
      semesterLabel: progress.semesterLabel,
      joinedAt: progress.joinedAt,
      totalXp: progress.totalXp,
      completedQuizzes: progress.completedQuizzes,
      averageScore: progress.averageScore,
      completedTopics: progress.completedTopics,
      totalTopics: progress.totalTopics,
      currentStreakDays: progress.currentStreakDays,
      bestStreakDays: progress.bestStreakDays,
      weeklyAnsweredQuestions: List<int>.unmodifiable(
        progress.weeklyAnsweredQuestions,
      ),
      achievements: _buildAchievements(progress),
    );
  }

  List<ProfileAchievement> _buildAchievements(UserProgress progress) {
    return List<ProfileAchievement>.unmodifiable([
      ProfileAchievement(
        id: 'achievement-first-quiz',
        type: AchievementType.firstQuiz,
        title: 'Langkah Pertama',
        description: 'Selesaikan kuiz pertama dalam aplikasi.',
        progress: math.min(progress.completedQuizzes, 1),
        target: 1,
      ),
      ProfileAchievement(
        id: 'achievement-high-score',
        type: AchievementType.highScore,
        title: 'Skor Cemerlang',
        description: 'Dapatkan sekurang-kurangnya 90% dalam satu kuiz.',
        progress: math.min(progress.highestScore.round(), 90),
        target: 90,
      ),
      ProfileAchievement(
        id: 'achievement-streak',
        type: AchievementType.sevenDayStreak,
        title: 'Konsisten 7 Hari',
        description: 'Belajar selama tujuh hari berturut-turut.',
        progress: math.min(progress.currentStreakDays, 7),
        target: 7,
      ),
      ProfileAchievement(
        id: 'achievement-topic-master',
        type: AchievementType.topicMaster,
        title: 'Penguasa Topik',
        description: 'Selesaikan semua topik Semester 1.',
        progress: progress.completedTopics,
        target: progress.totalTopics,
      ),
    ]);
  }
}
