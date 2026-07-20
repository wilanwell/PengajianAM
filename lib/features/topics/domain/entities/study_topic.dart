/// Represents one learning topic in the
/// Pengajian AM syllabus.
///
/// Entity ini tidak mengimport class UI Flutter
/// supaya domain layer kekal bebas daripada
/// presentation layer.
class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.code,
    required this.semester,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.completedQuestionCount,
    this.lastAttemptAt,
  }) : assert(semester > 0, 'Semester mestilah lebih besar daripada sifar.'),
       assert(questionCount >= 0, 'Jumlah soalan tidak boleh negatif.'),
       assert(
         completedQuestionCount >= 0,
         'Jumlah soalan selesai tidak boleh negatif.',
       ),
       assert(
         completedQuestionCount <= questionCount,
         'Jumlah soalan selesai tidak boleh '
         'melebihi jumlah soalan topik.',
       );

  final String id;
  final String code;
  final int semester;
  final String title;
  final String description;

  final int questionCount;
  final int completedQuestionCount;

  /// Masa percubaan kuiz terakhir pengguna
  /// untuk topik ini.
  ///
  /// Null bermaksud pengguna belum pernah
  /// menghantar kuiz bagi topik tersebut.
  final DateTime? lastAttemptAt;

  double get progress {
    if (questionCount == 0) {
      return 0;
    }

    return completedQuestionCount / questionCount;
  }

  int get progressPercentage {
    return (progress * 100).round();
  }

  int get remainingQuestionCount {
    final remaining = questionCount - completedQuestionCount;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  bool get hasAttempt {
    return lastAttemptAt != null;
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
