# Культурная библиотека: проверенные 200 вопросов

Дата: 2026-10-03. PUBLISHED: живой каталог 115 наборов / 3798 вопросов, Helm revision 17. Все 200 новых вопросов прошли независимый фактчек, технический импорт и живую проверку ниже.

## Состав и редакционные решения

- Классическая литература: 30; послевоенная/современная: 30.
- Мюзиклы: 20; балеты: 20; оперы: 20; музыкальные произведения: 20.
- Исторические события: 20; греческая мифология: 20; скандинавские предания: 20.
- Все 200 получили независимый фактчек ACCEPT, включая источники, варианты, оговорки авторства и объяснения. Отчёты: PREPARATION_BOOKS_60_REVIEW.md, PREPARATION_MUSIC_60_REVIEW.md, PREPARATION_HISTORY20_REVIEW.md, PREPARATION_MYTHOLOGY40_REVIEW.md и ../PREPARATION_COMPOSITIONS20_REVIEW.md.
- Никакого утверждения «вся мировая культура покрыта». Полная программа около 1890–2200 новых вопросов ещё не завершена. Фольклор вне Греции/Скандинавии, расширенные кино/книги/музыкальные реестры остаются в плане.
- У книжных источников в публикуемой копии изменено только описание: убрано слово «Черновик». Вопросы/варианты/ответы/объяснения неизменны.
- compositions20-legacy.json оказался редакционным массивом, а не legacy pack. Адаптация в prep_compositions.json явная: question → text; A/B/C/D → массив в этом порядке; answer → индекс 0/1/2/3; id и explanation сохранены. Первые два отказа quizctl (invalid_json / unknown_field) не были приняты за успешный импорт; исправленный pack прошёл import/validate/build/validate.
- Исторический accepted30-snapshot книг был ранее перезаписан старым renderer. Не выдаётся за восстановленное побайтовое доказательство. Текущие 60 книжных вопросов независимо перепроверены целиком; повреждённый исторический артефакт сохранён и описан в книжном отчёте.

## Проверки

- verify-culture200.ps1: PASS, 200/200 reviewed stems/options/answers/explanations; manifest explanations; private grading/option-ID mapping; metadata-only каталог 115/3798.
- Независимое техническое ревью: ACCEPT; PREPARATION_CULTURE200_TECH_REVIEW.md SHA256 6c03984c4b4f9218a2327eb7f02db18adb888a15cd4cf0ff7ce34ec098fa9a7b.
- go test -p=1 ./...: PASS; SQLite полный корпус, 115 банков / 3798 ответов и история после перезапуска (57.145 s).
- go vet ./...: PASS.
- flutter test --no-pub: 54 PASS; flutter analyze --no-pub: No issues found.
- Финальная flutter build web --release --no-pub --no-wasm-dry-run --pwa-strategy=none --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org: PASS, 54.4 s. Предыдущая сборка с неверным именем define QM_API_BASE не используется: она оставляла loopback default. Нефатальные предупреждения: устаревшая pwa-strategy и неиспользуемая семья CupertinoIcons; не Android/WASM acceptance.
- Раскладка 12 категорий 1262×568: TDD RED (Природа bottom=602 вне viewport), GREEN после меньшей высоты обложек при >8 категориях. Проверены реальные mappings обложек. Мобильная библиотека остаётся прокручиваемой, не обещает уместить 12 карточек одновременно.

## Обложки и происхождение

Использован встроенный imagegen; изображения — атмосферные иллюстрации, не доказательства исторических/мифологических фактов. Все три результата визуально просмотрены. Исходники 1536×1024 сохранены в Codex generated_images; JPEG 600×400 созданы стандартным System.Drawing без нового пакета. Литература повторно использует существующую philology.jpg.

