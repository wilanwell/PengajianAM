import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../quiz/domain/entities/quiz_result.dart';
import '../../data/repositories/shared_preferences_user_progress_repository.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  return SharedPreferencesUserProgressRepository();
});

final userProgressControllerProvider =
    NotifierProvider<UserProgressController, UserProgress>(
      UserProgressController.new,
    );

class UserProgressController extends Notifier<UserProgress> {
  Future<void>? _initializationFuture;

  UserProgressRepository get _repository {
    return ref.read(userProgressRepositoryProvider);
  }

  @override
  UserProgress build() {
    return _initialProgress();
  }

  Future<void> initialize() {
    return _initializationFuture ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    try {
      final storedProgress = await _repository.loadProgress();

      if (storedProgress != null) {
        state = storedProgress;
      }
    } catch (_) {
      // Aplikasi masih boleh digunakan menggunakan mock defaults.
    }
  }

  int calculateEarnedXp(QuizResult result) {
    final correctAnswerXp = result.correctAnswers * 10;

    final completionBonus = result.answeredQuestions == result.totalQuestions
        ? 20
        : 0;

    final perfectScoreBonus =
        result.totalQuestions > 0 &&
            result.correctAnswers == result.totalQuestions
        ? 50
        : 0;

    return correctAnswerXp + completionBonus + perfectScoreBonus;
  }

  Future<void> recordQuizResult(QuizResult result) {
    return recordServerQuizResult(
      result: result,
      earnedXp: calculateEarnedXp(result),
    );
  }

  Future<void> recordServerQuizResult({
    required QuizResult result,
    required int earnedXp,
  }) async {
    await initialize();

    final normalizedEarnedXp = earnedXp < 0 ? 0 : earnedXp;

    final updatedWeeklyActivity = List<int>.filled(7, 0);

    for (
      var index = 0;
      index < state.weeklyAnsweredQuestions.length &&
          index < updatedWeeklyActivity.length;
      index++
    ) {
      updatedWeeklyActivity[index] = state.weeklyAnsweredQuestions[index];
    }

    final currentDayIndex = DateTime.now().weekday - 1;

    updatedWeeklyActivity[currentDayIndex] += result.answeredQuestions;

    state = state.copyWith(
      totalXp: state.totalXp + normalizedEarnedXp,
      weeklyXp: state.weeklyXp + normalizedEarnedXp,
      monthlyXp: state.monthlyXp + normalizedEarnedXp,
      completedQuizzes: state.completedQuizzes + 1,
      totalCorrectAnswers: state.totalCorrectAnswers + result.correctAnswers,
      totalQuizQuestions: state.totalQuizQuestions + result.totalQuestions,
      highestScore: math.max(state.highestScore, result.percentage),
      weeklyAnsweredQuestions: List<int>.unmodifiable(updatedWeeklyActivity),
    );

    await _saveSafely();
  }

  Future<String?> updateDisplayName(String value) async {
    await initialize();

    final normalizedName = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.length < 2) {
      return 'Nama mestilah sekurang-kurangnya 2 aksara.';
    }

    if (normalizedName.length > 30) {
      return 'Nama tidak boleh melebihi 30 aksara.';
    }

    state = state.copyWith(displayName: normalizedName);

    await _saveSafely();

    return null;
  }

  Future<void> resetToDefaults() async {
    state = _initialProgress();

    await _saveSafely();
  }

  Future<void> clearLocalProgress() async {
    try {
      await _repository.clearProgress();
    } finally {
      _initializationFuture = null;
      state = _initialProgress();
    }
  }

  Future<void> _saveSafely() async {
    try {
      await _repository.saveProgress(state);
    } catch (_) {
      // Perubahan state kekal untuk sesi semasa walaupun
      // penyimpanan tempatan gagal.
    }
  }

  UserProgress _initialProgress() {
    return UserProgress(
      userId: 'current-user',
      displayName: 'PelajarPA',
      email: 'pelajar@example.com',
      semesterLabel: 'Semester 1',
      joinedAt: DateTime(2026, 1, 10),
      totalXp: 1820,
      weeklyXp: 1820,
      monthlyXp: 6540,
      completedQuizzes: 8,
      totalCorrectAnswers: 122,
      totalQuizQuestions: 160,
      highestScore: 82.0,
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
  }
}
