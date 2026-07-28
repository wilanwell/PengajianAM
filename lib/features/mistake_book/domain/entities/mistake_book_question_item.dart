enum MistakeBookQuestionStatus { needsReview, mastered }

class MistakeBookQuestionItem {
  const MistakeBookQuestionItem({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.selectedOptionIndex,
    required this.correctOptionIndex,
    required this.explanation,
    required this.status,
    required this.incorrectCount,
    required this.reviewCount,
    required this.firstIncorrectAt,
    required this.lastIncorrectAt,
    required this.lastReviewedAt,
    required this.masteredAt,
    bool? isReviewable,
  }) : isReviewable =
           isReviewable ?? (status == MistakeBookQuestionStatus.needsReview),
       assert(options.length >= 2),
       assert(selectedOptionIndex >= 0),
       assert(selectedOptionIndex < options.length),
       assert(correctOptionIndex >= 0),
       assert(correctOptionIndex < options.length),
       assert(selectedOptionIndex != correctOptionIndex),
       assert(incorrectCount > 0),
       assert(reviewCount >= 0),
       assert(
         !(isReviewable ?? (status == MistakeBookQuestionStatus.needsReview)) ||
             status == MistakeBookQuestionStatus.needsReview,
       );

  final String questionId;

  final String questionText;

  final List<String> options;

  final int selectedOptionIndex;

  final int correctOptionIndex;

  final String explanation;

  final MistakeBookQuestionStatus status;

  /// Menunjukkan sama ada soalan masih aktif dan boleh
  /// dimasukkan ke dalam sesi latihan semula.
  ///
  /// Soalan yang tidak aktif masih boleh disimpan sebagai
  /// rekod pembelajaran, tetapi tidak boleh dilatih semula.
  final bool isReviewable;

  final int incorrectCount;

  final int reviewCount;

  final DateTime firstIncorrectAt;

  final DateTime lastIncorrectAt;

  final DateTime? lastReviewedAt;

  final DateTime? masteredAt;

  bool get needsReview {
    return status == MistakeBookQuestionStatus.needsReview;
  }

  bool get isMastered {
    return status == MistakeBookQuestionStatus.mastered;
  }

  /// Soalan dianggap diarkibkan apabila masih berstatus
  /// perlu dijawab semula tetapi sudah tidak boleh dilatih.
  bool get isArchived {
    return needsReview && !isReviewable;
  }

  String get selectedAnswerText {
    return options[selectedOptionIndex];
  }

  String get correctAnswerText {
    return options[correctOptionIndex];
  }
}
