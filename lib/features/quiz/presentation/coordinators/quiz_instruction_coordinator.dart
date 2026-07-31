import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../topics/domain/entities/study_topic.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session_source.dart';

final quizInstructionCoordinatorProvider = Provider<QuizInstructionCoordinator>(
  (ref) {
    return const QuizInstructionCoordinator();
  },
);

class QuizInstructionCoordinator {
  const QuizInstructionCoordinator();

  StudyTopic? findTopic({
    required List<StudyTopic> topics,
    required String topicId,
  }) {
    for (final topic in topics) {
      if (topic.id == topicId) {
        return topic;
      }
    }

    return null;
  }

  Map<String, String> buildQuizQuestionQueryParameters({
    required String topicId,
    required QuizMode mode,
    required QuizSessionSource source,
    required int questionCount,
    required bool resumeDraft,
  }) {
    return {
      'topicId': topicId,
      'mode': mode.routeValue,
      'source': source.serverValue,
      'questionCount': questionCount.toString(),
      'resumeDraft': resumeDraft.toString(),
    };
  }
}
