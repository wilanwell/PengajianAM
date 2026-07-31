import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_instruction_topic_not_found_view.dart';

void main() {
  testWidgets('memaparkan mesej apabila topik kuiz tidak ditemui', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuizInstructionTopicNotFoundView()),
    );

    expect(
      find.byKey(const Key('quiz-instruction-topic-not-found-view')),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('quiz-instruction-topic-not-found-message')),
      findsOneWidget,
    );

    expect(find.text('Topik yang dipilih tidak ditemui.'), findsOneWidget);

    expect(find.text('Arahan Kuiz'), findsOneWidget);
  });
}
