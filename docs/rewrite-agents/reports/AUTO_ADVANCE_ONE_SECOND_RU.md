# Автопереход через одну секунду

2026-10-03, Europe/Istanbul. Задача `quiz_master-gt6`.
Код `ff91d0ca22d63c07074ac50a9359a1d71551b09a`.
Выпуск `quiz-2026.10.03-auto1s-ff91d0c`, Helm revision 12.

У правильного ответа исходный и возобновлённый таймер — 1 секунда вместо 3.
Пауза, ручное продолжение, объяснение в центральном окне, остановка при lifecycle/
route change и отмена при dispose сохранены. Неверный ответ не перелистывается сам.
API, вопросы, правильные ответы, данные и инфраструктурные шаблоны не менялись.

## Проверка

- TDD: тест ожидания Question 2 после одной секунды упал на старом таймере.
- При первом полном запуске новый промежуточный assert был слишком поздним:
  `pumpAndSettle` уже тратит время на анимацию входа Dialog. Исправлена временная
  граница теста, не увеличен таймер приложения. Возобновление отдельно проверяется:
  через 900 мс ещё Question 1, после дополнительных 100 мс — Question 2.
- `flutter test --no-pub`: 46 PASS, включая паузу/возобновление, неподвижную карточку
  и ручное продолжение неверного ответа.
- `flutter analyze --no-pub`: No issues found.
- Production: `flutter build web --release --no-pub --no-wasm-dry-run
  --pwa-strategy=none --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org`: PASS.
  Предварительная сборка с default loopback API НЕ опубликована. Известные
  предупреждения pwa-strategy/CupertinoIcons сохраняются.
- Проверены все отличия Web от предыдущего выпуска. Переданы JS, bootstrap,
  FontManifest и version.json; прежние API/контент/остальные assets переиспользованы.
- Remote-only runtime build network=none/pull=false, nginx -t, Helm lint,
  server dry-run и atomic rollout PASS. Pod 2/2, 0 restarts.
- HTTPS version.json показывает `auto_advance_seconds:1`. SHA256 скачанного
  публичного main.dart.js совпадает с локальной production-сборкой и метаданными:
  `406d47e8d850db54569fc908ee9819563784b36fbafbfb90c10f6b0572264728`.
- В отдельном браузере открыта gastronomy-1, выбран правильный ответ: окно
  «Верно» с «Следующий через 1 с · Пауза», затем следующий вопрос без ручного
  продолжения. Снимки просмотрены; browser errors пустой, собственный браузер закрыт.
  Это ручной smoke, точная временная граница подтверждается widget-тестом.
- Самопроверка пяти осей: изменение соответствует запросу, остаётся в владельце
  Dialog, новых зависимостей/секретов/запросов нет, обработчики отмены не изменены.
  Независимое cross-provider ревью и Android NOT_RUN; не заявлены как пройденные.

Image: `docker.io/library/quiz-master@sha256:1de5593cb5e99da28c737e95948281941da1867bc74248bbd0b51447047cefc2`.
API SHA256 прежний: `5c6558fc37e42f08fbf25d255f619d340bb42d3fb57f97f7d3a6c0b19379b1ba`.
Backup/restore-proof integrity ok, counts 39 participants / 440 attempts / 102 bundles:
`/opt/quiz-master/backups/quiz-2026.10.03-auto1s-ff91d0c.sqlite`.
PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` сохранён.
Rollback: `helm rollback quiz-master 11 -n quiz-master --wait`, без изменения live DB.
Language Learner revision 85 и edge 10 не менялись при подготовке выпуска.

Без помощников, локального Docker/Postgres и GitHub Actions. Библиотека подготовки
`quiz_master-8k1` остаётся открытой: её проверка/генерация ещё не выполнены.
