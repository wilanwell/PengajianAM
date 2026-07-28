import '../../domain/entities/mistake_book_topic_detail.dart';

enum MistakeBookTopicStatus { initial, loading, success, failure }

class MistakeBookTopicState {
  const MistakeBookTopicState({
    this.status = MistakeBookTopicStatus.initial,
    this.topicId,
    this.detail,
    this.errorMessage,
  });

  final MistakeBookTopicStatus status;

  final String? topicId;

  final MistakeBookTopicDetail? detail;

  final String? errorMessage;

  bool get isLoading {
    return status == MistakeBookTopicStatus.loading;
  }
}
