import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_state.dart';

void main() {
  test('memuatkan dan menapis topik', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(topicsControllerProvider.notifier);

    await controller.loadTopics();

    var state = container.read(topicsControllerProvider);

    expect(state.status, TopicsStatus.success);

    expect(state.topics, hasLength(7));

    expect(state.totalQuestions, 150);

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
