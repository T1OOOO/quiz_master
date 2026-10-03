# Первые проверенные тренировочные раунды

2026-10-03. Два новых квиза: `prep-capitals-1` и `prep-film-actors-1`,
по 20 вопросов. Коллекция: 103 квиза / 3168 вопросов; 8 корневых категорий.
Это первый выпуск, а не завершение всей программы флагов/культуры/истории.

Независимый фактчекер `fact-preparation-oct3` сначала решал кандидаты без ключа.
После исправлений оба итоговых отчёта: ACCEPT20 / REVISE0 / REJECT0.
См. PREPARATION_CAPITALS_REVIEW.md и PREPARATION_CINEMA_REVIEW.md:
доступные официальные источники, индивидуальные вердикты и проверенные SHA256.
Это отдельный контекст того же Codex runtime, не cross-vendor review.

Исправлены чужие/короткие объяснения, ошибочные ссылки и буквенные заметки после
перестановки вариантов. Финальные объяснения совпадают с ключом по stable ID:
столицы 40–54 слова, кино 43–59; позиции правильного ответа 5/5/5/5 в каждом.
Уточнены молодая Роуз, взрослая Эльза, столичные функции ЮАР/Боливии/Нидерландов/
Шри-Ланки. Источники столиц — UNSD и национальные официальные сайты;
кино — прямые AFI/BFI/официальные cast records, AMPAS для наград.
source-evidence.md сохраняет историю проверки прежних, уже заменённых ссылок.

Импорт выполнен существующим quizctl; новый код API/DB/UI не понадобился.
Оба draft/bundle валидны. Сверены SHA256, все40 stem/options/private grading/
manifest explanations: полное сохранение исходных ответов и объяснений.
Cinema source bytes нормализованы при копировании; JSON семантически идентичен
принятому legacy: source SHA256 be7107b971b4ffa7e2a35a0d3f553efa38b23ab58b8c9313a28a6c4ba02410ad.
Capitals source SHA256 a29c9ee7aa363d6fa7a481d16dd30d52ad105ac884fbed4692af9ce451a82279.
Публикационные bundle timestamps: 2026-10-03T02:09:21Z.
Private source/key/bundle не размещаются в публичном каталоге; allowlist metadata
проверяется исполняемым тестом quizctl. Старые попытки сохраняют версии в SQLite.

Проверки из C:/ap/quiz_master:

- RED Flutter discovery: новая коллекция отсутствовала, ожидаемые103/3168 не найдены.
- Первый Go suite выявил ещё один устаревший101/3128 golden в catalog_test;
  обновлён счётчик и явно проверено присутствие обоих новых ID.
- `go test -p=1 ./next/server/...`: PASS все10 пакетов.
- `go vet -p=1 ./next/server/...`: PASS.
- `flutter test --no-pub`: PASS49; поиск нового квиза и 8 категорий проверены.
- `flutter analyze --no-pub`: No issues found.
- JSON/schema validation и сравнение source/manifest/bundle: PASS40.

Данные catalog.json — отдельный Flutter asset; JS/API не изменились.
Для выпуска достаточно обновить этот asset и серверные JSON в существующем
runtime image. Flutter/Go production recompilation не требуется.
Android build и отдельное независимое code review NOT_RUN; не заявлены PASS.
Production: `quiz-2026.10.03-preparation-ef96a79`, интеграция
`ef96a79b0429671e1719a4c452d411fa245b4b4b`, Helm revision14.
Image digest `sha256:28228ed6cf51259c9ad5fe9af4a8949fff82be1c6713d98789f11fc6fbff5a43`.
API SHA256 `5c6558fc37e42f08fbf25d255f619d340bb42d3fb57f97f7d3a6c0b19379b1ba`
и JS SHA256 `2a957994dcf86ca0ac7eb9e7a21d0694a834f908bda2ae1f10786e1be88191d1`
не изменились. Public catalog SHA256
`e9b2fd0b420ec548acb86ccedec24602aeddaaec7f44cdeade920b1c8b099ccc` совпал
с исходным asset при отдельной HTTPS-загрузке; фактические103/3168 подтверждены.

Remote runtime build network=none/pull=false, nginx-t, Helm strict lint/server
dry-run, atomic upgrade PASS. Pod2/2 Running0restarts, health/ready OK;
исходный PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` сохранён.
Backup `/opt/quiz-master/backups/quiz-2026.10.03-preparation-ef96a79.sqlite`:
online backup + независимый restore integrity OK, до релиза40participants /
441attempts /102bundles. Проверочные попытки браузера добавлены обычным API.
Первый shell hostname-probe был неверно процитирован PowerShell и не был
зачтён; сама release.sh до сборки проверила фактический racknerd-f0269d5.

Браузер1262x576 и390x640: 8 категорий помещаются; переход
География→Столицы→квиз работает без запроса имени. Оба квиза открываются по URL,
каждый показывает1/20. Неверный ответ открывает центральный диалог с полным
правильным объяснением; Продолжить переносит на2/20. Верный ответ в столицах
автоматически перевёл2/20→3/20. Точная1s задержка покрыта Flutter-тестом.
Кино008 показывает Foster/Clarice, не чужой Schindler-текст. Длинный вопрос
про Fellowship и все4варианта помещаются на390x640. Browser errors пусты.
Снимки preparation-library-phone.png/preparation-capitals-feedback.png/
preparation-cinema-feedback-phone.png просмотрены. Собственный браузер закрыт,
ресурсы освобождены; полноценное завершение20ответов в production не заявляется.
Rollback: `helm rollback quiz-master 13 -n quiz-master --wait`; live DB не откатывать.

Остаток большого плана отслеживается в quiz_master-8k1; флаги и следующие
культурные/исторические блоки ещё не опубликованы.
