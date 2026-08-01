import 'package:flutter/material.dart';

import '../../domain/entities/quiz_result.dart';
import '../coordinators/quiz_review_coordinator.dart';
import '../widgets/quiz_review_content.dart';

class QuizReviewPage extends StatefulWidget {
  const QuizReviewPage({required this.result, super.key});

  final QuizResult result;

  @override
  State<QuizReviewPage> createState() {
    return _QuizReviewPageState();
  }
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  static const _coordinator = QuizReviewCoordinator();

  QuizReviewFilter _selectedFilter = QuizReviewFilter.all;

  void _selectFilter(QuizReviewFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleQuestionIndexes = _coordinator.visibleQuestionIndexes(
      result: widget.result,
      filter: _selectedFilter,
    );

    return QuizReviewContent(
      result: widget.result,
      selectedFilter: _selectedFilter,
      visibleQuestionIndexes: visibleQuestionIndexes,
      onFilterSelected: _selectFilter,
    );
  }
}
