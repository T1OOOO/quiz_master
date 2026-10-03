# Культурная библиотека: проверенные 200 вопросов

Дата: 2026-10-03. Статус до выкладки: ACCEPT, локальный каталог 115 наборов / 3798 вопросов. Живой сервер пока revision 16 / 106 / 3598; статус публикации обновляется только после реальной проверки.

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

PENDING. Цель — тот же проверенный racknerd-f0269d5 / 192.3.164.184, namespace quiz-master, существующий PVC. План: online SQLite backup + isolated restore, pinned runtime/API image, Helm atomic upgrade, живые API/catalog/assets SHA и браузерные сценарии. Rollback revision 16 без восстановления старой БД поверх новых ответов. Локальные Docker/PostgreSQL и GitHub Actions не использовались.
