import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../domain/entities/quiz_result.dart';
import '../controllers/quiz_session_controller.dart';
import '../widgets/quiz_result_content.dart';

class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({required this.result, super.key});

  final QuizResult result;

  void _retryQuiz(BuildContext context, WidgetRef ref) {
    ref.read(quizSessionControllerProvider.notifier).reset();

    context.goNamed(
      RouteNames.quiz,
      queryParameters: {'topicId': result.topicId},
    );
  }

  void _openAnswerReview(BuildContext context) {
    context.pushNamed(RouteNames.quizReview, extra: result);
  }

  void _returnToMistakeBookTopic(BuildContext context, WidgetRef ref) {
    ref.read(quizSessionControllerProvider.notifier).reset();

    context.goNamed(
      RouteNames.mistakeBookTopic,
      pathParameters: {'topicId': result.topicId},
    );
  }

  void _returnToTopics(BuildContext context) {
    context.goNamed(RouteNames.topics);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuizResultContent(
      result: result,
      onReviewAnswers: () {
        _openAnswerReview(context);
      },
      onRetryQuiz: () {
        _retryQuiz(context, ref);
      },
      onReturnToMistakeBookTopic: () {
        _returnToMistakeBookTopic(context, ref);
      },
      onReturnToTopics: () {
        _returnToTopics(context);
      },
    );
  }
}
