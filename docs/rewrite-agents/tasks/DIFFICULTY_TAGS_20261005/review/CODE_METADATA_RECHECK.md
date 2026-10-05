# Independent changed-scope recheck — 2026-10-05

Reviewer: same independent Codex review context `metadata_code_safety_review`, actual model gpt-6.1-sol/high. Rechecked fixes by Backend Terra and integration fixes by root against CONTRACT.md. Original CODE_METADATA_GATE.md remains unchanged. Reviewer wrote only this report; no source edits, tests, builds, Git, browser, children or deployment. Parent-supplied base HEAD remains a1fd8bf; these are working-file hashes, not an integration commit acceptance.

**Requirements verdict: REWORK, narrowly for PostgreSQL question-order shuffling and missing mandatory replay evidence. Code-quality verdict: REWORK for the question-order defect.** All eight original specific findings are addressed in the changed implementation. This does not certify PostgreSQL practice support, pinned Linux CI, full annotation coverage/application or publication.

## Original findings disposition

| Original finding | Recheck |
|---|---|
| 1. API difficulty_counts rejected by Flutter | RESOLVED. Catalog.fromJson (`api_models.dart:518`) admits optional counts with four required band keys, optional unknown, nonnegative integers, no extra keys and counts sufficient for returned questions. Absent counts still work; private fields remain rejected. New difficulty_test.dart includes server-shaped counts and invalid/private cases. |
| 2. PostgreSQL cannot select difficulty | RESOLVED for ranked API capability. Service now implements CatalogFor, StartQuiz, CatalogForDifficulty, StartDifficultyQuiz, StartRound and StartDifficultyRound. HTTP ranked difficulty assertion no longer requires a practice method. Shared SelectDifficulty filters the full pack; bundle identity remains intact. Runtime PostgreSQL execution is still pending. |
| 3. Whole-pack practice rejects omitted round | RESOLVED for SQLite practice. StartPracticeQuiz/StartDifficultyPracticeQuiz select all questions/all matches, and HTTP explicitly dispatches whole versus round practice. Unfiltered round-only providers keep their separate capability path. HTTP tests cover omitted-round practice, filtered whole practice and missing quiz rejection. PostgreSQL practice remains unsupported as before and must not be described as enabled. |
| 4. POST explicit empty difficulty accepted | RESOLVED. HTTP uses *string and rejects present empty while allowing absence. Existing predecode protection still rejects null/duplicate/case-aliased keys; new negative test includes the exact empty body. |
| 5. Go dictionary weaker than Python | RESOLVED for reported omissions. LoadTaxonomy now checks RU/EN labels and aliases, prefix/facet mapping with skill and ingredient-family exceptions, and missing/duplicate collection identity. Genuine rehashed negatives cover missing label, blank/duplicate aliases, prefix mismatch and duplicate collections. Go real frozen dictionary test validates the Python hash and 423 entries. |
| 6. Private facets marked safe | RESOLVED. Python and Go dictionary validators reject safe country/place/ingredient/cuisine/person tags; annotation/link validation independently rejects private facet context even with an in-memory dictionary. New tests cover this bypass. |
| 7. Browse loses difficulty band | RESOLVED. journey_pages.dart:145 builds the library URI with widget.difficulty; widget_test.dart now exercises Browse from a selected quiz error state. |
| 8. no_match becomes invalid_response | RESOLVED. Client ApiFailure accepts no_match and error-envelope.schema.json includes it. The DTO test verifies the server-shaped envelope. Existing UI error rendering remains generic; this disposition certifies preservation of the explicit response code, not a new custom no-match message. |

Docker now copies metadata/tags.v1.json to /app/metadata/tags.v1.json, matching config default and closing the earlier conditional annotated startup packaging concern. No image was built or deployed in this recheck.

## Remaining actionable code defect

**[P2] PostgreSQL rounds never shuffle their questions.** `next/server/internal/attempts/service.go:170` StartRound and `:184` StartDifficultyRound obtain QuestionRound, assign its copied source-order slice and call Start. `Start:209` calls `makeSnapshots`; `next/server/internal/attempts/rules.go:207-231` loops questions in input order and invokes the shuffler only on each snapshot's OptionOrder. Consequently every ranked PostgreSQL round exposes source-order question IDs. SQLite `collection.go:223` startQuestionRound explicitly shuffles question IDs within the chosen slice. This violates the frozen requirement to split filtered questions into rounds before shuffling within the selected slice.

Small adequate fix: after selecting the round, use an independent copy and the service's injectable shuffler to permute question IDs, validate its permutation, then call Start with that ordered slice. Do not shuffle the full pack before partitioning; retain the original source bundle identity and order public_question persistence to match snapshots. Add a deterministic reverse/shuffle test that proves PostgreSQL selected-round question order changes, stays in that slice, and leaves the catalog/full bundle unmodified. A helper-level test plus the tagged PostgreSQL test should verify actual stored positions. No execution reproduction was run here; the complete call chain proves absence of a question-order shuffle.

