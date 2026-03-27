# Руководство по тестированию

## Архитектура тестирования

Проект использует Clean Architecture с разделением на слои, что упрощает тестирование:

- **Domain** - бизнес-логика (тестируется unit-тестами)
- **Data** - репозитории и API клиенты (тестируются с моками)
- **Presentation** - UI и providers (тестируются с моками зависимостей)

## Структура тестов

```
test/
├── core/                    # Тесты для core компонентов
│   ├── api/                # API Client тесты
│   └── utils/              # Утилиты тесты
├── features/               # Тесты для features
│   ├── auth/               # Auth тесты
│   ├── quiz/               # Quiz тесты
│   └── home/               # Home тесты
├── fixtures/               # Тестовые данные
│   ├── auth_fixtures.dart
│   └── quiz_fixtures.dart
└── helpers/                # Тестовые хелперы
    └── test_helpers.dart
```

## Запуск тестов

```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/core/api/api_client_test.dart

# С покрытием
flutter test --coverage
```

## Типы тестов

### 1. Unit тесты

Тестируют отдельные компоненты изолированно:

```dart
test('getAllQuizzes should return list of quizzes', () async {
  // Arrange
  when(mockApiClient.getAllQuizzes()).thenAnswer(...);
  
  // Act
  final result = await repository.getAllQuizzes();
  
  // Assert
  expect(result, isA<List<Quiz>>());
});
```

### 2. Provider тесты

Тестируют Riverpod providers с моками зависимостей:

```dart
test('quizStateProvider should update state', () {
  final container = ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  
  // Test provider behavior
});
```

### 3. Widget тесты

Тестируют UI компоненты (планируется):

```dart
testWidgets('HomeScreen should display quizzes', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Quiz Master'), findsOneWidget);
});
```

## Моки и фикстуры

### Генерация моков

Используется `mockito` для генерации моков:

```dart
@GenerateMocks([ApiClient, QuizRepository])
void main() {
  // Tests
}
```

Запустить генерацию:
```bash
dart run build_runner build
```

### Фикстуры

Используются для создания тестовых данных:

```dart
final quiz = QuizFixtures.createQuiz(id: 'quiz1');
final user = AuthFixtures.createUser(username: 'testuser');
```

## Тестирование Providers

### Override providers для тестирования

```dart
final container = ProviderContainer(
  overrides: [
    quizRepositoryProvider.overrideWithValue(mockRepository),
    apiClientProvider.overrideWithValue(mockApiClient),
  ],
);
```

### Тестирование async providers

```dart
test('quizzesProvider should load quizzes', () async {
  when(mockRepository.getAllQuizzes()).thenAnswer(...);
  
  final result = await container.read(quizzesProvider.future);
  
  expect(result, isA<List<Quiz>>());
});
```

## Покрытие кода

### Генерация отчета о покрытии

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Целевое покрытие

- **Core компоненты**: 90%+
- **Repositories**: 85%+
- **Providers**: 80%+
- **Utils**: 95%+

## Best Practices

### 1. Изоляция тестов

Каждый тест должен быть независимым:

```dart
setUp(() {
  // Инициализация для каждого теста
  mockRepository = MockQuizRepository();
});

tearDown(() {
  // Очистка после каждого теста
  container.dispose();
});
```

### 2. Arrange-Act-Assert паттерн

```dart
test('example', () {
  // Arrange - подготовка данных
  final expected = QuizFixtures.createQuiz();
  
  // Act - выполнение действия
  final result = repository.getQuiz('quiz1');
  
  // Assert - проверка результата
  expect(result, expected);
});
```

### 3. Использование фикстур

Вместо создания объектов вручную:

```dart
// ❌ Плохо
final quiz = Quiz(id: '1', title: 'Test', ...);

// ✅ Хорошо
final quiz = QuizFixtures.createQuiz(id: '1', title: 'Test');
```

### 4. Моки зависимостей

Всегда мокайте внешние зависимости:

```dart
@GenerateMocks([ApiClient, QuizRepository])
void main() {
  late MockApiClient mockApiClient;
  
  setUp(() {
    mockApiClient = MockApiClient();
  });
}
```

## Известные проблемы

1. **FlutterSecureStorage** - требует настройки для тестов
2. **Riverpod code generation** - нужно перегенерировать после изменений
3. **Async providers** - требуют правильной обработки async/await

## Планы по улучшению

- [ ] Добавить интеграционные тесты
- [ ] Добавить widget тесты для основных экранов
- [ ] Настроить CI/CD для автоматического запуска тестов
- [ ] Добавить golden тесты для UI
- [ ] Улучшить покрытие до 90%+
