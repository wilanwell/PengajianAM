import 'package:flutter/material.dart';

class QuizHubLoadingView extends StatelessWidget {
  const QuizHubLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('quiz-hub-loading-view'),
      child: CircularProgressIndicator(),
    );
  }
}
