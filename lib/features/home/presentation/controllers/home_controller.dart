import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // Temporary delay to simulate loading data from a remote source.
      // This will later be replaced by HomeRepository and Supabase.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      const summary = HomeSummary(
        displayName: 'Pelajar',
        semesterLabel: 'Semester 1',
        completedQuizzes: 8,
        averageScore: 76,
        totalXp: 1420,
        weeklyRank: 7,
        currentTopic: 'Negara Berdaulat',
        currentTopicProgress: 0.65,
        completedTopics: 3,
        totalTopics: 8,
      );

      state = const HomeState(status: HomeStatus.success, summary: summary);
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
