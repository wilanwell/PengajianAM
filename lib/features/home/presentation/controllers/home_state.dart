import '../../domain/entities/home_summary.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.summary,
    this.errorMessage,
  });

  final HomeStatus status;
  final HomeSummary? summary;
  final String? errorMessage;

  bool get isLoading => status == HomeStatus.loading;

  bool get hasData {
    return status == HomeStatus.success && summary != null;
  }

  HomeState copyWith({
    HomeStatus? status,
    HomeSummary? summary,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
