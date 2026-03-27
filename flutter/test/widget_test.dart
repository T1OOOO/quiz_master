import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quiz_master/core/di/injection.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart'
    as quiz_entities;
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:quiz_master/main.dart';

class FakeQuizRepository implements QuizRepository {
  @override
  Future<quiz_entities.Feedback> checkAnswer(
    String quizId,
    String questionId,
    int answerIndex,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<quiz_entities.Quiz>> getAllQuizzes() async => [
    const quiz_entities.Quiz(
      id: 'quiz-1',
      title: 'Smoke Quiz',
      description: 'Test description',
      categoryString: 'General',
      questionsCount: 1,
    ),
  ];

  @override
  Future<quiz_entities.Question> getQuestion(String quizId, String questionId) {
    throw UnimplementedError();
  }

  @override
  Future<quiz_entities.Quiz> getQuizById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<quiz_entities.Quiz> getQuizSummary(String id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> reportIssue(
    String quizId,
    String questionId,
    String message,
    String questionText,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> submitScore(String quizId, int score, int total, String? token) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('app renders home screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'selected_theme': 'night'});
    await resetDependencies();
    await configureDependencies();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(FakeQuizRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
