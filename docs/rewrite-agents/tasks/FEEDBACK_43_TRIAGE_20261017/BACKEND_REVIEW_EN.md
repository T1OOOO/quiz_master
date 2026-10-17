# Backend review — shuffle and replay WIP

**Reviewer:** feedback43-backend-review-20261017
**Review mode:** read-only native code review
**Reviewed:** 2026-10-17

## Scope and source freeze

The following pre-existing dirty files were inspected. No source file, test, build, browser, staging area, or private raw feedback record was changed or executed.

| File | SHA-256 at end of review |
| --- | --- |
| `next/server/internal/attempts/rules_test.go` | `0259D91C4D289101BDE619DE7EB2DF0698CA554EB77BA9BBD4B4A0F1ECDDB28F` |
| `next/server/internal/attempts/service.go` | `7FA02C4310462A106C16DAF6C7A48D6EB0BD1FDF37AFEC2F945400AEDA296094` |
| `next/server/internal/sqlite/attempts.go` | `32D86C72004B98C3C43035AA83E9036E7FB5CB75AFE127332EEB4E082F7EA106` |
| `next/server/internal/sqlite/collection.go` | `EE0D6A525FB3B01AC0DA3B6A58ED713178A8C8554BF4DEFB8B9E70B4A69EA700` |
| `next/server/internal/sqlite/metadata_replay_test.go` | `46C765E2A8D3615215A5F518D2988EDAB9B3E2C080E5578D8185CE6B4F9AE7F2` |

The source hashes were stable between the initial scoped-diff read and this final freeze.

## Finding

### P1 — PostgreSQL difficulty integration test still asserts pre-shuffle order

**Location:** `next/server/internal/attempts/difficulty_rounds_integration_test.go:103-105`.

**Trigger:** `TestPostgresDifficultyRoundsPersistFilteredShuffledPartitions` injects a reversing `Options.Shuffle`, then calls `StartDifficultyQuiz` without a round.

**Evidence:** the changed `Service.Start` now calls `ShuffleQuestions` for every attempt before it creates snapshots and stores rows (`service.go:219-228`). The test instead compares snapshot `i` to `catalog.Quiz.Questions[i]`, which is source order.

**Consequence:** the tagged PostgreSQL integration test deterministically fails after this intended all-attempt shuffle; it cannot serve as release evidence for the new behavior.

**Smallest adequate correction:** update the whole-pack assertion to verify the same question-ID set, no duplicates, and the injected reversed order (or otherwise assert a permutation). Keep the later round-persistence assertions, which already expect the reversal. Run the affected tagged integration test only after ownership is established.

## Requirements compliance

- **Question shuffle:** `Service.Start` and SQLite `Attempts.start` now shuffle the selected question slice before snapshots and persistence. Round and difficulty methods first choose their subset, then delegate to that start path. This preserves the selected membership while changing order.
- **Snapshots and replay:** snapshots and `attempt_questions` are produced from the same shuffled slice. The changed SQLite metadata replay test uses question IDs rather than source indexes when comparing persisted records, which is the required adaptation to per-attempt order.
- **Round/difficulty/practice:** inspected call paths funnel ordinary, selected, difficulty, round, and practice starts through the same shuffle point. The code does not reintroduce out-of-round questions after selection.
- **Idempotency and storage:** the changed start code does not alter submit digest lookup, same-key/different-payload conflict handling, transaction boundaries, or persisted bundle lookups.
- **Answer-key privacy:** reviewed start persistence stores `PublicQuestion` and option-order snapshot data; no grading object or correct-option field is introduced in the start response or those new writes.
- **Entropy and validation:** both backends propagate `ShuffleQuestions`/random shuffle errors; `ShuffleQuestions` validates a permutation and rejects empty/duplicate/unknown question IDs.

## Verdicts

- **Requirements compliance:** conditionally sound by source inspection for the reviewed shuffle, selection, stored-snapshot, idempotency, and privacy paths; not accepted as verified because the affected PostgreSQL integration assertion is stale.
- **Code quality:** changes are small and place shuffling at a single final start boundary in both backends. The stale integration assertion is a concrete quality-gate defect and should be corrected before adopting the unknown-owner WIP.

## Checks not run

- No Go tests, integration tests, builds, browser checks, or app checks were run, as the packet requires read-only review only.
- No raw private feedback files or participant/request data were read.
- This native review is not external approval, adoption, a commit, or publication.
