import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_question_item.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_detail.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_summary.dart';

void main() {
  group('MistakeBookSnapshot', () {
    test('mewakili Buku Kesilapan yang masih kosong', () {
      final snapshot = MistakeBookSnapshot(
        generatedAt: DateTime.utc(2026, 7, 26, 8),
        needsReviewCount: 0,
        masteredCount: 0,
        topics: const [],
      );

      expect(snapshot.totalTrackedCount, 0);
      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.hasItemsToReview, isFalse);
    });

    test('mengira jumlah item dan status latihan dengan tepat', () {
      final snapshot = MistakeBookSnapshot(
        generatedAt: DateTime.utc(2026, 7, 26, 8),
        needsReviewCount: 3,
        masteredCount: 2,
        topics: const [],
      );

      expect(snapshot.totalTrackedCount, 5);
      expect(snapshot.isEmpty, isFalse);
      expect(snapshot.hasItemsToReview, isTrue);
    });
  });

  group('MistakeBookTopicSummary', () {
    test('mengira jumlah dan mastery progress topik dengan tepat', () {
      final topic = MistakeBookTopicSummary(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Kemahiran Insaniah',
        semester: 1,
        sortOrder: 1,
        needsReviewCount: 1,
        masteredCount: 3,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 7),
      );

      expect(topic.totalTrackedCount, 4);
      expect(topic.hasItemsToReview, isTrue);
      expect(topic.masteryProgress, 0.75);
    });
  });

  group('MistakeBookQuestionItem', () {
    test('mendedahkan jawapan dan status semakan dengan tepat', () {
      final item = _sampleQuestionItem();

      expect(item.needsReview, isTrue);
      expect(item.isMastered, isFalse);
      expect(item.selectedAnswerText, 'Pilihan A');
      expect(item.correctAnswerText, 'Pilihan B');
    });
  });

  group('MistakeBookTopicDetail', () {
    test('mengira jumlah dan penguasaan detail topik', () {
      final detail = MistakeBookTopicDetail(
        generatedAt: DateTime.utc(2026, 7, 27, 8),
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Kemahiran Insaniah',
        semester: 1,
        sortOrder: 1,
        needsReviewCount: 1,
        masteredCount: 0,
        items: [_sampleQuestionItem()],
      );

      expect(detail.totalTrackedCount, 1);
      expect(detail.isEmpty, isFalse);
      expect(detail.masteryProgress, 0);
    });
  });
}

MistakeBookQuestionItem _sampleQuestionItem() {
  return MistakeBookQuestionItem(
    questionId: 'question-1',
    questionText: 'Apakah jawapan yang betul?',
    options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
    selectedOptionIndex: 0,
    correctOptionIndex: 1,
    explanation: 'Pilihan B ialah jawapan yang betul.',
    status: MistakeBookQuestionStatus.needsReview,
    incorrectCount: 2,
    reviewCount: 0,
    firstIncorrectAt: DateTime.utc(2026, 7, 26, 8),
    lastIncorrectAt: DateTime.utc(2026, 7, 27, 8),
    lastReviewedAt: null,
    masteredAt: null,
  );
}
