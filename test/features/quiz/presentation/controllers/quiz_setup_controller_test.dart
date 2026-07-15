import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_setup_controller.dart';

void main() {
  test('mengemas kini tetapan kuiz', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(quizSetupControllerProvider.notifier);

    controller.selectTopic('topic-s1-02');

    controller.selectMode(QuizMode.exam);

    controller.selectQuestionCount(20);

    final state = container.read(quizSetupControllerProvider);

    expect(state.selectedTopicId, 'topic-s1-02');

    expect(state.mode, QuizMode.exam);

    expect(state.questionCount, 20);

    expect(state.durationMinutes, 30);

    expect(state.canContinue, isTrue);
  });

  test('menggunakan tetapan kuiz lalai', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(quizSetupControllerProvider.notifier);

    controller.applyDefaults(mode: QuizMode.exam, questionCount: 20);

    final state = container.read(quizSetupControllerProvider);

    expect(state.mode, QuizMode.exam);

    expect(state.questionCount, 20);

    expect(state.selectedTopicId, isNull);
  });
}
