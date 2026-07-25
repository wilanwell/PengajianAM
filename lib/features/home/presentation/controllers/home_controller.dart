import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leaderboard/domain/entities/leaderboard_period.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_state.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../../topics/presentation/controllers/topics_state.dart';
import '../../domain/entities/home_summary.dart';
import 'home_state.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    return const HomeState();
  }

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == HomeStatus.loading ||
            state.status == HomeStatus.success)) {
      return;
    }

    state = state.copyWith(status: HomeStatus.loading, clearErrorMessage: true);

    try {
      /*
       * Mulakan semua operasi secara serentak.
       */
      final progressFuture = ref
          .read(userProgressControllerProvider.notifier)
          .initialize(forceRefresh: forceRefresh);

      final topicsFuture = ref
          .read(topicsControllerProvider.notifier)
          .loadTopics(forceRefresh: forceRefresh);

      /*
       * Ambil keputusan request leaderboard
       * ini secara langsung.
       *
       * Jangan membaca shared provider state
       * selepas await kerana request lain boleh
       * menukarnya kepada loading atau tempoh
       * yang berbeza.
       */
      final leaderboardFuture = ref
          .read(leaderboardControllerProvider.notifier)
          .loadLeaderboardState(
            period: LeaderboardPeriod.weekly,
            forceRefresh: forceRefresh,
          );

      await Future.wait<void>([progressFuture, topicsFuture]);

      final leaderboardState = await leaderboardFuture;

      final progress = ref.read(userProgressControllerProvider);

      final topicsState = ref.read(topicsControllerProvider);

      if (topicsState.status != TopicsStatus.success) {
        state = HomeState(
          status: HomeStatus.failure,
          errorMessage:
              topicsState.errorMessage ??
              'Progress topik tidak dapat '
                  'dimuatkan.',
        );

        return;
      }

      if (leaderboardState.status != LeaderboardStatus.success) {
        state = HomeState(
          status: HomeStatus.failure,
          errorMessage:
              leaderboardState.errorMessage ??
              'Ranking mingguan tidak dapat '
                  'dimuatkan.',
        );

        return;
      }

      if (leaderboardState.period != LeaderboardPeriod.weekly) {
        state = const HomeState(
          status: HomeStatus.failure,
          errorMessage:
              'Tempoh ranking mingguan '
              'tidak sepadan.',
        );

        return;
      }

      final currentUserEntry = leaderboardState.currentUserEntry;

      /*
 * Pengguna opt-in wajib mempunyai
 * current-user ranking.
 *
 * Pengguna opt-out memang tidak akan
 * mempunyai current-user entry.
 */
      if (leaderboardState.isParticipating && currentUserEntry == null) {
        state = const HomeState(
          status: HomeStatus.failure,
          errorMessage:
              'Kedudukan mingguan pengguna '
              'tidak dapat dikenal pasti.',
        );

        return;
      }

      if (!leaderboardState.isParticipating && currentUserEntry != null) {
        state = const HomeState(
          status: HomeStatus.failure,
          errorMessage:
              'Status penyertaan leaderboard '
              'tidak sepadan.',
        );

        return;
      }

      final topics = topicsState.topics;

      if (topics.isEmpty) {
        state = const HomeState(
          status: HomeStatus.failure,
          errorMessage:
              'Topik pembelajaran belum '
              'tersedia.',
        );

        return;
      }

      final currentTopic = _resolveCurrentTopic(topics);

      final completedTopics = topics.where((topic) {
        return topic.isCompleted;
      }).length;

      final summary = HomeSummary(
        displayName: progress.displayName,
        semesterLabel: progress.semesterLabel,
        completedQuizzes: progress.completedQuizzes,
        averageScore: progress.averageScore,
        totalXp: progress.totalXp,
        weeklyRank: currentUserEntry?.rank,
        currentTopic: currentTopic.title,
        currentTopicProgress: currentTopic.progress,
        completedTopics: completedTopics,
        totalTopics: topics.length,
      );

      state = HomeState(status: HomeStatus.success, summary: summary);
    } catch (_) {
      state = const HomeState(
        status: HomeStatus.failure,
        errorMessage:
            'Dashboard tidak dapat dimuatkan. '
            'Sila cuba semula.',
      );
    }
  }

  StudyTopic _resolveCurrentTopic(List<StudyTopic> topics) {
    final attemptedIncompleteTopics = topics.where((topic) {
      return !topic.isCompleted && topic.lastAttemptAt != null;
    }).toList();

    attemptedIncompleteTopics.sort((first, second) {
      return second.lastAttemptAt!.compareTo(first.lastAttemptAt!);
    });

    if (attemptedIncompleteTopics.isNotEmpty) {
      return attemptedIncompleteTopics.first;
    }

    for (final topic in topics) {
      if (!topic.isCompleted) {
        return topic;
      }
    }

    final attemptedTopics = topics.where((topic) {
      return topic.lastAttemptAt != null;
    }).toList();

    attemptedTopics.sort((first, second) {
      return second.lastAttemptAt!.compareTo(first.lastAttemptAt!);
    });

    if (attemptedTopics.isNotEmpty) {
      return attemptedTopics.first;
    }

    return topics.first;
  }

  Future<void> refreshDashboard() {
    return loadDashboard(forceRefresh: true);
  }

  void reset() {
    state = const HomeState();
  }
}
