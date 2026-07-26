import 'mistake_book_topic_summary.dart';

class MistakeBookSnapshot {
  const MistakeBookSnapshot({
    required this.generatedAt,
    required this.needsReviewCount,
    required this.masteredCount,
    required this.topics,
  }) : assert(needsReviewCount >= 0),
       assert(masteredCount >= 0);

  final DateTime generatedAt;
  final int needsReviewCount;
  final int masteredCount;
  final List<MistakeBookTopicSummary> topics;

  int get totalTrackedCount {
    return needsReviewCount + masteredCount;
  }

  bool get isEmpty {
    return totalTrackedCount == 0;
  }

  bool get hasItemsToReview {
    return needsReviewCount > 0;
  }
}
