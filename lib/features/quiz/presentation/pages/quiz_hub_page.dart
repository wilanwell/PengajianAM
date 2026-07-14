import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_view.dart';

class QuizHubPage extends StatelessWidget {
  const QuizHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kuiz')),
      body: const SafeArea(
        child: FeaturePlaceholderView(
          icon: Icons.quiz_rounded,
          title: 'Pilih Mode Kuiz',
          description: 'Practice Mode dan Exam Mode akan disediakan di sini.',
        ),
      ),
    );
  }
}
