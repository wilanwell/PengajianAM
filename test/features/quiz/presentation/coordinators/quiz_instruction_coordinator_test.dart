import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_instruction_coordinator.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';

void main() {
  const coordinator = QuizInstructionCoordinator();

  group('QuizInstructionCoordinator', () {
    test('findTopic mengembalikan topik yang sepadan', () {
      final topic = coordinator.findTopic(
        topics: _sampleTopics,
        topicId: 'topic-2',
      );

      expect(topic?.id, 'topic-2');

      expect(topic?.title, 'Sistem Kerajaan');
    });

    test('findTopic mengembalikan null apabila topik tidak wujud', () {
      final topic = coordinator.findTopic(
        topics: _sampleTopics,
        topicId: 'topic-tidak-wujud',
      );

      expect(topic, isNull);
    });

    test('membentuk parameter route kuiz standard', () {
      final parameters = coordinator.buildQuizQuestionQueryParameters(
        topicId: 'topic-1',
        mode: QuizMode.practice,
        source: QuizSessionSource.standard,
        questionCount: 10,
        resumeDraft: false,
      );

      expect(parameters, {
        'topicId': 'topic-1',
        'mode': 'practice',
        'source': 'standard',
        'questionCount': '10',
        'resumeDraft': 'false',
      });
    });

    test('membentuk parameter route resume latihan semula', () {
      final parameters = coordinator.buildQuizQuestionQueryParameters(
        topicId: 'topic-2',
        mode: QuizMode.exam,
        source: QuizSessionSource.mistakeReview,
        questionCount: 20,
        resumeDraft: true,
      );

      expect(parameters, {
        'topicId': 'topic-2',
        'mode': 'exam',
        'source': 'mistake_review',
        'questionCount': '20',
        'resumeDraft': 'true',
      });
    });
  });
}

const List<StudyTopic> _sampleTopics = [
  StudyTopic(
    id: 'topic-1',
    code: 'S1-01',
    semester: 1,
    title: 'Konsep Negara',
    description: 'Pengenalan kepada konsep negara.',
    questionCount: 10,
    completedQuestionCount: 0,
  ),
  StudyTopic(
    id: 'topic-2',
    code: 'S1-02',
    semester: 1,
    title: 'Sistem Kerajaan',
    description: 'Struktur dan sistem kerajaan.',
    questionCount: 20,
    completedQuestionCount: 5,
  ),
];
