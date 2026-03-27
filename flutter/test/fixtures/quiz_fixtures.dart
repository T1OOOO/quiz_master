import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';

/// Test fixtures for Quiz entities
class QuizFixtures {
  static Question createQuestion({
    String? id,
    String? text,
    List<String>? options,
    String? explanation,
    String? imageUrl,
    int? difficulty,
  }) {
    return Question(
      id: id ?? 'q1',
      text: text ?? 'Test question?',
      options: options ?? ['Option 1', 'Option 2', 'Option 3'],
      explanation: explanation,
      imageUrl: imageUrl,
      difficulty: difficulty ?? 1,
      fullyLoaded: true,
    );
  }

  static Quiz createQuiz({
    String? id,
    String? title,
    String? description,
    Category? category,
    String? categoryString,
    List<Question>? questions,
    int? questionsCount,
  }) {
    return Quiz(
      id: id ?? 'quiz1',
      title: title ?? 'Test Quiz',
      description: description ?? 'Test Description',
      category: category,
      categoryString: categoryString ?? 'Test Category',
      questions: questions ?? [createQuestion()],
      questionsCount: questionsCount ?? 1,
    );
  }

  static Category createCategory({String? id, String? title}) {
    return Category(id: id ?? 'cat1', title: title ?? 'Test Category');
  }

  static Feedback createFeedback({
    required bool correct,
    String? explanation,
    int? correctAnswer,
  }) {
    return Feedback(
      correct: correct,
      explanation: explanation ?? 'Test explanation',
      correctAnswer: correctAnswer ?? (correct ? 0 : 1),
    );
  }

  static List<Quiz> createQuizList({int count = 3}) {
    return List.generate(
      count,
      (index) => createQuiz(
        id: 'quiz$index',
        title: 'Test Quiz $index',
        categoryString: 'Category ${index % 2}',
      ),
    );
  }
}