## Remaining required evidence and boundaries

- **Partially answered annotated attempt after source republish and taxonomy change is still NOT_RUN.** CONTRACT.md explicitly names this meaningful test, and the private metadata addition affects reconstructed hashes and persisted versions. Add a fixture that starts an annotated attempt, accepts at least one answer, republishes the same question IDs with changed numeric/context/editorial metadata and a different taxonomy reference, then submits/finishes/reveals the old attempt. Assert its original question revisions, metadata, bundle identity, correct grading and explanation remain pinned, and a new attempt uses the new content. The old operations must not consult the current dictionary. Source inspection remains reassuring; this is a missing required regression gate, not a proven replay bug.
- Shared rules_test.go now exercises 82 interleaved easy/hard questions, 41 matches, 20/20/1 partitions, no repeats, full union, no-match and source identity/catalog agreement. This closes the algorithm-level tail gap. SQLite difficulty_rounds_test still tests round zero against real persistence. Neither proves shuffled PostgreSQL persistence or a multi-round PostgreSQL catalog/attempt runtime agreement.
- PostgreSQL integration suites have `//go:build integration` and require QM_TEST_DATABASE_URL. Ordinary `go test ./...` excludes them. Shared ranked methods are reviewed and compile in local tests, but PostgreSQL DB behavior was not executed by those logs. The existing Flutter quiz journey always requests practice; PostgreSQL lacks practice/Feedback, so do not advertise the complete practice UI on PostgreSQL. This was pre-existing and a retrofit is outside this change's declared scope.
- Full 4078 annotation application/index/publication and independent review of all records remain pending. Parent reported source integrity unchanged and partial 2051 (later Food B pending combination); this reviewer did not recalculate annotation coverage or certify facts. Editorial flags and factual uncertainty remain meaningful.

## Verification evidence inspected

No unchanged tests were rerun. Read the actual saved outputs: `.run/quizipedia/go31-local-tests-fixed.txt` shows content/attempts/sqlite/httpapi PASS; `go31-full-tests.txt` shows full ordinary Go packages PASS; `go31-vet.txt` is empty and the root reports exit 0. Root supplied Go 1.27.0 Windows execution context, without policy bypass. Pinned Go 1.25 Linux and tagged PostgreSQL CI remain pending. The old report's NOT_RUN for new Go unit execution is superseded by this evidence, while PostgreSQL integration remains NOT_RUN.

Read `.run/quizipedia/client29-fixed-targeted.txt` (50 PASS), `client29-all-tests.txt` (96 PASS) and `client29-correct-analyze.txt` (No issues found). Parent reports Dart format 21 files/zero changes and Python new RED→11 PASS; these commands were not rerun here. New Python private-facet tests and changed validators were inspected. Windows logs are transient evidence; root must preserve durable summarized proof before integration/release.

Reviewed SHA256 hashes:

| File | SHA256 |
|---|---|
| metadata/quiz_metadata.py | 57A8D5818AB803BC6D56BBE34C4FB27A0A31A6A6995D16B307C9AAA2E7BFB59A |
| next/server/internal/content/taxonomy.go | 24C168667079CFF5B7388CD4313EAB64DF053A72CA8AA87B6EC8E8C4E804E330 |
| next/server/internal/attempts/service.go | 35D5158C4953291EAD51A8705F2A1AD09E73FF15A79B8D4004C19D171225BE0A |
| next/server/internal/attempts/rules.go | 938B8FBC5AD31579D4DB1FD73E671A3FB19FF13037D724695F2F62D12F3363DC |
| next/server/internal/httpapi/attempts.go | 47222C287C5B2D3C7CB26F80515FE42D4CC86AA4DDA44FF63CF7E8581F0D5E95 |
| next/server/internal/sqlite/collection.go | 90D2144A2F3FACC154E04555C95B5AA28268D1D7C4429DD53109A9B0E8788423 |
| next/apps/quiz_app/lib/api_models.dart | AD2702F40978F814D8B4AE0D5376061F60549E0B4248CCB393D3F4E7BDC118BA |
| next/apps/quiz_app/lib/journey_pages.dart | 667D4EC94666D2C5308DF4C307BF2F99F01CE2B7131796C951C9156CB0B7016B |
| next/infra/api/Dockerfile | 72CA53376C065412707AB9332144F4704FD95A5E5DD0D27A40571039A69E15C2 |

Status: DONE_WITH_CONCERNS. Root owns narrow fixes/evidence, issue reconciliation, durable report, actual integration commit/push and release. Independent changed-context review is not a cross-provider governance gate. Host bounded read lease lease-db2ed7d3cbd245d2b8a1a23987c83c8b was released before report lease; report lease release is recorded in tool evidence.
