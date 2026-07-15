import 'dart:math';

import '../entities/quiz_question.dart';

class QuizRandomizer {
  const QuizRandomizer();

  List<QuizQuestion> randomize({
    required List<QuizQuestion> questions,
    required int seed,
    bool shuffleQuestionOrder = true,
  }) {
    if (questions.isEmpty) {
      return const [];
    }

    final random = Random(seed);

    final randomizedQuestions = <QuizQuestion>[
      for (final question in questions)
        _randomizeQuestionOptions(question: question, random: random),
    ];

    if (shuffleQuestionOrder) {
      randomizedQuestions.shuffle(random);
    }

    return List<QuizQuestion>.unmodifiable(randomizedQuestions);
  }

  QuizQuestion _randomizeQuestionOptions({
    required QuizQuestion question,
    required Random random,
  }) {
    if (!question.shuffleOptions || question.options.length < 2) {
      return question;
    }

    final indexedOptions = <_IndexedQuizOption>[
      for (var index = 0; index < question.options.length; index++)
        _IndexedQuizOption(originalIndex: index, text: question.options[index]),
    ];

    indexedOptions.shuffle(random);

    final newCorrectOptionIndex = indexedOptions.indexWhere((option) {
      return option.originalIndex == question.correctOptionIndex;
    });

    if (newCorrectOptionIndex < 0) {
      throw StateError('Jawapan betul tidak ditemui selepas randomization.');
    }

    return question.copyWith(
      options: List<String>.unmodifiable([
        for (final option in indexedOptions) option.text,
      ]),
      correctOptionIndex: newCorrectOptionIndex,
    );
  }
}

class _IndexedQuizOption {
  const _IndexedQuizOption({required this.originalIndex, required this.text});

  final int originalIndex;
  final String text;
}
