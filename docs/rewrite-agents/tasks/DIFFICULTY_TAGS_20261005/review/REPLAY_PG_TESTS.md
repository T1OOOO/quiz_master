# Annotated replay and PostgreSQL round regression evidence

2026-10-05. Worker `metadata_replay_tests`, Codex gpt-6-sol, unique project-hub label `exec-replay-tests-sol`. Assignment base supplied by lead: branch `codex/quiz-v2`, HEAD `a1fd8bf`. These are uncommitted working-file hashes; no Git/index/branch/deployment operations were performed. Production changes by the lead/backend were preserved. Skills read: qm-work-packet, qm-go-backend, qm-review and agent-hub-coordination, plus HOST_HUB and project HUB_PROTOCOL_EN. No children spawned.

**Worker status: DONE_WITH_CONCERNS, ready for independent review.** The required SQLite annotated partial replay now passes. The PostgreSQL integration test compiles, but actual PostgreSQL execution remains **NOT_RUN locally**, pending the lead's PostgreSQL CI gate. No full-suite, pinned Go 1.25 Linux, cross-provider review or release claim is made.

## Owned files and coverage

- `next/server/internal/sqlite/metadata_replay_test.go`: new test `TestAnnotatedPartialAttemptPinsMetadataAfterRepublish` uses a real temporary SQLite database and raw source collection import, the production collection path. It starts two annotated questions with numeric difficulty 2, public context and private editorial tags, accepts one correct answer, then republishes the same question IDs with difficulty 9, a distinct taxonomy ID/hash and disjoint tag IDs. Stems, option text, grading and explanations also change, making accidental replacement grading/reveals observable. A newly started attempt uses the replacement revisions and metadata. The test then removes the raw source and both dictionary files, confirms live dictionary loading fails, and uses the replacement service to replay the original receipt, submit the remaining original answer, finish at 2/2 and reveal the original correct options/explanations. It compares stored original bundle (including taxonomy/private metadata), public questions, revisions, snapshots, option mapping and persisted positions against the original values.
- `next/server/internal/attempts/difficulty_rounds_integration_test.go`: new `//go:build integration` test `TestPostgresDifficultyRoundsPersistFilteredShuffledPartitions` constructs 82 valid interleaved easy/hard questions, loads them through real `NewService`, creates a real identity and invokes actual service starts. The easy catalog and whole attempt contain 41 matches. Deterministic reverse shuffling must occur independently inside each selected slice, yielding 20/20/1 rounds; no hard question, repetition or missing catalog question is allowed. It reads real `attempt_questions` rows ordered by position and checks their public questions, revision columns, snapshots, reversed options and mappings. It checks original bundle identity in attempts/catalog, full-catalog immutability, past-tail rejection and empty-band catalog/start rejection. It requires `QM_TEST_DATABASE_URL` and migrations just like the existing lifecycle integration suite.
- This report. No existing helper or implementation file changed by this worker.

These tests close the missing evidence implementation identified in `CODE_METADATA_RECHECK.md`, against CONTRACT.md lines 19 and 33. The PostgreSQL runtime gate remains unresolved until CI executes the tagged test against a database. No PostgreSQL practice retrofit was attempted.

## Verification

Runtime: `C:/Program Files/Go/bin/go.exe`, `go version go1.27.0 windows/amd64`. Go commands below ran from `C:/ap/quiz_master/next/server`.

| Command | Result | Saved local output |
|---|---|---|
| `go test ./internal/sqlite -run '^TestAnnotatedPartialAttemptPinsMetadataAfterRepublish$' -count=1 -v` | PASS, exit 0; test 0.15s | `.run/quizipedia/replay-sqlite-targeted.txt` |
| `go test -tags integration ./internal/attempts -run '^$' -count=1` | Compile/link PASS, exit 0, explicitly `[no tests to run]`; **not database execution** | `.run/quizipedia/replay-pg-compile-only-valid.txt` |
| `go test ./internal/sqlite ./internal/attempts -run '^(TestAnnotatedPartialAttemptPinsMetadataAfterRepublish\|TestServiceShuffledRoundPermutesOnlyItsSelectedSlice\|TestDifficultySelectionPartitionsFilteredPackWithoutRepeats)$' -count=1 -v` | PASS, exit 0; annotated replay 0.16s; both shared round tests PASS | `.run/quizipedia/replay-targeted-valid.txt` |
| `gofmt -w` over the two owned test files | Exit 0 | Formatted source |

No RED is claimed: this assignment adds missing mandatory regression coverage, and the SQLite behavior was already correct. The PostgreSQL defect fix was already present when these tests were implemented. Actual database regression execution, including a hypothetical pre-fix RED, was unavailable locally and was not simulated.

## Resource admission incident and disposition

Initial heavy lease `lease-47812687af2d4f94bb58342115bb36c4` was GRANTED. The first renewal guard write mistakenly used a relative path while the Go command cwd was `next/server`; file creation failed and the initial guard process exited. The first targeted SQLite check finished within the original grant. A subsequent shell attempted renewal after expiration, received rejection, but erroneously continued to an integration compile-only check (exit 0). That compile log is **excluded from accepted evidence**. The lead was notified immediately. No Go subprocess remained, the failed guard exited, and the owner reconciled the expired lease with concrete quiescence evidence; broker returned RELEASED, generation 2.

Fresh heavy lease `lease-15d69af25ca84bcf87816c03c50190fe` was GRANTED. The corrected guard used absolute script/stop paths and this worker's own session identity, renewing every eight seconds. An explicit successful lease renewal immediately preceded the accepted compile-only and targeted checks, and failed renewal would exit that shell before checks. After both commands completed, the stop file was set, the owned guard process was waited out and confirmed absent, and no guard error file existed; the lease was released normally. The editing lease and report lease were also released. Guard/log files are ignored local evidence, not production artifacts. No uncertain reservation or unrelated process was erased or terminated.

## Stable working-file SHA256

| File | SHA256 |
|---|---|
| `next/server/internal/sqlite/metadata_replay_test.go` | `D722B668588306F4237C718B4E50F07E6818258B87E42C5A74AD2E0796167F62` |
| `next/server/internal/attempts/difficulty_rounds_integration_test.go` | `6B8B95F0990F7BE949D8600DC1DA17B82C49A919C0EE3C49337470E75DCA73BE` |
| `next/server/internal/attempts/service.go` (read-only dependency) | `F9F5E64E9208F65DF5FCE7E5174C35F7D22F2607E27EBBF4E6669CFCD400B8AA` |
| `next/server/internal/attempts/rules.go` (read-only dependency) | `4CAF6AF1E3247B1D5C2D2F7146A1DE790DF7B0A4C9831E53CE5961436D43EB11` |

Lead owns independent review, integration/full quality gates, PostgreSQL CI execution, Beads/hub acceptance, commit and mandatory push. No integration commit or task acceptance is fabricated by this worker.
