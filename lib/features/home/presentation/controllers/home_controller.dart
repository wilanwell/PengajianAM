import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/domain/services/mock_rank_calculator.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
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
      await Future<void>.delayed(const Duration(milliseconds: 350));

      await ref
          .read(userProgressControllerProvider.notifier)
          .initialize(forceRefresh: forceRefresh);

      final progress = ref.read(userProgressControllerProvider);

      final summary = HomeSummary(
        displayName: progress.displayName,
        semesterLabel: progress.semesterLabel,
        completedQuizzes: progress.completedQuizzes,
        averageScore: progress.averageScore,
        totalXp: progress.totalXp,
        weeklyRank: MockRankCalculator.weeklyRank(progress.weeklyXp),
        currentTopic: 'Negara Berdaulat',
        currentTopicProgress: 0.65,
        completedTopics: progress.completedTopics,
        totalTopics: progress.totalTopics,
      );

      state = HomeState(status: HomeStatus.success, summary: summary);
    } catch (_) {
      state = const HomeState(
        status: HomeStatus.failure,
        errorMessage: 'Dashboard tidak dapat dimuatkan. Sila cuba semula.',
      );
    }
  }

  Future<void> refreshDashboard() {
    return loadDashboard(forceRefresh: true);
  }

  void reset() {
    state = const HomeState();
  }
}
