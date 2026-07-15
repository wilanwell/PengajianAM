import '../entities/quiz_question.dart';

abstract interface class QuizRepository {
  Future<List<QuizQuestion>> getQuestions({
    required String topicId,
    required int limit,
  });
}
