import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../../quiz/domain/entities/quiz_result.dart';
import '../../data/repositories/supabase_user_progress_repository.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  return SupabaseUserProgressRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
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
    return _emptyProgress();
  }

  Future<void> initialize({bool forceRefresh = false}) {
    if (forceRefresh) {
      _initializationFuture = null;
    }

    return _initializationFuture ??= _initializeInternal();
  }

  Future<void> refresh() {
    return initialize(forceRefresh: true);
  }

  Future<void> _initializeInternal() async {
    try {
      final progress = await _repository.loadProgress();

      if (progress == null) {
        throw StateError('Progress pengguna tidak tersedia.');
      }

      state = progress;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
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

  Future<void> recordQuizResult(QuizResult result) async {
    await initialize();

    final earnedXp = calculateEarnedXp(result);

    _applyQuizResultLocally(result: result, earnedXp: earnedXp);

    await _saveSafely();
  }

  Future<void> recordServerQuizResult({
    required QuizResult result,
    required int earnedXp,
  }) async {
    await initialize(forceRefresh: true);
  }

  void _applyQuizResultLocally({
    required QuizResult result,
    required int earnedXp,
  }) {
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
  }

  Future<String?> updateDisplayName(String value) async {
    await initialize();

    final normalizedName = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.length < 2) {
      return 'Nama mestilah sekurang-kurangnya '
          '2 aksara.';
    }

    if (normalizedName.length > 30) {
      return 'Nama tidak boleh melebihi '
          '30 aksara.';
    }

    final previousState = state;

    state = state.copyWith(displayName: normalizedName);

    try {
      await _repository.saveProgress(state);

      return null;
    } catch (error) {
      state = previousState;

      final message = error.toString().trim();

      if (message.isNotEmpty) {
        return message;
      }

      return 'Nama paparan tidak dapat '
          'dikemas kini.';
    }
  }

  Future<void> resetToDefaults() {
    return clearLocalProgress();
  }

  Future<void> clearLocalProgress() async {
    await _repository.clearProgress();

    _initializationFuture = null;

    await initialize(forceRefresh: true);
  }

  void resetState() {
    _initializationFuture = null;
    state = _emptyProgress();
  }

  void reset() {
    resetState();
  }

  Future<void> _saveSafely() async {
    try {
      await _repository.saveProgress(state);
    } catch (_) {
      // State kekal untuk sesi semasa.
    }
  }

  UserProgress _emptyProgress() {
    return UserProgress(
      userId: '',
      displayName: 'Pelajar',
      email: '',
      semesterLabel: 'Semester 1',
      joinedAt: DateTime(2026, 1, 1),
      totalXp: 0,
      weeklyXp: 0,
      monthlyXp: 0,
      completedQuizzes: 0,
      totalCorrectAnswers: 0,
      totalQuizQuestions: 0,
      highestScore: 0,
      completedTopics: 0,
      totalTopics: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
      weeklyAnsweredQuestions: List<int>.unmodifiable([0, 0, 0, 0, 0, 0, 0]),
    );
  }
}
