# Study release evidence — 2026-10-04

Validated scope: four accepted introductory modules, 80 source-backed local unranked questions and four real article illustrations. Separate question artwork and the future 58-chapter roadmap are not shipped as completed work.

Owner checks: Python builder parity PASS; seven reader regressions PASS both normally and under `-O`. Final Flutter full suite: **69 tests PASS**, including 14 study cases. Analyzer: **No issues found**. Independent source/content and code-quality/requirements reviews APPROVE, with frozen hashes in the review reports.

Actual desktop browser checks on the release build found an incorrect library image fallback and light headline on parchment; dedicated hero assets and explicit warm dark ink were corrected with failing-before/passing-after regressions. Final release build PASS (50 seconds). Isolated local browser session: cards open the article, practice starts with 20 questions, wrong answer displays a centered explanation/cited source, Enter on focused Continue advances. Desktop 1262×568 and phone 390×844 screenshots were inspected for readable text, illustrations and horizontal fit (library/article/question/feedback). Evidence PNGs are generated in ignored `study/site/`, not a production screenshot or complete accessibility audit.

No Android device acceptance, complete accessibility audit, local Docker/PostgreSQL or GitHub Actions claim is made. The existing server/API binary is unchanged and its SHA256 was independently checked against the running container: `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`.

## Production observed

Release `quiz-2026.10.04-study-5536e77`, source commit `5536e777139018bae2b244bfe7a586e73f5d5543`, Helm revision **19**. The independent release-script review APPROVE includes explicit version checks that remain enforced with optimized Python; matching and mismatched inputs were tested under `-O` (accept/reject respectively).

Node `racknerd-f0269d5`; isolated namespace/release `quiz-master`. Imported image `docker.io/library/quiz-master@sha256:6fd3e6d90203198b5a03975d9b3b6387821b504ae20a1bf63212ac8afd044b59`. API binary reused unchanged. Runtime-only remote image assembly used network=none/pull=false; nginx validation, Helm strict lint, server dry-run and lock-protected atomic upgrade PASS. Deployment 1/1, pod 2/2, zero restarts. TLS certificate Ready True; existing PVC `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` preserved.

Online backup and independent restore proof: `/opt/quiz-master/backups/quiz-2026.10.04-study-5536e77.sqlite`, integrity=ok, restore=ok; counts 54 participants / 457 attempts / 118 bundles. On-node proof only, not off-node disaster recovery. Prior revision18 remains the application rollback target; no live DB restoration performed.

Public version JSON equals packaged metadata and requested build; public main.dart.js SHA256 equals `f4a26be4767faec41d63ef5efc298ce35f3cd094547b9e82bcf47a17aaa23a0b`. Every one of **118 selected API catalogs** matches its public ID/question count: **3878 questions**. The separate public study catalog has four modules/80 questions. Existing API practice smoke PASS: receipt/explanation/correctness match, unanswered/future/foreign feedback404, no-store, invalid mode400. Initial catalog smoke had a PowerShell nested-array harness error; direct array assignment corrected the harness, then all118 passed.

Actual public browser: study library → nature article → practice → wrong answer/explanation/source opened through native clicks; desktop and phone modal screenshots inspected, no browser errors reported. Local final browser additionally checked keyboard Continue, correct one-second advance, TOC scrolling and Home; local-reader smoke checks all80 answer mappings, explanations, scores and malformed hashes. Screenshots remain in ignored `study/site/production-*.png` and `flutter-*.png`. The owned session was closed; other browser sessions were not touched.

Language Learner app revision85, frontend `frontend-2026.10.02-1921-da0ca89b076` and JS hash `520c6508fc7c9457b684c2d3210ae15322bdc2e9d1faf35b319958f55fbe66c7` unchanged; shared edge revision10 unchanged. Its existing 1/1 deployments remain ready (NLP intentionally0/0). No neighbor source/DB/edge writes.

Follow-ups: `quiz_master-5gh` individual-question images, `quiz_master-ek9` future chapters, `quiz_master-y6p` real Android acceptance. Initial content and Flutter integration issues closed. Unrelated Beads/content20 changes preserved locally; only owned issue records are included in this handoff.
