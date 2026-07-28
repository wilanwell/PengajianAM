import 'mistake_book_question_item.dart';

class MistakeBookTopicDetail {
  const MistakeBookTopicDetail({
    required this.generatedAt,
    required this.topicId,
    required this.topicCode,
    required this.topicTitle,
    required this.semester,
    required this.sortOrder,
    required this.needsReviewCount,
    required this.masteredCount,
    required this.items,
    int? reviewableCount,
  }) : reviewableCount = reviewableCount ?? needsReviewCount,
       assert(semester >= 1 && semester <= 3),
       assert(sortOrder >= 0),
       assert(needsReviewCount >= 0),
       assert(masteredCount >= 0),
       assert((reviewableCount ?? needsReviewCount) >= 0),
       assert((reviewableCount ?? needsReviewCount) <= needsReviewCount),
       assert(items.length == needsReviewCount + masteredCount);

  final DateTime generatedAt;

  final String topicId;

  final String topicCode;

  final String topicTitle;

  final int semester;

  final int sortOrder;

  /// Jumlah semua soalan berstatus perlu dijawab semula,
  /// termasuk soalan yang telah diarkibkan.
  final int needsReviewCount;

  /// Jumlah soalan aktif yang boleh dilatih semula.
  final int reviewableCount;

  final int masteredCount;

  final List<MistakeBookQuestionItem> items;

  int get totalTrackedCount {
    return needsReviewCount + masteredCount;
  }

  int get archivedNeedsReviewCount {
    return needsReviewCount - reviewableCount;
  }

  bool get isEmpty {
    return items.isEmpty;
  }

  bool get hasReviewableItems {
    return reviewableCount > 0;
  }

  double get masteryProgress {
    if (totalTrackedCount == 0) {
      return 0;
    }

    return masteredCount / totalTrackedCount;
  }
}
