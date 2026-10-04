# Wave2 production release — 2026-10-04

Published at https://quiz.kotopedia.org after the user's explicit production request. Source commit `3ebba4e6908ae314d966f6d53a5e11bc65486950`; build `quiz-2026.10.04-study-3ebba4e`; Helm revision20. Six accepted study chapters/120 questions include the new evolution and map-reading articles. Ranked catalog remains118 packs/3878 questions. Independent content and integration acceptance is recorded in the existing wave2 reviews.

## Fresh verification

- `python study/build.py --check --flutter` and its optimized `-O` execution: PASS6/120.
- `python -m unittest discover -s study -p check_reader.py`, repeated with `-O`: seven tests PASS each.
- In `next/apps/quiz_app`, `flutter test --concurrency=1 --reporter expanded`: all69 tests PASS, including six actual chapters/120 questions/loadable heroes.
- `flutter analyze --no-pub`: no issues found.
- `flutter build web --release --no-pub --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --pwa-strategy=none`: exit0,52.8seconds. Existing deprecated PWA/unused Cupertino font notices; build succeeded.
- Local staged Flutter browser: six illustrated library cards, maps article/question/wrong-answer explanation/manual Continue, evolution article. Actual1262×768 and390×844 screenshots inspected. Browser errors empty.

## Exact deployment

Strict known-host SSH verified node `racknerd-f0269d5` / `192.3.164.184`, context `default`, namespace/release `quiz-master`. Previous revision19/build5536e77/image6fd3e6d checked before mutation. Source diff from5536e77 for `next/server`, `next/contracts`, `quizzes`, and chart is empty, so the API was reused and independently hashed against the running container.

Archive `.run/quiz-2026.10.04-study-3ebba4e.tar.gz`,39,537,434bytes; SHA256 `0c11242680eeb6bbbe323ee1f2a68c60804e26d4961c36173d148a6018ba0677`. Explicit runtime parts only; private quizzes/contracts are outside public `web`. Remote archive and all213 file checksums matched before execution.

Remote commands from `/opt/quiz-master/releases/quiz-2026.10.04-study-3ebba4e`:

```sh
python3 backup_sqlite.py /opt/quiz-master/backups/quiz-2026.10.04-study-3ebba4e-preflight.sqlite
bash release-study.sh quiz-2026.10.04-study-3ebba4e > release.log 2>&1
kubectl get deploy,pods,pvc,certificate -n quiz-master
```

The release script held `/opt/quiz-master/DEPLOY.lock` across exact baseline verification, online SQLite backup, network=none/pull=false runtime build, nginx configuration test, containerd import/digest alias, strict Helm lint, server dry-run, atomic Helm upgrade/wait and public identity/JS hash checks. Exit0. Dry-run emitted existing Helm-resource last-applied annotation warnings; actual kubectl apply was not used.

Image `docker.io/library/quiz-master@sha256:5bc19e3f7f05176a68bdd56e3426ef45e030fd982a2d86105b72edcde40fc71b`. API SHA256 `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`; JS SHA256 `f4a26be4767faec41d63ef5efc298ce35f3cd094547b9e82bcf47a17aaa23a0b`. JS is unchanged because this wave changes bundled content/assets rather than application logic.

Both preflight and lock-protected backups/independent restored copies: integrity=ok,56 participants/458 attempts/119 historical bundles. Preflight backup was downloaded to ignored `.run/study-release-3ebba4e/offnode-backup.sqlite` and restored independently as `offnode-restore-proof.sqlite`; integrity/counts matched before upgrade. This is a verified off-node recovery copy, not automated backup retention/monitoring.

Revision20 deployed; Deployment1/1, pod2/2 Running, zero restarts; TLS certificate Ready True. Original PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` retained. Rollback: `helm rollback quiz-master 19 -n quiz-master --wait`; preserve live PVC/new answers, do not restore an older DB over later answers.

## Public acceptance

Public version JSON and JS hash match packaged metadata. Exact byte comparison passed for both catalogs and both new hero PNGs. Study catalog SHA256 `4652506857c1b581f31d54f61758fd77f5c072d92a3e82d753a7c2899453fdee`; maps hero `82b95f992fad2032028f8b7fa4f6aa5ec1863b969ad6aadddb0da4a64176fe5a`; evolution hero `89acee1e376269d721130a85b4556840e5314597f1f2ec77f1c77613548c1241`.

The existing `deploy/quiz-preview/smoke.ps1` has older hardcoded identity/counts. An ignored copy at `.run/study-release-3ebba4e/smoke-current.ps1` changes only those expectations to build3ebba4e/118/3878 and camel-case `buildId`. `pwsh -NoProfile -File` ran this full harness successfully: all118 selected catalogs and attempt starts;3878 question counts;19 accepted answers/finished attempt/history/reveals; stable idempotent receipt; foreign-owner404;20+5 unique round partition; invalid round400. `practice-smoke.ps1` also passed: feedback/explanation/correctness, unanswered/future/foreign404, cache=no-store, invalid mode400. Only disposable smoke records were created; credentials were not printed.

Actual public native clicks checked six-card library, maps article/practice/wrong-answer centered explanation/manual Continue and evolution article/practice. Desktop1262×568/768 and phone390×844 screenshots under ignored `.run/study-release-3ebba4e/production-*.png` were inspected. The first immediate library capture preceded image loading; later `production-library-loaded.png` shows all six real heroes. Browser error output empty. Owned named Chromium session and local HTTP server closed.

Read-only before/after checks: Language Learner app revision85, frontend `frontend-2026.10.02-1921-da0ca89b076`, hash `520c6508fc7c9457b684c2d3210ae15322bdc2e9d1faf35b319958f55fbe66c7`; shared edge revision11. Edge had already advanced from the earlier report's revision10 before this session; this release changed neither neighbor nor edge. No local Docker/PostgreSQL/Actions or additional agents were used.

Physical Android, complete accessibility audit and load acceptance were not run. Existing follow-ups remain `quiz_master-y6p` (Android), `quiz_master-5gh` (question artwork), and `quiz_master-ek9` (future chapters). New follow-up `quiz_master-5yz` tracks reconciling the historical README and parameterizing the old smoke expectations. Deployment follow-up `quiz_master-ukk` is completed. Pre-existing shared Beads/content20/overview changes are preserved; only these two issue records and release evidence belong to the handoff commit.
