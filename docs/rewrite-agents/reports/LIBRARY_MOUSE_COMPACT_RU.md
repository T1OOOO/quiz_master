# Прокрутка мышью и компактная библиотека

2026-10-03, задача quiz_master-1vo. Код 420849f68746814bdc8bb604ff436fc21d9d6e59.
Выпуск quiz-2026.10.03-library-420849f, Helm revision 13.

Использована стандартная ScrollBehavior с добавлением mouse к существующим
dragDevices. Карточки и шапка библиотеки компактнее при высоте окна <720;
сохранены изображения, названия, навигация, клавиатура и прокрутка длинных списков.
Это не гарантия размещения всех категорий при любом масштабе текста/высоте:
в меньших окнах и при увеличенном шрифте список остаётся прокручиваемым.

- TDD: на прежнем коде категории выходили за 576/640px, mouse drag оставлял offset0.
- После первой правки phone оставался на6px ниже окна; обложка сокращена до40px.
- flutter test --no-pub: 49 PASS. flutter analyze --no-pub: No issues found.
- flutter build web --release --no-pub --no-wasm-dry-run --pwa-strategy=none
  --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org: PASS.
  Известные предупреждения pwa-strategy/CupertinoIcons, новых ошибок нет.
- На сервер переданы только JS/bootstrap/FontManifest/version. API/контент неизменны.
- Remote runtime build network=none/pull=false, nginx -t, Helm lint/server dry-run,
  atomic rollout PASS. Pod2/2,0restarts; исходный PVC сохранён.
- Backup/restore integrity ok:40participants,441attempts,102bundles.
  /opt/quiz-master/backups/quiz-2026.10.03-library-420849f.sqlite
- Публичный JS SHA256 совпадает с production сборкой:
  2a957994dcf86ca0ac7eb9e7a21d0694a834f908bda2ae1f10786e1be88191d1.
- Браузер1262x576/390x640: все7категорий видны; клик открывает Гастрономию;
  последовательный mouse drag прокручивает список. Первый одиночный mouse move
  принимал жест без следующей дельты; повторная проверка с несколькими движениями
  показала реальную прокрутку. Ошибок браузера нет, собственный браузер закрыт.
  Снимки library-phone.png/library-mouse-drag.png просмотрены.
- Самопроверка: стандартные API без новых зависимостей, нет изменений авторизации,
  grading, источников и DB. Независимое ревью и Android NOT_RUN, не заявлены PASS.

Image docker.io/library/quiz-master@sha256:1f48ae5746b4314097d5f51d60a9841bfc17a092ee32be8df9ce955d3b39c68e.
Rollback helm rollback quiz-master 12 -n quiz-master --wait; liveDB не откатывать.
Новая библиотека вопросов ещё не опубликована; задачи c1e/xiw возобновляются отдельно.
