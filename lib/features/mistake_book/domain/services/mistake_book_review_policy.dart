class MistakeBookReviewPolicy {
  const MistakeBookReviewPolicy._();

  /// Jumlah maksimum soalan yang boleh dimasukkan
  /// dalam satu sesi latihan semula.
  ///
  /// Sesi yang lebih pendek mengurangkan beban pengguna
  /// dan mengelakkan permintaan yang terlalu besar kepada backend.
  static const int maxQuestionsPerSession = 20;

  /// Menentukan jumlah soalan sebenar untuk sesi latihan semula.
  ///
  /// - Nilai kosong atau negatif menghasilkan 0.
  /// - Nilai 1 hingga 20 dikekalkan.
  /// - Nilai melebihi 20 dihadkan kepada 20.
  static int resolveQuestionCount(int reviewableCount) {
    if (reviewableCount <= 0) {
      return 0;
    }

    if (reviewableCount > maxQuestionsPerSession) {
      return maxQuestionsPerSession;
    }

    return reviewableCount;
  }
}
