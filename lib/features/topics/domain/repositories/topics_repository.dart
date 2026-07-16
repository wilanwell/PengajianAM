import '../entities/study_topic.dart';

abstract interface class TopicsRepository {
  Future<List<StudyTopic>> fetchTopics();
}
