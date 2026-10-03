# Content20 integration checkpoint

Task quiz_master-8k1.16 remains in progress. Target: 20 new banks / 400 questions.

Local accepted/imported: paintings20, 20 questions. Architecture is an unaccepted partial draft (10 actual questions); other 18 banks have not been written. New400 wave published: zero. Production remains revision18, 117 packs / 3858 questions; local catalog is 118 / 3878.

Editorial FINAL ACCEPT: CONTENT20_REVIEW.md, paintings20 candidate SHA BDD02F0DEBDADA048864E1CCC326B6A4E4F1FD7D2A041D4842BE4765DBB9CFE7. Imported into quizzes/Preparation/prep_wave20_paintings.json and next/content/prep-wave20-paintings. Bundle SHA 36f2aa741de00ddb8afd65b842492ddae0aa4fb3f401b464f5366d7e881ab867; normalized source SHA c30ed21d66b8edc52ee1eac9a8809b247e0a6ebdc4f9d02df981136450e9f26c.

Fresh verification, 2026-10-03:

- quizctl import/validate/build/validate: PASS (20 questions).
- Current go run ./cmd/quizctl catalog: PASS, 118 packs. The older ignored .run/quizctl-preparation.exe could not generate this catalog; current source CLI succeeded. Do not reuse the old executable as current-code evidence.
- go test ./cmd/quizctl -run TestCatalog -count=1 -p=1: RED at old expected117/actual118; counts updated to118/3878. Then go test ./... -p=1: all packages PASS, SQLite32.390s, GOMAXPROCS2.
- go vet ./...: PASS, GOMAXPROCS2.
- flutter test --no-pub --concurrency=1: all55 PASS.
- flutter analyze --no-pub: no issues.
- powershell -NoProfile -File reports/verify-content20.ps1: PASS for all20 answer mappings, stems, options, explanations, normalized source SHA, public-field boundary and metadata catalog118/3878. Initial helper checks caught implicit Windows PowerShell encoding and array wrapping; fixed explicitUTF8 and direct array assignment, fresh PASS.

No new Flutter build, live deployment or browser test is claimed for this wave. Reuse current verified JS only for a content-only release after the complete accepted batch; update metadata/source/canonical packs together, back up SQLite before upgrade, preserve historical attempts and the existing PVC. Never publish architecture partial files.

Independent integration check: pending.

## Independent paintings20 integration check — ACCEPT

Reviewed 2026-10-03, read-only and limited to the frozen paintings20 integration paths. `powershell -NoProfile -File reports/verify-content20.ps1` returned `PASS: reviewed source, normalized hash, all 20 canonical answers/options/stems/explanations, public boundary, catalog 118/3878`.

I independently repeated the mapping audit across every ID `wave20-paintings-001` through `-020`, rather than relying only on the checker. For each item, the reviewed legacy question equals `quizzes/Preparation/prep_wave20_paintings.json`; both canonical draft and bundle preserve the ID, stem and all four option texts; their keyed option ID agrees with the source `correct_answer`; and the manifest preserves the source explanation. All 20 rows passed. The corrected option-ID mapping is balanced as expected and includes, for example, 001→`opt-2`, 004→`opt-4`, 011→`opt-1`, 018→`opt-3`, and 020→`opt-2`.

The raw draft file is intentionally not byte/object-equal to the source quiz: it is the canonical contract representation (`question_id`, `stem`, option IDs and private grading), not a copied legacy payload. Field-level preservation passed. The public bundle questions expose neither `grading` nor `explanation`; answer mappings stay in its private-grading section, while the manifest retains explanations for validation.

Catalog audit passed: 118 entries, summed `questions_count` 3878, and `prep-wave20-paintings` has 20 questions. The manifest normalized source SHA is `c30ed21d66b8edc52ee1eac9a8809b247e0a6ebdc4f9d02df981136450e9f26c`.

**ACCEPT — bounded paintings20 integration consistency only.** This verifies the current frozen 20-question path and public/private answer boundary. It does not claim completion of the 400-question wave, a full release, deployment, or publication. The earlier Go/vet/Flutter evidence above remains lead-recorded evidence and was not rerun in this read-only content check.
