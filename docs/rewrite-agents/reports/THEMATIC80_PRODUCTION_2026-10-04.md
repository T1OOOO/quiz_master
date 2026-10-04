# Thematic80 — verified production release

Published at **https://quiz.kotopedia.org** as `quiz-2026.10.04-thematic-61b47ea`, source commit `61b47ea85f6843e43b7b2fad6bab88c0eb45c37a` (pushed to `origin/codex/quiz-v2`). Public discovery and server loading contain **126 packs / 3958 questions**, including eight new thematic packs /80 questions. Study remains6 modules /120 questions.

## Release identity and preparation

Confirmed existing target: `racknerd-f0269d5` / `192.3.164.184`, namespace/release `quiz-master`. A fresh preflight verified Helm revision21 and the previous mobile image. Deployment used the existing exclusive `/opt/quiz-master/DEPLOY.lock`, checked that baseline image again, verified the staged file checksums, used the pinned nginx base, tested nginx in a read-only disposable container and ran Helm lint/template/server dry-run before atomic upgrade.

The already verified mobile Web and API binaries were reused byte-for-byte. Only accepted raw sources, canonical packs, discovery metadata and release metadata were added. No Flutter or API implementation changed during this release; the mobile layout fix is retained.

- API SHA-256: `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`.
- Web JS SHA-256: `d2d48f232230a9153f27aac5ef4fdcadeea736b0785f30d8fd3a173df89592c1` (public JS hash also checked by the release script).
- Uploaded archive:39683215 bytes, SHA-256 `aa87d3775d0ccec057cce185b584ac7072481d055b07dc21bbe26cc68ed16937`; the remote archive hash matched.
- Resulting immutable image: `docker.io/library/quiz-master@sha256:cdfd63ef1d2027e963606a447f8296559848a703219c4a415f86f61395516c46`.
- Remote retained package: `/opt/quiz-master/releases/quiz-2026.10.04-thematic-61b47ea` with exact runtime inputs, checksums and release script.

## Backup and rollback

Before upgrade, the online SQLite backup and an independently restored database both passed integrity_check and reconciled **63 participants /584 attempts /119 attempt bundles**. Backup: `/opt/quiz-master/backups/quiz-2026.10.04-thematic-61b47ea.sqlite`. It was also downloaded off-node and independently restored locally, again integrity=ok and the same counts. These are preflight snapshot counts; normal public/smoke answers after the backup legitimately add records.

Rollback: `helm rollback quiz-master 21 -n quiz-master --wait --timeout 180s`. Retain the existing live PVC and subsequent answers. This content-only release performs no database schema migration. Database replacement is not part of normal image rollback.

## Executed public acceptance

Helm revision22 is deployed; deployment1/1 and pod2/2, zero restarts. Original PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` remains Bound. TLS certificate Ready=True. Neighboring language-learner-app revision85 and edge revision11 were unchanged in before/after snapshots. A transient503 occurred during the chart's Recreate rollout; readiness and public version subsequently passed.

The actual public API verification created a normal disposable guest and completed one ten-question attempt for each new pack:

| Pack | Verified questions | Server score | Reveals |
| --- | ---: | ---: | ---: |
| DreamWorks | 10 | 10 | 10 |
| Game of Thrones | 10 | 10 | 10 |
| Game worlds | 10 | 10 | 10 |
| Harry Potter | 10 | 10 | 10 |
| Pixar | 10 | 10 | 10 |
| Star Wars | 10 | 10 | 10 |
| Terminator | 10 | 10 | 10 |
| TV series | 10 | 10 | 10 |

For every question, the public stem and four ordered options matched the accepted source; the chosen canonical option matched the original numeric key and the attempt snapshot. Each finish returned score10 and ten history entries. Before finish, public questions omitted grading/answer/explanation and early reveals returned404. After finish, all80 revealed correct texts and explanations matched the accepted sources exactly. The metadata catalog contains only its five allowed fields and reconciles126/3958. Public version exactly matches the staged release.

[Integration evidence and independent editorial/code reviews](THEMATIC80_INTEGRATION_2026-10-04.md) record the passing import/mapping/content/catalog checks and the explicit full CLI test limitation. Follow-up `quiz_master-jwz` remains open for normal Windows/isolated-Linux toolchain execution; the blocked full CLI suite is not claimed to pass. Existing unrelated content/study drafts and the old-bank answer-option correction ticket remain separate work.
