class MistakeBookTopicSummary {
  const MistakeBookTopicSummary({
    required this.topicId,
    required this.topicCode,
    required this.topicTitle,
    required this.semester,
    required this.sortOrder,
    required this.needsReviewCount,
    required this.masteredCount,
    required this.lastMistakeAt,
  }) : assert(semester >= 1 && semester <= 3),
       assert(sortOrder >= 0),
       assert(needsReviewCount >= 0),
       assert(masteredCount >= 0),
       assert(needsReviewCount + masteredCount > 0);

  final String topicId;
  final String topicCode;
  final String topicTitle;
  final int semester;
  final int sortOrder;
  final int needsReviewCount;
  final int masteredCount;
  final DateTime lastMistakeAt;

  int get totalTrackedCount {
    return needsReviewCount + masteredCount;
  }

  bool get hasItemsToReview {
    return needsReviewCount > 0;
  }

  double get masteryProgress {
    if (totalTrackedCount == 0) {
      return 0;
    }

    return masteredCount / totalTrackedCount;
  }
}
