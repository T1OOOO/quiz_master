# First assignments after P00

These are bounded starting briefs. Lead fills the actual Beads IDs, checkout/base hashes, unique hub labels and report paths using TASK_PACKET_EN.md. No placeholder ID is to be seeded into Beads or the hub. Stop at three concurrent children; reserve review capacity as results arrive.

## P01 — content baseline, Terra/high, qm_conten

Goal: establish an executable source inventory and the legacy answer-decoding risk before designing migration.

Read `quizzes/**/*.json`, `internal/quiz/domain/types.go`, `internal/quiz/service/service.go` around SyncFromFiles, and the downstream persistence mapping. Use a deterministic parser over only the quiz directory; output aggregates and a short anomaly list rather than dumping the corpus into context.

Own only the assigned P01 report and isolated scratch fixtures. No legacy source edit, no production DB, no content correction, no commit. Recompute quiz/question/category counts, type/option-count distributions, missing difficulty and duplicate IDs. Create an isolated example with a known nonzero `correct_answer` and show whether current decoding preserves it. Distinguish source-code behavior from unknown production data.

Acceptance: reproducible command/script and environment in report; every input file accounted for; observed decode result versus source expectation; exact relevant symbols; migration hazards and the minimum fixture list. Send READY through the hub, with output artifact hashes. This report's later commit is lead-owned; do not invent a hash now.

## P02 — test baseline, Luna/medium, qm_qa

Goal: establish actual check results and reproduce the prior Flutter hang at the current revision.

Read `go.mod`, `BACKEND_TESTING.md`, `flutter/pubspec.yaml` and the actual test entry points. Own only assigned evidence files; no production edits or broad dependency upgrades. Confirm tool versions. Run existing Go tests with captured exit status and a lead-selected finite timeout. For Flutter, start with one known small test and capture setup/runtime output; use the previous no-pub failure as a clue, not an assumption about the cause. Coordinate full Flutter process ownership before a broader suite.

Acceptance: passing/failing/skipped/unavailable separately listed; commands/cwd/duration/log paths; minimal reproduction if stuck; no claim of a green baseline from an interrupted process. Escalate diagnostic work requiring code changes or broad reasoning to Terra with the reproduction.

## P03 — environment contract, Terra/medium, qm_release

Goal: identify the smallest reproducible local/CI environment for the new implementation.

Read current Taskfile/Makefile/Compose/Dockerfile and relevant deployment docs; inspect installed Go, Flutter/Dart, Java/Android tools and container availability without reading secrets. Inventory existing MCP capability names and confirm which targets are known versus unverified. Check the existing hub path and a harmless status/read.

Own only the assigned environment report. Propose toolchain versions after checking compatibility and a single startup/build procedure. No infrastructure deployment, database migration, global installation or automatic optional MCP installation in this task.

Acceptance: prerequisites table with observed versions and unknowns; proposed local ports/isolated test resources; concrete blockers; distinction between already callable, configured, proposed and not implemented tools. Do not infer a Quiz database identity merely from a callable postgres tool.

## P29 — product/editorial brief, Terra/medium, qm_advisor

Run when a slot is free; it need not block P01–P03. Goal: write a short advisory brief for the quiz product and its first creative team pack.

Read TEAM_PLAN_EN.md scope and LIVE_TEAM_QUIZ_EN.md user flow. Own the assigned memo/hub advice only. Include audience, fun/learning balance, supported interaction types, content tone, factual review and a sample acceptance scenario. Keep the immediate-correctness question visibly pending until answered. Propose defaults for captain, admission and scoring without silently treating them as user decisions.

Acceptance: one recommended path and at most two meaningful alternatives; explicit assumptions and source-backed claims; no added microservices, new game framework or unapproved product scope. Lead converts accepted decisions into P04/P33 and P30 packets.

## Integration gate

After reports, lead confirms the baseline and maps affected issues. Resolve decisive schema/game-rule questions in P04/P33, then assign backend and Flutter foundations against the same fixtures. Keep v1 remediation separate if the source audit establishes an urgent legacy defect. The project has not passed the first working slice until P11's actual Web/Android/server round trip is demonstrated.
