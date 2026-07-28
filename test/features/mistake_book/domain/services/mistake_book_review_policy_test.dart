import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/services/mistake_book_review_policy.dart';

void main() {
  group('MistakeBookReviewPolicy', () {
    test('mengembalikan sifar apabila tiada soalan untuk dilatih', () {
      expect(MistakeBookReviewPolicy.resolveQuestionCount(0), 0);
    });

    test('mengembalikan sifar bagi jumlah negatif', () {
      expect(MistakeBookReviewPolicy.resolveQuestionCount(-1), 0);
    });

    test('mengekalkan jumlah yang lebih kecil daripada had sesi', () {
      expect(MistakeBookReviewPolicy.resolveQuestionCount(15), 15);
    });

    test('mengekalkan jumlah yang sama dengan had sesi', () {
      expect(
        MistakeBookReviewPolicy.resolveQuestionCount(
          MistakeBookReviewPolicy.maxQuestionsPerSession,
        ),
        20,
      );
    });

    test('mengehadkan jumlah yang melebihi had kepada 20', () {
      expect(MistakeBookReviewPolicy.resolveQuestionCount(50), 20);

      expect(MistakeBookReviewPolicy.resolveQuestionCount(120), 20);
    });
  });
}
