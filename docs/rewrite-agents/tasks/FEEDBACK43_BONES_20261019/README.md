# Подготовка frontend-only выпуска Bones

Этот пакет готовит выпуск после Books: ожидаемая исходная точка — Helm 68,
Deployment 66, build `quiz-2026.10.19-books-8954b166` и образ
`sha256:dd7166c8690a2009f6b6fa5ae6b8145f6328c93fd0b8e1d450cbe9de83b4ef13`.
Ни один скрипт здесь не запускает удалённые действия без явных флагов
`--execute --acknowledge-production`; перед этим нужен свежий preflight,
подтверждающий эти значения.

Выпуск содержит только клиентские изменения для 206 костных сущностей и
связанных материалов. Серверный API переносится из baseline побайтно:
`208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa`.
Новый tag имеет вид `quiz-2026.10.19-bones-<SHA8>`; `version.json` отмечает
`frontend_only=true`, `api_build_id=quiz-2026.10.19-books-8954b166` и исходный
API commit `8954b166a872cb8e4ffbe856981e730c2260f30d`.

Во время prepare контроллер сравнивает все 148 файлов `/app/quizzes` у
baseline и кандидата как набор путей и SHA-256 байтов. Любое добавление,
удаление или изменение прерывает выпуск. Приватный `book-quiz.json` с 42
вопросами передаётся только в HTTP-репетицию: он не копируется в image.
Репетиция проверяет 42 правильных ответа и одну неверную попытку, привязки
305 статей к revision, snapshot/receipt/score, а также прежний smoke-тест.

Выпуск сохраняет проверки node Ready/DiskPressure, imageFS не менее 20%, PVC,
backup/restore SQLite, receipt между фазами, канонический CRI digest, Helm
dry-run, rollback на revision 68, публичные version/JS/health и неизменность
feedback. Число фактов передаётся в `prepare_package.py` явным
`--quizipedia-facts`; оно не зафиксировано в этом пакете.

Пакет не выполняет сборку, публикацию или очистку хранилища.
