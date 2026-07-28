import '../entities/mistake_book_snapshot.dart';
import '../entities/mistake_book_topic_detail.dart';

abstract interface class MistakeBookRepository {
  Future<MistakeBookSnapshot> fetchMistakeBook();

  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId);
}
