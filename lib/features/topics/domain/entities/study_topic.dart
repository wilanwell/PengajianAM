/// Represents one learning topic in the Pengajian AM syllabus.
///
/// This domain entity does not import Flutter UI classes such as
/// Color or IconData. This keeps the domain layer independent
/// from the presentation layer.
class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.code,
    required this.semester,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.completedQuestionCount,
  }) : assert(semester > 0),
       assert(questionCount >= 0),
       assert(completedQuestionCount >= 0),
       assert(completedQuestionCount <= questionCount);

  final String id;
  final String code;
  final int semester;
  final String title;
  final String description;
  final int questionCount;
  final int completedQuestionCount;

  double get progress {
    if (questionCount == 0) {
      return 0;
    }

    return completedQuestionCount / questionCount;
  }

  int get progressPercentage {
    return (progress * 100).round();
  }

  bool get isNotStarted {
    return completedQuestionCount == 0;
  }

  bool get isInProgress {
    return completedQuestionCount > 0 && completedQuestionCount < questionCount;
  }

  bool get isCompleted {
    return questionCount > 0 && completedQuestionCount == questionCount;
  }
}
