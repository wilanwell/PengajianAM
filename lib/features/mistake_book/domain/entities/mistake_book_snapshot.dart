import 'mistake_book_topic_summary.dart';

class MistakeBookSnapshot {
  const MistakeBookSnapshot({
    required this.generatedAt,
    required this.needsReviewCount,
    required this.masteredCount,
    required this.topics,
    int? reviewableCount,
  }) : reviewableCount = reviewableCount ?? needsReviewCount,
       assert(needsReviewCount >= 0),
       assert(masteredCount >= 0),
       assert((reviewableCount ?? needsReviewCount) >= 0),
       assert((reviewableCount ?? needsReviewCount) <= needsReviewCount);

  final DateTime generatedAt;

  /// Jumlah semua soalan yang masih memerlukan semakan,
  /// termasuk soalan yang telah diarkibkan.
  final int needsReviewCount;

  /// Jumlah soalan yang masih aktif dan boleh dilatih.
  final int reviewableCount;

  final int masteredCount;

  final List<MistakeBookTopicSummary> topics;

  int get totalTrackedCount {
    return needsReviewCount + masteredCount;
  }

  int get archivedNeedsReviewCount {
    return needsReviewCount - reviewableCount;
  }

  bool get isEmpty {
    return totalTrackedCount == 0;
  }

  bool get hasItemsToReview {
    return reviewableCount > 0;
  }
}
