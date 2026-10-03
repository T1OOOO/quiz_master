# Изображения флагов: реализация и проверки

Дата: 2026-10-03. База: 824eefd. Это технический этап, не публикация нового банка флагов.

- Legacy importer сохраняет optional media (uri/kind/alt); закрытая проверка структуры отвергает неверные типы и приватные дополнительные поля. Старые варианты ответов и ревизии сохраняются.
- Flutter сохраняет media из public DTO при перемешивании вариантов и показывает image через native Image.network: HTTPS, contain, фиксированная высота 80 px, загрузка/ошибка без изменения геометрии, нейтральная русская подпись.
- Go TDD: до изменения TestImportQuestionMedia падал с unknown_field; после изменения весь internal/content PASS. Затем go test ./... (10 пакетов) и go vet ./... PASS.
- Flutter TDD: до реализации отсутствовал question-media; финальный flutter test: 52 PASS, flutter analyze: No issues. Детерминированные pending→error проверки сохраняют координаты изображения и четырёх ответов на 390×640 и 1262×576; отдельный API→перемешанная QuizPage тест проверяет сохранение media.
- Независимый review-flags-oct3 сначала потребовал дополнительные тесты (hub304), после исправления: requirements ACCEPT / code quality ACCEPT (hub307). Проверяющий не автор изменений; это отдельный контекст того же runtime, не cross-vendor review.
- flutter build web --release --no-pub --no-wasm-dry-run --pwa-strategy=none --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org PASS (34.6 s). Сборка предупредила о deprecated pwa-strategy и отсутствующей CupertinoIcons font family; успешная сборка не означает проверки всех иконок в браузере.
- Linux amd64 API: CGO_ENABLED=0, go build -trimpath -ldflags='-s -w' ./cmd/api PASS.
- API SHA256: 47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764.
- main.dart.js SHA256: 28a5daf5cfc95f6f5d09265b5b16c3cec9d0198be0e9853bafc27818a7ef97f5.

Остаются контентные этапы: принять реестр стран, права/варианты изображений, вопросы и объяснения; импортировать банк; проверить настоящую Web-игру с изображениями; выложить и проверить production. Android-сборка и production-проверка новых изображений здесь не заявлены. Первый выпуск 40 вопросов уже опубликован отдельно, см. PREPARATION_FIRST_RELEASE_RU.md.
