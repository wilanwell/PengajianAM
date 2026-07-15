import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile_achievement.dart';
import '../../domain/entities/student_profile.dart';
import 'profile_state.dart';

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  static final List<ProfileAchievement> _mockAchievements =
      List<ProfileAchievement>.unmodifiable([
        const ProfileAchievement(
          id: 'achievement-first-quiz',
          type: AchievementType.firstQuiz,
          title: 'Langkah Pertama',
          description: 'Selesaikan kuiz pertama dalam aplikasi.',
          progress: 1,
          target: 1,
        ),
        const ProfileAchievement(
          id: 'achievement-high-score',
          type: AchievementType.highScore,
          title: 'Skor Cemerlang',
          description: 'Dapatkan sekurang-kurangnya 90% dalam satu kuiz.',
          progress: 82,
          target: 90,
        ),
        const ProfileAchievement(
          id: 'achievement-streak',
          type: AchievementType.sevenDayStreak,
          title: 'Konsisten 7 Hari',
          description: 'Belajar selama tujuh hari berturut-turut.',
          progress: 4,
          target: 7,
        ),
        const ProfileAchievement(
          id: 'achievement-topic-master',
          type: AchievementType.topicMaster,
          title: 'Penguasa Topik',
          description: 'Selesaikan semua topik Semester 1.',
          progress: 3,
          target: 7,
        ),
      ]);

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
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final profile = StudentProfile(
        userId: 'current-user',
        displayName: 'PelajarPA',
        email: 'pelajar@example.com',
        semesterLabel: 'Semester 1',
        joinedAt: DateTime(2026, 1, 10),
        totalXp: 1820,
        completedQuizzes: 8,
        averageScore: 76.0,
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
        achievements: _mockAchievements,
      );

      state = ProfileState(status: ProfileStatus.success, profile: profile);
    } catch (_) {
      state = const ProfileState(
        status: ProfileStatus.failure,
        errorMessage: 'Profil tidak dapat dimuatkan. Sila cuba semula.',
      );
    }
  }

  String? updateDisplayName(String value) {
    final profile = state.profile;

    if (profile == null) {
      return 'Maklumat profil belum tersedia.';
    }

    final normalizedName = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.length < 2) {
      return 'Nama mestilah sekurang-kurangnya 2 aksara.';
    }

    if (normalizedName.length > 30) {
      return 'Nama tidak boleh melebihi 30 aksara.';
    }

    state = state.copyWith(
      profile: profile.copyWith(displayName: normalizedName),
      clearErrorMessage: true,
    );

    return null;
  }

  Future<void> refreshProfile() {
    return loadProfile(forceRefresh: true);
  }

  void reset() {
    state = const ProfileState();
  }
}
