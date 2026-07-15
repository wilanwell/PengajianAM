import '../../domain/entities/study_topic.dart';

enum TopicsStatus { initial, loading, success, failure }

enum TopicProgressFilter { all, notStarted, inProgress, completed }

class TopicsState {
  const TopicsState({
    this.status = TopicsStatus.initial,
    this.topics = const [],
    this.searchQuery = '',
    this.filter = TopicProgressFilter.all,
    this.errorMessage,
  });

  final TopicsStatus status;
  final List<StudyTopic> topics;
  final String searchQuery;
  final TopicProgressFilter filter;
  final String? errorMessage;

  bool get isLoading {
    return status == TopicsStatus.loading;
  }

  int get totalQuestions {
    return topics.fold<int>(0, (total, topic) => total + topic.questionCount);
  }

  int get completedTopics {
    return topics.where((topic) => topic.isCompleted).length;
  }

  List<StudyTopic> get visibleTopics {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return topics
        .where((topic) {
          final matchesSearch =
              normalizedQuery.isEmpty ||
              topic.title.toLowerCase().contains(normalizedQuery) ||
              topic.description.toLowerCase().contains(normalizedQuery) ||
              topic.code.toLowerCase().contains(normalizedQuery);

          final matchesFilter = switch (filter) {
            TopicProgressFilter.all => true,
            TopicProgressFilter.notStarted => topic.isNotStarted,
            TopicProgressFilter.inProgress => topic.isInProgress,
            TopicProgressFilter.completed => topic.isCompleted,
          };

          return matchesSearch && matchesFilter;
        })
        .toList(growable: false);
  }

  TopicsState copyWith({
    TopicsStatus? status,
    List<StudyTopic>? topics,
    String? searchQuery,
    TopicProgressFilter? filter,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TopicsState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
