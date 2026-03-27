# Проверка ресурсов с сервера и дополнительные функции

## ✅ Проверка загрузки ресурсов с сервера

### Изображения вопросов
**Загружаются с сервера** ✅
- Все изображения вопросов (`question.image_url`) загружаются через `Image.network()`
- URL формируется через `ImageUtils.getImageUrl()` 
- Поддержка абсолютных URL (http://, https://)
- Поддержка относительных путей (добавляется baseUrl)
- Индикаторы загрузки и обработка ошибок

### Данные квизов
**Загружаются с сервера** ✅
- Все квизы загружаются через API (`/api/quizzes`)
- Вопросы загружаются по требованию (`/api/quizzes/:id/questions/:qid`)
- Используется lazy loading для оптимизации

### Локальные ресурсы
**Только для UI** ✅
- Фоновые изображения тем (опционально, могут быть с сервера)
- Иконки категорий (Material Icons)
- Текстуры для карточек (локальные assets)

## 🔐 OAuth и Аутентификация

### Реализовано
- ✅ Структура для OAuth логина (готово к расширению)
- ✅ Обычный login/register через API
- ✅ Guest login (без пароля)
- ✅ JWT токены с безопасным хранением (FlutterSecureStorage)
- ✅ Автоматическое восстановление сессии

### API Endpoints
- `POST /api/login` - Вход
- `POST /api/register` - Регистрация
- `POST /api/guest` - Гостевой вход
- `GET /api/quota` - Получить квоты пользователя (требует токен)

### Использование
```dart
// Login
ref.read(authStateProvider.notifier).login(username, password);

// Guest login
ref.read(authStateProvider.notifier).guestLogin(username);

// Check auth state
final authState = ref.watch(authStateProvider);
final authData = await authState;
if (authData != null) {
  // User is authenticated
  final token = authData.token;
  final user = authData.user;
}
```

## 📊 Статистика использования

### Реализовано
- ✅ Сбор статистики прохождения квизов
- ✅ Отслеживание правильных/неправильных ответов
- ✅ Подсчет времени, потраченного на квизы
- ✅ Отправка результатов на сервер (`/api/submit`)
- ✅ Leaderboard (таблица лидеров)

### API Endpoints
- `POST /api/submit` - Отправить результат квиза (требует токен)
- `GET /api/leaderboard` - Получить таблицу лидеров

### Использование
```dart
// Update statistics after quiz
ref.read(userStatisticsNotifierProvider.notifier).updateFromQuiz(
  correct: 5,
  incorrect: 2,
  timeSpent: 300, // seconds
);

// Submit score to server
final authData = await ref.read(authStateProvider);
if (authData != null) {
  await apiClient.submitScore(
    quizId,
    score,
    total,
    authData.token,
  );
}
```

## 🚫 Ограничения (Quota/Limits)

### Реализовано
- ✅ Проверка ограничений на количество квизов
- ✅ Проверка ограничений на количество вопросов
- ✅ Проверка ограничений на количество попыток прохождения
- ✅ Утилита `QuotaChecker` для проверки всех ограничений

### Типы ограничений
1. **Quizzes Limit** - Максимальное количество пройденных квизов
2. **Questions Limit** - Максимальное количество отвеченных вопросов
3. **Attempts Limit** - Максимальное количество попыток прохождения одного квиза

### Использование
```dart
// Check if user can start quiz
final quota = await ref.read(userQuotaProvider);
final statistics = ref.read(userStatisticsNotifierProvider);

if (!QuotaChecker.canStartQuiz(
  quota: quota,
  statistics: statistics,
)) {
  // Show limit reached message
  return;
}

// Check remaining quizzes
final remaining = QuotaChecker.getRemainingQuizzes(
  quota: quota,
  statistics: statistics,
);
```

## 📝 Интеграция в Quiz Flow

### При запуске квиза
1. Проверить `canStartQuiz()` - можно ли начать новый квиз
2. Проверить `canAttemptQuiz()` - можно ли попытаться пройти этот квиз снова
3. Если ограничения достигнуты - показать сообщение

### При ответе на вопрос
1. Проверить `canAnswerQuestion()` - можно ли ответить на вопрос
2. Если ограничение достигнуто - показать сообщение

### После завершения квиза
1. Обновить локальную статистику
2. Отправить результат на сервер (если пользователь авторизован)
3. Обновить счетчик попыток

## 🔧 Файлы

### Auth
- `lib/features/auth/domain/entities/auth_entities.dart` - Модели пользователя и аутентификации
- `lib/features/auth/data/repositories/auth_repository.dart` - Реализация репозитория
- `lib/features/auth/presentation/providers/auth_providers.dart` - Riverpod providers

### Statistics
- `lib/features/statistics/domain/entities/statistics_entities.dart` - Модели статистики
- `lib/features/statistics/presentation/providers/statistics_providers.dart` - Riverpod providers

### Utils
- `lib/core/utils/quota_checker.dart` - Утилита для проверки ограничений
- `lib/core/utils/image_utils.dart` - Утилита для работы с изображениями

## ⚠️ Заметки

1. **OAuth**: Структура готова, но полная реализация OAuth (Google, GitHub и т.д.) требует дополнительной настройки на backend
2. **Quota API**: Endpoint `/api/quota` должен быть реализован на backend для получения квот пользователя
3. **Secure Storage**: Токены хранятся в `FlutterSecureStorage` для безопасности
4. **Guest Mode**: Гостевой режим работает без ограничений (quota = null)

## 🚀 Следующие шаги

1. Реализовать endpoint `/api/quota` на backend
2. Добавить UI для отображения ограничений
3. Добавить UI для OAuth логина (если нужно)
4. Добавить уведомления при достижении ограничений
5. Добавить кеширование статистики локально
