import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_entities.freezed.dart';
part 'quiz_entities.g.dart';

@freezed
sealed class Category with _$Category {
  const factory Category({required String id, required String title}) =
      _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
sealed class Question with _$Question {
  const factory Question({
    required String id,
    required String text,
    required List<String> options,
    String? explanation,
    @JsonKey(name: 'image_url') String? imageUrl,
    int? difficulty,
    @Default(false) bool fullyLoaded,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

@freezed
sealed class Quiz with _$Quiz {
  const factory Quiz({
    required String id,
    required String title,
    required String description,
    Category? category,
    String? categoryString,
    @Default([]) List<Question> questions,
    @JsonKey(name: 'questions_count') @Default(0) int questionsCount,
  }) = _Quiz;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Handle category which can be either string or Category object
    Category? categoryObj;
    String? categoryStr;

    if (json['category'] != null) {
      if (json['category'] is String) {
        categoryStr = json['category'] as String;
      } else if (json['category'] is Map<String, dynamic>) {
        categoryObj = Category.fromJson(
          json['category'] as Map<String, dynamic>,
        );
        categoryStr = categoryObj.title;
      }
    }

    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: categoryObj,
      categoryString: categoryStr,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      questionsCount: (json['questions_count'] as int?) ?? 0,
    );
  }
}

@freezed
sealed class Feedback with _$Feedback {
  const factory Feedback({
    required bool correct,
    @JsonKey(name: 'correct_answer') required int correctAnswer,
    String? explanation,
    @JsonKey(name: 'correct_text') String? correctText,
  }) = _Feedback;

  factory Feedback.fromJson(Map<String, dynamic> json) =>
      _$FeedbackFromJson(json);
}

@freezed
sealed class QuizStats with _$QuizStats {
  const factory QuizStats({
    required int correct,
    required int incorrect,
    required int answered,
    required int total,
  }) = _QuizStats;

  factory QuizStats.fromJson(Map<String, dynamic> json) =>
      _$QuizStatsFromJson(json);
}
