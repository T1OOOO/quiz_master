# Инвентарь cleanup для репетиций Bones

`rehearsal_cleanup.py` запускают только на `racknerd-f0269d5`. Без флага он
делает read-only inventory двух опубликованных stage-каталогов:
`quiz-2026.10.19-feedback-5df1d538` и `quiz-2026.10.19-books-8954b166`.
Ни сборку, ни публикацию, ни удаление image он не выполняет.

Перед inventory проверяются публичные build/API/ready, Helm 68 и Deployment 66,
оба контейнера с образом Books, PVC, retained Helm 67 для rollback, node
Ready/DiskPressure, imageFS не ниже 20 %, валидность SQLite backup и совпадение
prepared/reviewed receipt с закреплёнными digest. Inventory также отвергает
активный Docker/CRI reference на stage-путь, не печатая environment контейнеров.

Для каждого stage разрешены только семь disposable путей: `base.api`, `new.api`,
`base-quizzes`, `candidate-quizzes`, `restore-proof.sqlite`,
`publish-restore-proof.sqlite` и `rehearsal-data`. Каталог должен быть literal
`/opt/quiz-master/releases/<build>`, root:root 0700, без symlink; все удаляемые
деревья предварительно обходятся без symlink. Web, API, chart, manifest,
receipts, backup и images не являются target.

`--execute` предназначен только после независимого review. Он берёт
`/opt/quiz-master/DEPLOY.lock`, повторяет полный inventory уже под lock и удаляет
ровно 14 literal paths. Затем повторяет state/PVC/health/node/imageFS и проверяет,
что receipts, backup и stage-каталоги сохранены. Никаких broad prune, `rm -rf`
по строке, image delete или stage directory delete нет.

Планируемая read-only команда:

```bash
python3 rehearsal_cleanup.py
```

В этой задаче команда на сервере не выполнялась.
