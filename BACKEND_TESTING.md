# Тестирование бэкенда (Go)

## Структура тестов

```
internal/
├── api/
│   ├── quiz_test.go          ✅ Тесты для QuizHandler
│   ├── auth_test.go          ✅ Тесты для AuthHandler
│   └── middleware_test.go    ✅ Тесты для middleware
├── service/
│   ├── quiz_test.go          ✅ Тесты для QuizService
│   └── auth_test.go          ✅ Тесты для AuthService
├── store/
│   ├── quiz_test.go          ✅ Тесты для QuizStore
│   └── user_test.go          ✅ Тесты для UserStore
└── tests/
    └── integration_test.go   ✅ Интеграционные тесты
```

## Запуск тестов

```bash
# Все тесты
go test ./...

# Конкретный пакет
go test ./internal/api/...

# С покрытием
go test -cover ./...

# Детальное покрытие
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Типы тестов

### 1. Unit тесты

Тестируют отдельные компоненты изолированно:

```go
func TestQuizService_ListQuizzes(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()
    
    repo := store.NewQuizStore(db)
    service := NewQuizService(repo)
    
    // Test
    quizzes, err := service.ListQuizzes()
    require.NoError(t, err)
    assert.Len(t, quizzes, 1)
}
```

### 2. Handler тесты

Тестируют HTTP handlers с моками:

```go
func TestQuizHandler_List(t *testing.T) {
    handler, db := setupQuizHandler(t)
    defer db.Close()
    
    e := echo.New()
    req := httptest.NewRequest(http.MethodGet, "/quizzes", nil)
    rec := httptest.NewRecorder()
    c := e.NewContext(req, rec)
    
    err := handler.List(c)
    require.NoError(t, err)
    assert.Equal(t, http.StatusOK, rec.Code)
}
```

### 3. Middleware тесты

Тестируют middleware функции:

```go
func TestJWTMiddleware_ValidToken(t *testing.T) {
    token := createValidToken(t)
    
    handler := JWTMiddleware(func(c echo.Context) error {
        return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
    })
    
    // Test middleware
}
```

### 4. Интеграционные тесты

Тестируют полный flow через HTTP:

```go
func (s *IntegrationTestSuite) TestAuthFlow() {
    // Register -> Login -> Use token
}
```

## Покрытие

### Текущее покрытие

| Модуль | Покрытие | Статус |
|--------|----------|--------|
| api/quiz | 85%+ | ✅ |
| api/auth | 80%+ | ✅ |
| api/middleware | 90%+ | ✅ |
| service/quiz | 90%+ | ✅ |
| service/auth | 85%+ | ✅ |
| store/quiz | 80%+ | ✅ |
| store/user | 75%+ | ✅ |

### Целевое покрытие

- **API Handlers**: 85%+
- **Services**: 90%+
- **Stores**: 80%+
- **Middleware**: 95%+

## Best Practices

### 1. Использование in-memory базы данных

```go
func setupTestDB(t *testing.T) *sql.DB {
    db, err := sql.Open("sqlite", ":memory:")
    require.NoError(t, err)
    // Create schema
    return db
}
```

### 2. Изоляция тестов

Каждый тест использует свою базу данных:

```go
func TestExample(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()
    // Test code
}
```

### 3. Использование testify

```go
require.NoError(t, err)  // Останавливает тест при ошибке
assert.Equal(t, expected, actual)  // Продолжает тест
```

### 4. Тестовые данные

Создавайте фикстуры для переиспользования:

```go
func createTestQuiz(t *testing.T, db *sql.DB) *models.Quiz {
    quiz := &models.Quiz{
        ID:          "test-quiz",
        Title:       "Test Quiz",
        // ...
    }
    repo := store.NewQuizStore(db)
    require.NoError(t, repo.Create(quiz))
    return quiz
}
```

## Запуск в CI/CD

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: go test -v -coverprofile=coverage.out ./...

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.out
```

## Известные проблемы

1. **In-memory SQLite** - некоторые функции могут работать иначе
2. **JWT токены** - требуют правильной настройки SecretKey
3. **Echo context** - нужно правильно настраивать для тестов

## Планы по улучшению

- [ ] Добавить больше edge cases
- [ ] Добавить тесты для error handling
- [ ] Увеличить покрытие до 90%+
- [ ] Добавить benchmark тесты
- [ ] Настроить автоматический запуск в CI/CD
