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
       * Muatkan semua sumber data sebenar
       * secara serentak:
       *
       * 1. Profile dan overall progress
       * 2. Progress setiap topik
       * 3. Weekly leaderboard
       */
      await Future.wait<void>([
        ref
            .read(userProgressControllerProvider.notifier)
            .initialize(forceRefresh: forceRefresh),
        ref
            .read(topicsControllerProvider.notifier)
            .loadTopics(forceRefresh: forceRefresh),
        ref
            .read(leaderboardControllerProvider.notifier)
            .loadLeaderboard(
              period: LeaderboardPeriod.weekly,
              forceRefresh: forceRefresh,
            ),
      ]);

      final progress = ref.read(userProgressControllerProvider);

      final topicsState = ref.read(topicsControllerProvider);

      final leaderboardState = ref.read(leaderboardControllerProvider);

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

      final currentUserEntry = leaderboardState.currentUserEntry;

      if (currentUserEntry == null) {
        state = const HomeState(
          status: HomeStatus.failure,
          errorMessage:
              'Kedudukan mingguan pengguna '
              'tidak dapat dikenal pasti.',
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

      final completedTopics = topics.where((topic) => topic.isCompleted).length;

      final summary = HomeSummary(
        displayName: progress.displayName,
        semesterLabel: progress.semesterLabel,
        completedQuizzes: progress.completedQuizzes,
        averageScore: progress.averageScore,
        totalXp: progress.totalXp,

        /*
         * Ranking sebenar pengguna daripada
         * RPC get_leaderboard untuk tempoh weekly.
         */
        weeklyRank: currentUserEntry.rank,

        /*
         * Current topic sebenar berdasarkan
         * progress dan attempt terbaru.
         */
        currentTopic: currentTopic.title,
        currentTopicProgress: currentTopic.progress,

        /*
         * Jumlah topik selesai dikira daripada
         * distinct questions answered bagi
         * setiap topik.
         */
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
    /*
     * Keutamaan 1:
     *
     * Topik belum selesai yang mempunyai
     * attempt paling baharu.
     */
    final attemptedIncompleteTopics = topics
        .where((topic) => !topic.isCompleted && topic.lastAttemptAt != null)
        .toList();

    attemptedIncompleteTopics.sort((first, second) {
      return second.lastAttemptAt!.compareTo(first.lastAttemptAt!);
    });

    if (attemptedIncompleteTopics.isNotEmpty) {
      return attemptedIncompleteTopics.first;
    }

    /*
     * Keutamaan 2:
     *
     * Jika pengguna belum mempunyai attempt
     * aktif, pilih topik pertama yang belum
     * diselesaikan.
     */
    for (final topic in topics) {
      if (!topic.isCompleted) {
        return topic;
      }
    }

    /*
     * Keutamaan 3:
     *
     * Jika semua topik telah selesai,
     * paparkan topik yang mempunyai attempt
     * paling baharu.
     */
    final attemptedTopics = topics
        .where((topic) => topic.lastAttemptAt != null)
        .toList();

    attemptedTopics.sort((first, second) {
      return second.lastAttemptAt!.compareTo(first.lastAttemptAt!);
    });

    if (attemptedTopics.isNotEmpty) {
      return attemptedTopics.first;
    }

    /*
     * Fallback untuk pengguna baharu yang
     * belum mempunyai sebarang attempt.
     */
    return topics.first;
  }

  Future<void> refreshDashboard() {
    return loadDashboard(forceRefresh: true);
  }

  void reset() {
    state = const HomeState();
  }
}
