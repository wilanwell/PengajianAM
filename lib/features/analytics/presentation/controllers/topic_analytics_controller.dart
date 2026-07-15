import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../quiz/domain/entities/quiz_attempt.dart';
import '../../../quiz/presentation/controllers/quiz_history_controller.dart';
import '../../../quiz/presentation/controllers/quiz_history_state.dart';
import '../../domain/entities/topic_performance.dart';
import 'topic_analytics_state.dart';

final topicAnalyticsControllerProvider =
    NotifierProvider<TopicAnalyticsController, TopicAnalyticsState>(
      TopicAnalyticsController.new,
    );

class TopicAnalyticsController extends Notifier<TopicAnalyticsState> {
  @override
  TopicAnalyticsState build() {
    return const TopicAnalyticsState();
  }

  Future<void> loadAnalytics({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == TopicAnalyticsStatus.loading ||
            state.status == TopicAnalyticsStatus.success)) {
      return;
    }

    state = state.copyWith(
      status: TopicAnalyticsStatus.loading,
      clearErrorMessage: true,
    );

    try {
      await ref
          .read(quizHistoryControllerProvider.notifier)
          .loadHistory(forceRefresh: forceRefresh);

      final historyState = ref.read(quizHistoryControllerProvider);

      if (historyState.status == QuizHistoryStatus.failure) {
        throw StateError(
          historyState.errorMessage ?? 'Sejarah kuiz tidak dapat dimuatkan.',
        );
      }

      final performances = _buildPerformances(historyState.attempts);

      state = TopicAnalyticsState(
        status: TopicAnalyticsStatus.success,
        performances: performances,
      );
    } catch (_) {
      state = const TopicAnalyticsState(
        status: TopicAnalyticsStatus.failure,
        errorMessage: 'Analitik prestasi tidak dapat dimuatkan.',
      );
    }
  }

  Future<void> refreshAnalytics() {
    return loadAnalytics(forceRefresh: true);
  }

  void reset() {
    state = const TopicAnalyticsState();
  }

  List<TopicPerformance> _buildPerformances(List<QuizAttempt> attempts) {
    final accumulators = <String, _TopicPerformanceAccumulator>{};

    for (final attempt in attempts) {
      final result = attempt.result;

      final groupKey = result.topicId.isEmpty
          ? result.topicTitle
          : result.topicId;

      final accumulator = accumulators.putIfAbsent(
        groupKey,
        () => _TopicPerformanceAccumulator(
          topicId: result.topicId,
          topicCode: result.topicCode,
          topicTitle: result.topicTitle,
        ),
      );

      accumulator.addAttempt(attempt);
    }

    final performances = [
      for (final accumulator in accumulators.values)
        accumulator.toPerformance(),
    ];

    performances.sort((first, second) {
      final scoreComparison = second.averageScore.compareTo(first.averageScore);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final attemptComparison = second.attemptCount.compareTo(
        first.attemptCount,
      );

      if (attemptComparison != 0) {
        return attemptComparison;
      }

      return first.topicTitle.compareTo(second.topicTitle);
    });

    return List<TopicPerformance>.unmodifiable(performances);
  }
}

class _TopicPerformanceAccumulator {
  _TopicPerformanceAccumulator({
    required this.topicId,
    required this.topicCode,
    required this.topicTitle,
  });

  String topicId;
  String topicCode;
  String topicTitle;

  int attemptCount = 0;
  int totalQuestions = 0;
  int totalCorrectAnswers = 0;
  double bestScore = 0;
  int totalEarnedXp = 0;

  void addAttempt(QuizAttempt attempt) {
    final result = attempt.result;

    if (topicId.isEmpty && result.topicId.isNotEmpty) {
      topicId = result.topicId;
    }

    if (topicCode.isEmpty && result.topicCode.isNotEmpty) {
      topicCode = result.topicCode;
    }

    if (topicTitle.trim().isEmpty) {
      topicTitle = result.topicTitle;
    }

    attemptCount++;
    totalQuestions += result.totalQuestions;
    totalCorrectAnswers += result.correctAnswers;
    totalEarnedXp += attempt.earnedXp;

    bestScore = math.max(bestScore, result.percentage).toDouble();
  }

  TopicPerformance toPerformance() {
    return TopicPerformance(
      topicId: topicId,
      topicCode: topicCode,
      topicTitle: topicTitle.trim().isEmpty ? 'Topik Pengajian AM' : topicTitle,
      attemptCount: attemptCount,
      totalQuestions: totalQuestions,
      totalCorrectAnswers: totalCorrectAnswers,
      bestScore: bestScore,
      totalEarnedXp: totalEarnedXp,
    );
  }
}