- Музыка: next/apps/quiz_app/assets/categories/music.jpg, 52434 bytes; оригинал C:/Users/Alexey_Matvienko/.codex/generated_images/01a0be0d-bffb-7cd0-abcf-cac0f5458013/exec-2e88fca7-8854-4c21-abf5-f76220782e23.png.
- История: next/apps/quiz_app/assets/categories/history.jpg, 77860 bytes; оригинал exec-e41a23fc-5e86-46cc-9383-ed2879262751.png в том же каталоге.
- Мифология: next/apps/quiz_app/assets/categories/mythology.jpg, 73063 bytes; оригинал exec-f571d13d-762b-4cd0-8c9e-1c8b49bfc280.png в том же каталоге. Не идентифицируется конкретное божество или историческая реконструкция.

Промпты:
- musicCoverPrompt: Use case: photorealistic-natural. Asset type: landscape category cover for a cozy quiz app, music and stage arts. A beautifully worn violin and bow resting on a dark wooden theatre music desk, softly blurred burgundy velvet stage curtains behind. Warm amber lamplight, muted teal shadows, chestnut and antique brass palette, realistic wood grain. Wide 3:2 composition, violin clearly recognizable in a small center-cropped horizontal card. Calm inviting atmosphere, restrained contrast, not bright white. No readable sheet music, no text, logos, watermark, collage or panels.
- historyCoverPrompt: Use case: photorealistic-natural. Asset type: landscape HISTORY category cover for a cozy quiz app. A historian's wooden desk with a small brass hourglass, aged folded maps and a leather-bound archival volume, warm amber desk-lamp light, subdued teal shadows and chestnut wood, inviting quiet library atmosphere. Wide 3:2 composition, objects clear and centered enough for a very shallow horizontal card crop. Realistic paper and brass textures, restrained contrast, no large white areas. The maps have only abstract faded marks, no readable labels or political claims. No text, lettering, logos, watermark, people, weapons or collage.
- mythologyCoverPrompt: Use case: photorealistic-natural. Asset type: landscape MYTHOLOGY category cover for a cozy quiz library. A weathered classical marble bust with a laurel wreath and a small ancient-style lyre on a dark wooden study table; softly blurred moody forest and faint classical columns in the background, suggesting Greek and northern legends without depicting a specific identified deity. Gentle warm amber lamplight, deep muted teal, chestnut wood and antique ivory stone. Wide 3:2 composition, bust recognizable in a shallow horizontal center-cropped card. Quiet magical scholarly atmosphere, realistic stone, restrained contrast. No bright white background, readable text, runes, logos, watermark, collage, horned helmets or modern fantasy armor. Decorative artwork, not factual reconstruction.

## Выкладка

PUBLISHED: quiz-2026.10.03-culture-d5f070b, commit d5f070b5070fe6854539c3b2cf4a44df637ad5a5; Helm revision 17. Проверенный racknerd-f0269d5 / 192.3.164.184, namespace quiz-master; deployment 1/1, pod 2/2 Running, 0 restarts; тот же PVC pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf.

