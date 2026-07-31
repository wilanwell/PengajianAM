import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

class QuizInstructionTopicNotFoundView extends StatelessWidget {
  const QuizInstructionTopicNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('quiz-instruction-topic-not-found-view'),
      appBar: AppBar(title: const Text('Arahan Kuiz')),
      body: const Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Text(
            'Topik yang dipilih tidak ditemui.',
            key: Key('quiz-instruction-topic-not-found-message'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
