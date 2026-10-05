# Final independent changed-scope code review — 2026-10-05

Reviewer: `metadata_code_safety_review`, independent implementation-review context, actual Codex gpt-6.1-sol/high. Issues quiz_master-qr4.1 / qr4.2. Parent supplied base HEAD a1fd8bf; reviewed hashes below describe working files, not a final integration commit. Previous CODE_METADATA_GATE.md and CODE_METADATA_RECHECK.md remain unchanged. This final review covers only the new question shuffler/service helper, new SQLite replay regression, tagged PostgreSQL round regression, CI package addition and the previously unresolved boundaries. No production edits, tests, builds, Git, children, browser, deployment or publication were performed by this reviewer.

**Code-quality verdict: ACCEPT for the reviewed changed scope; no actionable findings. Requirements verdict: CONDITIONAL ACCEPT for metadata/selection implementation and regression-test design, pending exact-commit quality gates and tagged PostgreSQL runtime on pinned CI.** This is not final issue/release acceptance. The implementation defects recorded in the two preceding reports are resolved; previously accepted eight fixes were not redundantly re-reviewed.

## Remaining defect disposition

PostgreSQL question order is now correctly shuffled inside the selected round. `next/server/internal/attempts/service.go:175` and `:193` call `shuffledRound`; `:202-207` first obtains the copied partition with QuestionRound, then calls ShuffleQuestions with the service's injected shuffler. `rules.go:72-100` builds an independent ID list, rejects duplicate/empty input IDs, validates that the shuffled output contains every original ID exactly once, and returns a fresh ordered question slice. Start persists public questions and snapshots using that same ordered slice. It retains the full source bundle version/hash/private grading and does not alter the catalog. No shuffle-before-partition or option/question order mismatch remains.

`TestServiceShuffledRoundPermutesOnlyItsSelectedSlice` uses deterministic reverse order on round one of 41 questions, expects q-39 through q-20, checks original source order, and rejects a duplicated shuffled ID. The actual saved targeted log shows it PASS. The new tagged PostgreSQL test additionally checks persisted positions and snapshots, so its future CI execution will test the full call path rather than merely the helper.

## Required replay coverage disposition

`next/server/internal/sqlite/metadata_replay_test.go` now supplies the mandatory partially answered annotated-attempt regression. It imports two real raw questions through the production collection path, starts an attempt and accepts the first answer. Replacement content keeps question IDs but changes numeric difficulty 2→9, band, public context/private editorial tags, taxonomy ID/hash (disjoint tag IDs), stems, option text, keyed answer and explanation. A new attempt is checked against the replacement revisions/metadata.

The test removes the raw source and both old/new dictionary files, proves LoadTaxonomy fails for the removed current dictionary, then uses the replacement service to replay the original receipt, submit the second old answer, finish with 2/2 and reveal the old keys/explanations. Stored bundle (including original private metadata/taxonomy), public questions, revisions, option snapshots/mappings and positions are compared to the originals. Changing the keyed answer makes accidental new-bundle grading observable. This is meaningful runtime evidence for the actual SQLite collection path and closes the prior missing regression gate there. It does not claim PostgreSQL replay execution or validation of all historical archives.

## PostgreSQL test and CI disposition

`next/server/internal/attempts/difficulty_rounds_integration_test.go` constructs 82 interleaved easy/hard questions through a valid controlled bundle and NewService, creates a real participant, and verifies the filtered catalog/whole attempt contain all 41 easy questions. Injected reverse order must yield 20/20/1 round slices, with every catalog question exactly once. Actual database rows are checked by position for question/revision columns, public numeric metadata, snapshots, reversed options and mappings. Attempt/catalog identity must remain the original bundle identity; full catalog must remain unchanged; past-tail and no-match cases are rejected.

The test remains `//go:build integration`; compile-only success with `-run '^$'` is explicitly **not PostgreSQL execution**. `.github/workflows/quiz-v2-ci.yml` now includes internal/attempts in the existing isolated PostgreSQL suite with `-p 1 -count=1 -tags integration`, after migrations/identity/store, using Go 1.25.0 on Ubuntu. Serial package execution is appropriate for the shared isolated test database. No defect found in this CI addition. Actual CI runtime and exact pushed commit verification remain pending.

## Evidence inspected, not rerun

- `review/REPLAY_PG_TESTS.md` accurately distinguishes PASS from compile-only and describes the initial expired-lease compile incident and exclusion of that log. It records the subsequent fresh granted lease, corrected renewal guard, accepted rerun and release. This review relies on the accepted rerun, not the excluded output.
- `.run/quizipedia/replay-targeted-valid.txt` shows SQLite `TestAnnotatedPartialAttemptPinsMetadataAfterRepublish` PASS (0.16s), shared filtered partition test PASS and selected-slice shuffle test PASS, ordinary packages exit PASS. This is Go 1.27.0 Windows evidence as recorded by the worker/root.
- `.run/quizipedia/replay-pg-compile-only-valid.txt` shows attempts PASS with `[no tests to run]`; only compilation/linking is attested.
- Prior final-scope Go full-suite/vet checks must be refreshed by root after stable changes; previous go31 results predate these last files. Root reported fresh Python 11 PASS, contract checker 37 negatives/3 positives/7 scoring PASS and partial 2276 source-integrity PASS. Flutter 96/analyze evidence remains unchanged and valid for unchanged client code. These were not rerun here and do not establish full-corpus editorial acceptance.

## Reviewed working-file identity

| File | SHA256 |
|---|---|
| next/server/internal/sqlite/metadata_replay_test.go | D722B668588306F4237C718B4E50F07E6818258B87E42C5A74AD2E0796167F62 |
| next/server/internal/attempts/difficulty_rounds_integration_test.go | 6B8B95F0990F7BE949D8600DC1DA17B82C49A919C0EE3C49337470E75DCA73BE |
| next/server/internal/attempts/service.go | F9F5E64E9208F65DF5FCE7E5174C35F7D22F2607E27EBBF4E6669CFCD400B8AA |
| next/server/internal/attempts/rules.go | 4CAF6AF1E3247B1D5C2D2F7146A1DE790DF7B0A4C9831E53CE5961436D43EB11 |
| .github/workflows/quiz-v2-ci.yml | 9963E8DDB62522E64C5276D8F9FCBE6C4E73B4840EFBADDE389BC7C1ECE540AC |

## Conditions and handoff

Root must run the stable full Go suite/vet, commit only reviewed authorized changes, push successfully, and verify pinned Go 1.25/Linux and the actual tagged PostgreSQL test on that commit before claiming those gates PASS. PostgreSQL practice/Feedback support remains a pre-existing unsupported mode; this review accepts ranked selection and does not certify the complete practice UI on that provider. Full 4078 annotations, factual certification of all entries, source metadata application, deterministic full private index and metadata publication remain outside this completed code review and pending in the larger task. This Codex independent-context review is not a different-vendor review claim.

Handoff: DONE_WITH_CONCERNS (review complete; runtime CI/release gates pending, no unresolved actionable code defect). Root owns issue status, integration/push, durable test summaries and release. Host read lease lease-3146e152b9954ad9b38b8554e83370c2 was released before writing this report; report lease release is recorded in tool evidence. Reviewer changed only this new file.