- Payload SHA256 f4a88c372b1e38837a3d3a2839935397099d81d2b15a344373de3bec178e4750 (22320900 bytes); image sha256:851706cd15156eee637b62267eff8b6140d31aaaafa7cb28691b6d95481cb54f.
- API sha256 47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764 reused unchanged; JS 6d81798e8ff7ae7851925a0b2bc7ff32c79cc020888a8a182a856ddd04e392c2; live catalog 2d399603da666fd805c9b852805e94d1f40faaa3a1c309095126913a13f1edbb.
- Online SQLite backup /opt/quiz-master/backups/quiz-2026.10.03-culture-d5f070b.sqlite: integrity ok, independent restored copy integrity ok, counts participants/attempts/bundles 51/453/107. Старые попытки и snapshots сохраняются; количество stored bundles не обязано равняться текущему каталогу.
- nginx -t, strict Helm lint, server dry-run, atomic upgrade PASS. Dry-run warned about absent kubectl last-applied annotations on Helm-managed resources; actual apply not used.
- Live GET /v1/catalog?quiz_id=… for all nine new banks: 200 total, correct counts, public grading absent. Static metadata catalog SHA matched local; three new JPEG cover SHAs matched live.
- Browser actual Chromium 1262×568: all 12 root categories visible; compositions real shuffled 20-question round; wrong Handel/Vivaldi answer produced centered explanation without bottom layout shift; Continue reached 2/20.
- Browser 390×640: modern books, Greek mythology and history showed actual question and four options within viewport. Correct Orpheus answer auto-advanced to 2/20; wrong Dionysos/Hephaistos answer produced readable centered explanation. No browser errors returned.
- Mouse-down/move/up on phone-sized library scrolled from clipped lower rows to visible Филии/Филология; not merely DOM/wheel scrolling. Ten screenshots saved in culture200-evidence/. Physical Android device and all-20 UI completion NOT_RUN; full 3798-answer correctness/restart path is covered by server SQLite integration.
- Own Chromium sessions closed after checks. Two browser leases expired between model turns; no new browser action was executed under expired grants. Owner closed browsers, reconciled actual quiescence, and acquired fresh grants before resuming.
- Rollback revision 16, without restoring old DB over newer answers. No local Docker/PostgreSQL/GitHub Actions.

## Следующее обновление: ещё 60 вопросов

LOCAL READY, пока не опубликовано: фольклор 20 и фильмы/актёры 40. Каталог 117 наборов / 3858 вопросов. Общее новое покрытие после публикации — 730 вопросов; полная программа 1890–2200 ещё не завершена.

- Фактическое ревью обоих банков FINAL ACCEPT; кино исправлено по двум замечаниям (канонический AFI URL и замена повторного знания Michael Corleone/Al Pacino на Margo Channing/Bette Davis).
- Источники: folklore-legacy20.json raw SHA a9f5e30b919a74b17f7eb5152026503f533c6a763c4759d7a2d05e5040677ee9; movie-actors40-legacy-pack.json SHA c2102b3866e8d41c7f7ddc9f8aa0688b3ad537d484c31c6a4c2916c25079ae9a.
- Importer source_sha256 нормализует только CRLF/CR в LF (canonical.go:192–200): folklore manifest da16d79a8b015f55c1c124e306d584f2c85ad4011a20c96ea449eae7155cc1c2 не обязан совпадать с raw Windows SHA. Независимое повторное ревью подтвердило это правило: ACCEPT, не дефект.
- Canonical bundle SHA: folklore a13766ef62b6ea4abd19504a6f8c4a760ca296c66b6d2bd89be249be2a4d591d; actors c20dea8e8e7be1e696f48b71a02f4afe1388ebff7ed807ece1426f54eaf627d0.
- verify-culture200.ps1 теперь проверяет все 260 вопросов и normalized source SHA: PASS. Независимое техническое ревью переноса 60, приватных ключей и публичной границы: ACCEPT.
- Go test ./... и go vet ./... PASS; SQLite ответил на все 3858 вопросов и проверил результаты/историю после restart. GOMAXPROCS=2, -p 1.
- Flutter analyze PASS; все 55 тестов PASS, повторно после каталога117 (concurrency=1). Release web с QM_API_BASE_URL=https://quiz.kotopedia.org собран; metadata asset обновлён после импорта. JS SHA 13ded45a5af928eb7450c8587f17201fffc177761a90743d56a56b8894a88301; каталог a0c164e309d70f01032e83733c2785c26189fdd219c2d3819468fd1ee8bb1819.
- Найден воспроизводимый desktop overflow: на1262×768 нижний ряд был821px, RED. Минимальное изменение noncompact >8 categories coverHeight72 вместо112; tests1262×568/768 GREEN. Независимое code review ACCEPT. Живое браузерное подтверждение новой версии ещё NOT_RUN.
- Защищённые пользовательские .beads/issues.jsonl, PROJECT_OVERVIEW_RU.md и старый flags checkpoint не включать в commit. Ресурсные очереди/ошибка Windows1450 пережданы без остановки чужих процессов.
