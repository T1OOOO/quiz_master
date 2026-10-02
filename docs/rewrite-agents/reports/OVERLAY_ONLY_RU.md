# Результат только поверх вопроса

Release `quiz-2026.10.03-0245-6b5e2e6`, commit `6b5e2e693b089d071c482c71cf722f8ba3f4f0b0`,
Helm revision 11, 2026-10-03 02:45 Europe/Istanbul.

Причина скачка: _QuestionStep добавлял после ответа строки результата и управления
таймером в Column, уменьшая Expanded с вопросом. Теперь эти строки удалены;
результат и ExplanationPanel находятся в центральном модальном окне. Для single/
text practice убран и исходный неактивный Continue. Multi-choice/legacy submit
остался на постоянном месте и не добавляется после ответа.

Оба исхода открывают окно. Верный: 3 секунды до следующего, пауза/возобновление
в окне. Неверный: ручное продолжение. Закрыть/Продолжить переводят к следующему
вопросу; случайный клик вне окна и Back не оставляют отвеченный вопрос без выхода.
Таймер принадлежит окну, отменяется при закрытии/уничтожении; уход в неактивное
состояние или перекрытие маршрутом ставит его на паузу. Дополнительных запросов
проверки ответов нет; API и контент не менялись.

TDD: обновлённый тест сначала упал (нет Dialog после правильного ответа).
После исправления весь suite: 46 PASS; flutter analyze: no issues; Web release PASS.
Тесты измеряют неизменный Rect QuestionCard до/после ответа, включая 390×640.
В браузере 390×640: верно → объяснение → пауза → возобновление → 2/20;
1280×900: неверно → центральное объяснение → закрыть → 3/20.
Нижних result/continue панелей нет; фон и координаты карточки остались прежними.
Просмотрены все четыре снимка `overlay-*.png`; browser errors пустой.
Practice HTTPS smoke PASS: owned receipt/reveal, no-store, unanswered/future/foreign
404, invalid mode 400. Android и независимое cross-provider ревью NOT_RUN.
Сборка сохраняет прежние предупреждения pwa-strategy/CupertinoIcons.

Image: `docker.io/library/quiz-master@sha256:35154cc5b3a5706dab2a2f64e84698ae2e780192aeb4cd15c980251a29501d6e`.
Actual/public JS SHA256: `e742f9b48b35b497f8f5fbf2b178c9f3540906cac5c03127fcdb98f59c180242`.
API SHA256: `5c6558fc37e42f08fbf25d255f619d340bb42d3fb57f97f7d3a6c0b19379b1ba`.
Оба совпадают с version.json. API/CanvasKit/assets переиспользованы: сравнены все
файлы новой Web-сборки с предыдущим пакетом, переданы только изменённые JS,
icon-font, служебный build ID и версия. Предыдущий remote release сохранён.
Runtime build remote-only network=none/pull=false, nginx -t/Helm lint/dry-run PASS;
atomic rollout 1/1, pod 2/2, 0 restarts; существующий PVC неизменен, TLS Ready True.
Backup + separate restore-proof: integrity ok, counts 35 participants / 436 attempts /
102 bundles, `/opt/quiz-master/backups/quiz-2026.10.03-0245-6b5e2e6.sqlite`.
Rollback: `helm rollback quiz-master 10 -n quiz-master --wait`, без восстановления
или удаления live DB. Language Learner revision 85 не менялась.

Без новых агентов, зависимостей, локального Docker/Postgres или GitHub Actions.
Факты в объяснениях не перерабатывались: редактура dhu, cold-start ky5 и полная
React/Android parity остаются незавершёнными отдельными задачами.
