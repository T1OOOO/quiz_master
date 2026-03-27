# Quiz Master Flutter Application

Flutter версия приложения Quiz Master с полной копией функционала React Native приложения.

## Архитектура

Проект использует Clean Architecture по образцу `language_learner`:

- **Features** - модули приложения (quiz, home)
- **Domain** - бизнес-логика и entities
- **Data** - репозитории и datasources
- **Presentation** - UI экраны и providers

## Технологии

- **State Management**: Riverpod с code generation
- **Navigation**: Go Router с typed routes
- **HTTP Client**: Dio с interceptors
- **Models**: Freezed для immutable models
- **DI**: GetIt + Riverpod
- **i18n**: flutter_localizations (планируется)

## Структура проекта

```
lib/
├── core/           # Общие компоненты
│   ├── api/        # API клиент
│   ├── di/         # Dependency Injection
│   ├── network/    # Dio клиент и interceptors
│   └── providers/  # Core providers
├── features/       # Модули приложения
│   ├── quiz/       # Модуль квизов
│   └── home/       # Главный экран
├── router/         # Навигация
└── theme/          # Темы (планируется)
```

## Установка

```bash
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Запуск

```bash
flutter run
```

## Статус реализации

- ✅ Базовая структура проекта
- ✅ Зависимости настроены
- ✅ API клиент и репозитории
- ✅ Роутинг настроен (Go Router с typed routes)
- ✅ Экран списка квизов с поиском и категориями
- ✅ Экран прохождения квиза с вопросами
- ✅ State management (Riverpod)
- ✅ Компоненты: QuestionCard, AnswerOptions, QuestionHeader
- ⏳ Система тем (планируется)
- ⏳ Интернационализация (планируется)

## Основные компоненты

### Features

**Home Screen** (`lib/features/home/`)
- Список квизов с поиском
- Навигация по категориям (folders)
- Breadcrumbs для навигации
- Фильтрация по поисковому запросу

**Quiz Screen** (`lib/features/quiz/`)
- Отображение вопросов
- Выбор ответов
- Проверка ответов с feedback
- Статистика (правильные/неправильные ответы)
- Навигация между вопросами
- Сброс и перемешивание вопросов

### Core

- **API Client**: Dio с interceptors (retry, logging)
- **Repositories**: Clean Architecture с разделением domain/data
- **Providers**: Riverpod для state management
- **Router**: Go Router с typed routes
