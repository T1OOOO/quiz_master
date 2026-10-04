# Mobile question layout — 2026-10-04

User reported the gastronomy etiquette question with lower choices below the phone viewport. The existing question scroll view was working, but fixed quiz chrome plus spacious six-choice cards exceeded the available height.

## Reproduction and change

Regression tests failed before the fix at390×736 and360×640: the sixth/earlier choice was not hit-testable. Intermediate measured360×640 layout: quiz title y56..118; question card y208..679; scroll viewport y208..628. Each dense RadioListTile was44px plus6px wrapper padding, giving a50px outer control. The471px card exceeded its420px viewport.

The quiz title and round now share one flexible row. The separate48px library-link row is removed; shared Home and Back navigation remain available. Narrow screens use18px question text,16px choice text,12px card padding and4px choice spacing. Long content still scrolls, and system text scaling remains enabled. Desktop styling and answer IDs are preserved.

## Verification

- RED observed before production edits: both phone cases failed on clipped answers.
- Final `flutter test --no-pub --concurrency=1 --reporter expanded`: all72 tests PASS. Both phone cases assert all six full controls fit within the actual scroll viewport, each control is at least48px high, and selecting option6 submits stable ID `opt-6`. A320×568/text-scale2 long-answer case verifies scrolling and submission without layout exceptions. Existing media, keyboard, multiple-choice, feedback, study and desktop tests pass.
- `flutter analyze --no-pub`: no issues found.
- `flutter build web --release --no-pub --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --pwa-strategy=none`: exit0,61.2seconds. Existing deprecated PWA flag/unused Cupertino font notices remain.
- Independent `qm_reviewer` review approved requirements and all five code-quality axes after correcting viewport-bound assertions. Reviewer inspected source/tests only; lead executed the gates. This is independent-session review, not cross-provider acceptance.
- `git diff --check` for the changed client files: PASS.

## Production acceptance

Published pushed source `e7a7617f78b8d6d2fe96e2369ea87287e30b0106` as `quiz-2026.10.04-mobile-e7a7617`, Helm revision21, at https://quiz.kotopedia.org. Verified node `racknerd-f0269d5` /192.3.164.184, namespace/release `quiz-master`. Image `docker.io/library/quiz-master@sha256:19b8134c9d85614c056d4b1f3d181ac504d8e0ec124e4bdf3d80d8e4c8275dbb`. API SHA256 remains `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`; new JS SHA256 `d2d48f232230a9153f27aac5ef4fdcadeea736b0785f30d8fd3a173df89592c1` matched the public file. Catalog remains118/3878 and study6/120.

Package archive39,646,120bytes, SHA256 `722ae6ef657bc906867efbe2eda57c1520460a46ce728a90cbc209728e8e557c`. Runtime package/release log retained under `/opt/quiz-master/releases/quiz-2026.10.04-mobile-e7a7617`. The isolated release script pins baseline revision20's image, holds DEPLOY.lock, validates all file checksums, backs up/restores SQLite, builds runtime with network=none/pull=false, tests nginx, imports/tag-aliases image, lints/renders/server-dry-runs Helm and upgrades atomically. Successful invocation: `bash release-mobile.sh quiz-2026.10.04-mobile-e7a7617`. One earlier invocation omitted its required build argument and exited before deployment; corrected invocation completed exit0.

Deployment1/1, pod2/2 with zero restarts, original PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` retained; TLS certificate Ready True. Preflight backup `/opt/quiz-master/backups/quiz-2026.10.04-mobile-e7a7617.sqlite` and independent restored DB both integrity=ok, matching counts61 participants/581 attempts/119 bundles. Backup downloaded off-node and restored locally with the same integrity/counts. Rollback: `helm rollback quiz-master 20 -n quiz-master --wait`; retain the live PVC and later answers.

Actual public Flutter browser at360×640 and390×736: all six options displayed fully, each50px high; last choice bottom515px. Clicked the sixth choice, received the server-backed wrong-answer explanation, pressed Continue and verified question2/20. Also inspected1262×768 desktop screenshot. Browser errors empty. Screenshots under ignored `.run/mobile-layout-20261004/production-*.png`. Named browser closed and bounded renewal helper exited0. Language Learner remains revision85, shared edge11, with no writes to either.

Physical Android-device verification has not been run; existing Android issue remains open. Unrelated study wave3/content20/Beads changes are excluded from this fix.
