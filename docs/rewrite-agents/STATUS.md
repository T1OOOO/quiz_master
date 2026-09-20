# Quiz Master 2.0 rewrite status

Updated: 2026-09-20 (Europe/Istanbul)

## Current checkpoint

- Branch: `codex/quiz-v2`; base commit: `ce310d7589bc0f97adcb25d04a15c117aea7c1d8`.
- P00 (`quiz_master-rq9.1`) is accepted and closed. Integration commit: `d0dfc17057c163087bdc3390b22f6adfff3c3519`. Rewrite epic: `quiz_master-rq9`.
- P01 (`quiz_master-rq9.2`) is accepted and closed. Integration commit: `85ed3f038afee2249169f60243ccd322789d686c`.
- P02 (`quiz_master-rq9.3`) is accepted and closed. Integration commit: `c5eec44a8037e99cee3316e35cf5b164b31a7ee5`.
- P03 (`quiz_master-rq9.4`) is accepted and closed. Integration commit: `519848ab7a3b0a4118d589cabc8cbcbf3c687cf4`.
- P29 (`quiz_master-rq9.30`) is accepted and closed. Integration commit: `5e549a799bc8a14bc946240cd3a5005e305380ff`.
- P04 (`quiz_master-rq9.5`) and its P04R remediation (`quiz_master-rq9.42`) are accepted and closed. Integration commit: `0b32a6c77fbc020b0c95b6bb80551ee095c458d2`.
- P33 (`quiz_master-rq9.34`), execution child P33E (`quiz_master-rq9.43`) and fixture remediation P33F (`quiz_master-rq9.44`) are accepted and closed. Integration commit: `f85b2d4`. The original P33 hub card remains an immutable malformed-dependency audit; accepted hub lifecycle is recorded on `.43` and `.44`.
- P05 (`quiz_master-rq9.6`) is accepted and closed. Integration commit: `a3d6062`. It adds the Go/PostgreSQL server skeleton, checksummed migrations, guest/session identity boundary, bounded startup/HTTP timeouts and disposable-database integration evidence.
- P06 (`quiz_master-rq9.7`) and P06F (`quiz_master-rq9.45`) are accepted and closed. Reviewed Flutter code is integrated in `313dda8`; remote Android evidence is integrated in `884782c`. GitHub job `106112259701` built a real 154,866,738-byte debug APK with SHA-256 `9024d7f12908563e90a4a0c587450b45ad86ed1942b0db728e3350e86994996b`. No device, release signing or release-mode claim is made.
- P07 (`quiz_master-rq9.8`) is accepted and closed with `DONE_WITH_CONCERNS`. Integration commit: `558cac7`. The digest-pinned Compose API/PostgreSQL stack passed build, health and exact teardown checks; pinned CI covers Go, Flutter Web and Android. No remote CI run or real debug APK is claimed, so P06 remains blocked.
- P08 (`quiz_master-rq9.9`) is accepted and closed. Integration commit: `f5428ae`. `quizctl import/validate/build/diff` now produces a deterministic controlled bundle from the first real 25-question legacy pack; 25 grading entries and 150 option mappings were independently checked. Bundle SHA-256: `6c7754aa9b142d8657bac1bb65f0536d30364d262ef109315c4b9356ee512b95`.
- P09 (`quiz_master-rq9.10`) is accepted and closed with one environment concern. Integration commit: `ec74e4a`. Authenticated attempts now pin the P08 bundle/snapshots, enforce deadlines and idempotent final answers, score only on the server and persist participant-scoped history. PostgreSQL concurrency tests pass; Windows race instrumentation is unavailable because `CGO_ENABLED=0`.
- The P00-P39 Beads graph contains 40 mapped tasks and 70 plan dependency edges with no cycles.
- Kit profiles, skills, documents and hub configuration are installed in the project. The current task cannot hot-load the new custom profiles; explicit model/effort spawning is the fallback.
- Per user direction, run no more than one child agent at a time.
- Baseline packets P01-P09, advisory P29 and P33 are integrated and accepted. P10 is dependency-ready after the successful P06 remote Android smoke. The first remote CI run also exposed two portability defects (missing `rg` and CRLF/LF-sensitive P08 source hashing) that must be remediated before P10/P11 acceptance.

## Preserved pre-existing work

- `.beads/issues.jsonl` was already modified before rewrite work. It now also carries the requested rewrite registry, but must not be included in a rewrite commit while the earlier publication rejection remains unresolved.
- `PROJECT_OVERVIEW_RU.md` remains untracked and untouched. SHA-256: `1ED842B2F8B10EBC7FD16A58962ABCC22631905935791DA8719529873532E5E8`.
- Do not reset, clean, stash or publish either artifact as part of rewrite integration.

## Decisions and blockers

- Live-team reveal policy is frozen by accepted P33: the private host sees committed submissions immediately; teams receive receipt immediately; correctness is shared only after round close.
- P05/P06 consumed accepted P04 and P33 contracts; later backend/Flutter work must preserve those boundaries.
- Docker Desktop's Linux engine is now available. P07 proved an isolated digest-pinned API/PostgreSQL stack and exact project/volume cleanup.
- `bd doctor` reports a repository fingerprint mismatch and two pre-existing merge-artifact files. The database passed integrity and DB/JSONL sync checks. Do not auto-fix or delete those artifacts without resolving ownership.
- Production cutover and external publication are not authorized by this status.
- P01 verified 101/101 legacy JSON files and 3,128 questions. A nonzero legacy `correct_answer` is ignored by the current Go field tag and decodes to zero. Production data remains uninspected. P04/P08 must define explicit mapping, bounds checks, duplicate-ID policy and `correct_multi` handling.
- P02 established a green checked-in baseline: `go test ./...`, 12 focused Flutter tests and 61 full-suite Flutter tests passed with finite bounds. Device/browser integration remains outside this baseline.
- P03 records the proposed environment contract and blockers: Docker Linux engine, Android build/device tooling and `task` are unavailable; current entry points/toolchain conflict; hub MCP is configured but was not loaded in this task.
- P04 defines executable `quiz-contract/v1` schemas, scoring fixtures, bundle/attempt pinning, idempotent answer-write evidence and the deliberately team-free base event envelope. The dependency-free checker accepts all positive instances and rejects 37 named negatives; P33 owns the live-team extension and final reveal timing.
- P33 freezes `live-team-contract/v1`: one captain/final answer, admission closed on start, host-private arrivals, team receipt without correctness, shared reveal only after close, audience-separated events, QR/manual admission, reconnect/outbox semantics and private-by-default results. Its checker pins P04, accepts 18 positive cases and rejects 33 input-driven negatives by exact error; poisoned inputs reproduce 0/33 expected errors.
- P08 freezes the first production-shaped content path: strict legacy decoding, collision-fatal stable IDs, explicit difficulty/multi-answer mapping, full Draft 2020-12 validation, P04-compatible canonical hashes, Unicode normalization vectors, atomic local outputs and secret-safe diffs. This is controlled local content, not publication or full-corpus reconciliation.
- P09 adds migration 0002 and the first real API vertical: public catalog, authenticated start/answer/finish/history, reversible internal-to-contract participant IDs, immutable receipts, exact-deadline rejection, transaction serialization and private-key isolation. A disposable PostgreSQL run passed 53 attempt/HTTP integration events and left no container/volume.

## Next actions

1. Remediate the two remote CI portability failures and obtain a fully green rerun while preserving the successful Android artifact evidence.
2. Dispatch P10 Flutter catalog-to-history flow, then run the P11 first vertical gate.
3. Preserve P09's unavailable Windows race instrumentation as explicit release evidence.
