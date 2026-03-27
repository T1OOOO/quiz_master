import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/home/presentation/providers/home_providers.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';
import '../../../../fixtures/quiz_fixtures.dart';

import 'home_providers_test.mocks.dart';

@GenerateMocks([QuizRepository])
void main() {
  late MockQuizRepository mockRepository;
  late ProviderContainer container;
  late ProviderSubscription<String> searchSubscription;

  setUp(() {
    mockRepository = MockQuizRepository();
    container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    searchSubscription = container.listen<String>(
      searchQueryProvider,
      (previous, next) {},
      fireImmediately: true,
    );
  });

  tearDown(() {
    searchSubscription.close();
    container.dispose();
  });

  group('Home Providers', () {
    test('quizzesProvider should return list of quizzes', () async {
      // Arrange
      final expectedQuizzes = QuizFixtures.createQuizList();
      when(mockRepository.getAllQuizzes())
          .thenAnswer((_) async => expectedQuizzes);

      // Act
      final result = await container.read(quizzesProvider.future);

      // Assert
      expect(result, isA<List>());
      expect(result.length, expectedQuizzes.length);
      verify(mockRepository.getAllQuizzes()).called(1);
    });

    test('searchQueryProvider should update search query', () {
      // Arrange
      final notifier = container.read(searchQueryProvider.notifier);

      // Act
      notifier.update('test query');

      // Assert
      final state = container.read(searchQueryProvider);
      expect(state, 'test query');
    });

    test('currentPathProvider should update path', () {
      // Arrange
      final notifier = container.read(currentPathProvider.notifier);

      // Act
      notifier.add('Category1');

      // Assert
      final state = container.read(currentPathProvider);
      expect(state, ['', 'Category1']);
    });

    test('filteredQuizzesProvider should filter by search query', () async {
      // Arrange
      final quizzes = [
        QuizFixtures.createQuiz(
          id: 'quiz1',
          title: 'Test Quiz 1',
          categoryString: 'Alpha',
        ),
        QuizFixtures.createQuiz(
          id: 'quiz2',
          title: 'Another Quiz',
          categoryString: 'Beta',
        ),
      ];
      when(mockRepository.getAllQuizzes()).thenAnswer((_) async => quizzes);

      final searchNotifier = container.read(searchQueryProvider.notifier);
      searchNotifier.update('Test');

      // Wait for async to complete
      await container.read(quizzesProvider.future);

      // Act
      final result = container.read(filteredQuizzesProvider);

      // Assert
      expect(result.items.length, 1);
      expect(result.items.first.title, 'Test Quiz 1');
    });
  });
}
