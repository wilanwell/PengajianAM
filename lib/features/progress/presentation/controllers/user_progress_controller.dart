import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../quiz/domain/entities/quiz_result.dart';
import '../../domain/entities/user_progress.dart';

final userProgressControllerProvider =
    NotifierProvider<UserProgressController, UserProgress>(
      UserProgressController.new,
    );

class UserProgressController extends Notifier<UserProgress> {
  @override
  UserProgress build() {
    return _initialProgress();
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

  void recordQuizResult(QuizResult result) {
    final earnedXp = calculateEarnedXp(result);

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
      totalXp: state.totalXp + earnedXp,
      weeklyXp: state.weeklyXp + earnedXp,
      monthlyXp: state.monthlyXp + earnedXp,
      completedQuizzes: state.completedQuizzes + 1,
      totalCorrectAnswers: state.totalCorrectAnswers + result.correctAnswers,
      totalQuizQuestions: state.totalQuizQuestions + result.totalQuestions,
      highestScore: math.max(state.highestScore, result.percentage),
      weeklyAnsweredQuestions: List<int>.unmodifiable(updatedWeeklyActivity),
    );
  }

  String? updateDisplayName(String value) {
    final normalizedName = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.length < 2) {
      return 'Nama mestilah sekurang-kurangnya 2 aksara.';
    }

    if (normalizedName.length > 30) {
      return 'Nama tidak boleh melebihi 30 aksara.';
    }

    state = state.copyWith(displayName: normalizedName);

    return null;
  }

  void reset() {
    state = _initialProgress();
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
