import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/entities/study_topic.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/domain/repositories/topics_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_state.dart';

class _FakeTopicsRepository implements TopicsRepository {
  const _FakeTopicsRepository();

  @override
  Future<List<StudyTopic>> fetchTopics() async {
    return const [
      StudyTopic(
        id: 'topic-s1-01',
        code: 'S1-01',
        semester: 1,
        title: 'Kemahiran Insaniah',
        description: 'Kemahiran mencari dan menganalisis maklumat.',
        questionCount: 20,
        completedQuestionCount: 5,
      ),
      StudyTopic(
        id: 'topic-s1-02',
        code: 'S1-02',
        semester: 1,
        title: 'Negara Berdaulat',
        description: 'Konsep dan ciri negara berdaulat.',
        questionCount: 20,
        completedQuestionCount: 20,
      ),
      StudyTopic(
        id: 'topic-s1-03',
        code: 'S1-03',
        semester: 1,
        title: 'Perlembagaan Persekutuan',
        description: 'Keluhuran dan peruntukan Perlembagaan.',
        questionCount: 20,
        completedQuestionCount: 0,
      ),
    ];
  }
}

void main() {
  test('memuatkan dan menapis topik daripada repository', () async {
    final container = ProviderContainer(
      overrides: [
        topicsRepositoryProvider.overrideWithValue(
          const _FakeTopicsRepository(),
        ),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(topicsControllerProvider.notifier);

    await controller.loadTopics();

    var state = container.read(topicsControllerProvider);

    expect(state.status, TopicsStatus.success);

    expect(state.topics, hasLength(3));

    expect(state.totalQuestions, 60);

    expect(state.completedTopics, 1);

    controller.searchChanged('perlembagaan');

    state = container.read(topicsControllerProvider);

    expect(state.visibleTopics, hasLength(1));

    expect(state.visibleTopics.first.title, 'Perlembagaan Persekutuan');

    controller.searchChanged('');

    controller.filterChanged(TopicProgressFilter.completed);

    state = container.read(topicsControllerProvider);

    expect(state.visibleTopics, hasLength(1));

    expect(state.visibleTopics.first.title, 'Negara Berdaulat');
  });
}
