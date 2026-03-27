import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quiz_master/core/di/injection.dart';
import 'package:quiz_master/core/localization/app_localizations_provider.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart'
    as quiz_entities;
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:quiz_master/features/quiz/presentation/screens/quiz_screen.dart';
import 'package:quiz_master/main.dart';

class FakeQuizRepository implements QuizRepository {
  @override
  Future<quiz_entities.Feedback> checkAnswer(
    String quizId,
    String questionId,
    int answerIndex,
  ) async => const quiz_entities.Feedback(
    correct: true,
    correctAnswer: 0,
    explanation: 'Because it is correct.',
    correctText: 'Option A',
  );

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
  Future<quiz_entities.Question> getQuestion(
    String quizId,
    String questionId,
  ) async => const quiz_entities.Question(
    id: 'question-1',
    text: 'Which option works best on a small screen?',
    options: ['Option A', 'Option B', 'Option C', 'Option D'],
    explanation: 'Any option is acceptable in this fake repository.',
    difficulty: 4,
    fullyLoaded: true,
  );

  @override
  Future<quiz_entities.Quiz> getQuizById(String id) async =>
      await getQuizSummary(id);

  @override
  Future<quiz_entities.Quiz> getQuizSummary(String id) async =>
      const quiz_entities.Quiz(
        id: 'quiz-1',
        title: 'Small Screen Quiz',
        description: 'Quiz used by widget tests.',
        categoryString: 'General',
        questionsCount: 1,
        questions: [
          quiz_entities.Question(
            id: 'question-1',
            text: 'Which option works best on a small screen?',
            options: ['Option A', 'Option B', 'Option C', 'Option D'],
            difficulty: 4,
          ),
        ],
      );

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
  Future<void> pumpResponsiveApp(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'selected_theme': 'night',
      'app_locale': 'en',
    });
    await resetDependencies();
    await configureDependencies();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(FakeQuizRepository()),
        ],
        child: child,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('app renders home screen smoke test', (WidgetTester tester) async {
    await pumpResponsiveApp(
      tester,
      size: const Size(390, 844),
      child: const MyApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('home screen renders on small screens without overflow', (
    WidgetTester tester,
  ) async {
    await pumpResponsiveApp(
      tester,
      size: const Size(320, 640),
      child: const MyApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quiz screen renders on small screens without overflow', (
    WidgetTester tester,
  ) async {
    await pumpResponsiveApp(
      tester,
      size: const Size(320, 640),
      child: MaterialApp(
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: const QuizScreen(quizId: 'quiz-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Small Screen Quiz'), findsOneWidget);
    expect(find.text('Which option works best on a small screen?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
