# Quiz Master 2.0 — multi-agent execution plan

Prepared 2026-09-20. This is an execution proposal and a launch kit, not evidence that the rewrite has been implemented. Product platforms: **Web and Android, one Flutter client**. The current repository is `C:\ap\quiz_master`; the similarly named project under AntigravitiProjects is not the target.

## 1. Outcome and architectural decisions

Deliver a replacement that preserves the quiz product: discovery, guest/account access, solo play, multiplayer rooms, text chat, explanations, bookmarks and mistake review, history, rankings, reporting, editing and content publishing. Add the user's required live team mode: shared presenter question, QR joining from phones, simultaneous team answers and immediate host updates. Keep the old application available until migration and feature acceptance pass. `LIVE_TEAM_QUIZ_EN.md` defines that mode and records the pending immediate-correctness clarification.

Use a Go modular monolith, PostgreSQL and a Flutter client. Adopt Language Learner's useful patterns: versioned content contracts, reusable card composition, Riverpod state, typed models, a single API client, Drift local storage, contract checks, and thin MCP adapters. Implement quiz scoring, answer secrecy, deadlines, room state and replay handling specifically for Quiz Master.

| Area | Proposed implementation | Boundary |
|---|---|---|
| Client | Flutter/Dart, Riverpod, Freezed, Dio, Go Router, Drift | One Web/Android application; no second React Native rewrite |
| Server | Go, pgx, PostgreSQL; small HTTP and WebSocket adapters | Business rules live outside transport; one deployable service initially |
| Router | Prefer standard `net/http`; retain Echo if an ADR shows lower migration cost | A router change is not a release requirement |
| Content | JSON Schema, Markdown explanations, immutable versions, stable option IDs | Limited content model; no import of the entire Language Learner DSL |
| Contracts | OpenAPI plus content/event schemas and executable fixtures | Public playable payloads and private answer keys are different types |
| Tooling | Go `quizctl`; TypeScript MCP using the official SDK | CLI, editor and MCP share validation and publication rules |
| Local runtime | PostgreSQL/API in Compose; Flutter separately | One documented Windows and CI startup path |
| Release | Reproducible images, staging, backup/restore and rollback | Existing cluster only after capacity/ownership checks; production switch is a separate authorized action |

Exact compatible versions are selected and locked during foundation work. Do not copy a neighbor's lock files wholesale. No mandatory Redis, Kubernetes migration, service mesh, event bus or multiple microservices in the first release. Reassess using measured load.

## 2. Observations to reproduce before implementation

The earlier source audit found 101 quiz files, 3,128 questions and seven categories in `quizzes/`. All questions were choice questions, with 4–6 options; 703 lacked difficulty. These are baseline observations, not permanent expected counts: record the checkout and recompute them before migration.

Priority evidence paths:

- `internal/quiz/domain/types.go`: `correct_answer_index` JSON mapping.
- `internal/quiz/service/service.go`: `SyncFromFiles` and its actual JSON decoding; `internal/storage/repository/quiz.go` is the downstream persistence path.
- `quizzes/**/*.json`: source content uses `correct_answer`; 2,561 previously observed answers had a nonzero index. Reproduce this mismatch without touching production.
- `internal/auth/http/handlers.go`, `internal/authapi/handler.go`: result submission and trust in client totals.
- `internal/realtime/hub.go`, `internal/models/room.go`: room state, participant identity and events.
- `internal/auth/service/service.go`: quota implementation.
- `flutter/pubspec.yaml`, `flutter/lib/`: current UI and dependencies.
- `mobile/`: legacy alternative client; inventory behavior, not a second target.

The current working tree has a modified `.beads/issues.jsonl` and an untracked `PROJECT_OVERVIEW_RU.md`. These predate implementation. Preserve them. A prior automatic approval review rejected publishing those artifacts to the remote; this kit does not resolve that rejection or authorize a retry. Track any still-applicable blocker explicitly and do not bypass it through another command or checkout.

The earlier Go test run passed; an earlier Flutter test run hung and was interrupted. Neither establishes a passing baseline for the future checkout. Re-run relevant checks with a bounded timeout and report failures honestly.

## 3. Team and model routing

There are twelve logical roles, but **at most three spawned agents plus the lead** may be active. Usually use two implementers and reserve a slot for review. Roles are reused across waves, not twelve permanent conversations. Agent lifecycle is managed by Codex; durable communication uses the existing shared agent-hub (see `HUB_PROTOCOL_EN.md`).

| Role / agent profile | Default model / effort | Main responsibility | Required skill set |
|---|---|---|---|
| Lead, primary session | `gpt-5.6-sol` / medium | Scope, contracts, dependencies, task packets, integration and acceptance | `qm-lead`, `qm-work-packet`; `qm-review` for critical adjudication |
| `qm_content` | `gpt-5.6-terra` / high | Schemas, content conversion, source provenance, immutable bundles | `qm-work-packet`, `qm-contracts-content` |
| `qm_backend` | `gpt-5.6-terra` / medium | Identity, persistence, attempts, scoring, rooms, server APIs | `qm-work-packet`, `qm-go-backend` |
| `qm_flutter` | `gpt-5.6-terra` / medium | Shared Web/Android client, cards, routing, offline behavior | `qm-work-packet`, `qm-flutter` |
| `qm_tools` | `gpt-5.6-terra` / medium | MCP adapter, editor integration, development tooling | `qm-work-packet`, `qm-mcp` |
| `qm_qa` | `gpt-5.6-luna` / medium | Execute specified checks, reproduce failures, collect UI evidence | `qm-work-packet`, `qm-qa` |
| `qm_reviewer` | `gpt-5.6-terra` / high | Independent review of requirements, diff and edge cases | `qm-work-packet`, `qm-review` |
| `qm_release` | `gpt-5.6-terra` / medium | CI, build configuration, staging and migration rehearsal | `qm-work-packet`, `qm-release` |
| `qm_mechanical` | `gpt-5.6-luna` / low | Exact repetitive edits, fixture transcription, small documentation batches | `qm-work-packet`, `qm-mechanical` |
| `qm_advisor` | `gpt-5.6-terra` / medium | Product/UX advice, alternatives and help with blocked decisions | `qm-work-packet`, `qm-advisor` |
| `qm_quiz_writer` | `gpt-5.6-terra` / medium | Creative quiz concepts, question drafts, explanations and plausible distractors | `qm-work-packet`, `qm-quiz-writing` |
| `qm_fact_checker` | `gpt-5.6-terra` / high | Independent solve, factual verification and ambiguity review | `qm-work-packet`, `qm-fact-check` |

Recommended lead: Sol. Economical alternative: Terra/medium after the initial contracts have been settled; request Sol/high for unresolved architecture, concurrency and migration decisions. A Luna lead is suitable only for executing an already accepted list of small tasks. It must hand off architectural and data-integrity decisions, not approve them by itself.

The profile fixes both model and effort. If the tool accepts a role profile, use it. If only generic spawning is available, explicitly set the same model and effort, pass the profile's instructions, and start with minimal history. Do not silently inherit the lead's expensive model. If the harness forces full-history inheritance, prefer a sequential bounded task or disclose that the expected saving is unavailable.

`qm_reviewer` must be a different agent instance from the implementer. This is independence of context, not vendor diversity. Sol lead reviews critical scoring, authorization, room concurrency, content visibility and migration decisions. If the lead wrote the critical code, use a fresh Sol reviewer instead; generic spawn is required if a configured Terra profile cannot be overridden.

## 4. Skill selection policy

The shipped skills are short, original Quiz-specific instructions. They distill practices evaluated in neighboring projects and primary sources; they do not copy entire external skill packs. See `SOURCES_AND_SKILLS_EN.md` for provenance and rejected approaches.

Load the shared packet skill and the role skill, then only the reference required by the active task. Do not load all fourteen skills, all neighbor AGENTS files, the entire plan, or the entire Language Learner repository into every worker. Other applicable higher-priority instructions still apply. Each role's selected internet skill and MCP set are mapped in `SOURCES_AND_SKILLS_EN.md` and `MCP_SELECTION_EN.md`; these are task-fit recommendations, not a universal ranking. Backend, Flutter, QA and reviewers additionally load `qm-live-quiz` only on the live-team track.

The skill list in a profile is a **context-loading policy**, not a hard tool or filesystem allowlist. Codex does not gain an invented `skills = [...]` configuration field. Parent permissions and available MCP servers may be inherited. Review/tool access is constrained by actual session permissions and task ownership, not by an assertion in a prompt.

## 5. Workspace layout and ownership

Build beside the legacy application:

```tex
next/
  contracts/                 # HTTP, card, event and fixture contracts
  content/                   # canonical migrated content and manifests
  server/
    cmd/api/
    cmd/quizctl/
    internal/content/
    internal/identity/
    internal/catalog/
    internal/attempts/
    internal/rooms/
    internal/learning/
    internal/moderation/
    migrations/
  apps/quiz_app/
  tools/project_mcp/
  infra/
docs/rewrite-agents/
  tasks/                     # immutable issued task briefs
  reports/                   # per-task evidence, scoped to author
  decisions/                 # small lead-owned ADRs
  STATUS.md                  # lead-owned recovery summary


These are proposed directories, not a requirement to generate empty scaffolding. Each directory appears when a working slice needs it. Package/module names are chosen once in the foundation gate.

| Owner | Writable area, narrowed further in every packet | Coordination rule |
|---|---|---|
| Lead | Beads records, STATUS, ADRs, task packets, integration commits | Sole owner of scheduling, git index and repository-wide integration |
| Content | `next/contracts/**`, `next/content/**`, `next/server/internal/content/**`, `next/server/cmd/quizctl/**` | Freeze schema versions before consumers start; no direct DB migrations |
| Backend | Other `next/server/**`, including all SQL migrations | One migration owner; content DB adapter lives outside content-owned paths |
| Flutter | `next/apps/quiz_app/**` | All client features serial unless explicitly split into disjoint files |
| Tools | `next/tools/project_mcp/**` | Flutter editor widgets stay with Flutter; server endpoints stay with backend |
| Release | `next/infra/**`, assigned CI files | Root build/CI files and manifests require an exclusive lease from lead |
| QA | Assigned tests/evidence paths only | Does not patch production code while verifying |
| Reviewer | Read-only; returns review to lead | No edits, commits or fixes; lead stores verdict |
| Mechanical | Exact file list only | Never overlaps another active writer |
| Advisor | Assigned decision memo/report only; hub advice | Lead accepts proposals before they change scope or contracts |
| Quiz writer | A leased `next/content/drafts/<batch>/**` subtree | Content agent yields that subtree for the task; drafts cannot publish |
| Fact checker | Assigned editorial report only; hub findings | Reads drafts and sources; does not edit the writer's batch |

Shared Go manifests, Flutter pubspec/lock files, code generation, root CI and API contracts require a recorded owner. Other agents request the change from that owner. Nobody runs `git add .`, commits, rebases, pushes, stashes, cleans or changes branches while workers are editing. Lead integrates at a quiet boundary with workers stopped.

A task needs a known base commit **and** the initial relevant dirty-file manifest. In a shared working directory, `git diff BASE` alone does not isolate a worker. At handoff, create a scoped diff including new files, record hashes, and suspend writes to reviewed paths. For concurrent edits to the same paths, use isolated worktrees and explicit integration instead; do not pretend a prompt creates isolation.

## 6. Non-negotiable quiz invariants

1. Authoritative results come from submitted answers in a server-created attempt. Ignore/reject caller-supplied scores and totals.
2. An attempt pins question revisions, option IDs/order and scoring rules. Editing or republishing content cannot change an ongoing or historical attempt.
3. Published bundles contain private answer keys. Public ranked/room DTOs, static assets, logs and error payloads do not reveal them before the allowed reveal phase.
4. Downloaded practice packs may contain answers. Such practice is explicitly unranked and cannot later become a ranked attempt. Public practice content also limits secrecy for competitive use; rated rooms should use a controlled pool and the product must not promise cheat-proof play.
5. Accepted answer writes use a transaction, identity authorization and idempotency key. Same key/same payload returns the same result; same key/different payload conflicts. Concurrent submissions cannot award twice.
6. Stable authenticated user/guest IDs identify participants. Usernames are labels. One user cannot read or mutate another user's attempt, bookmark, report or room authority.
7. Server time governs deadlines. Reconnect uses room version and event sequence/snapshot. A restart must have a defined recovery policy, not an in-memory assumption.
8. Content transitions are draft → validated → published immutable version. A failed import does not silently publish a subset. Invalid rows are accounted for with a reason.
9. Preserve legacy IDs, password-hash compatibility and historical provenance. Old client-reported results remain visibly legacy/unverified and never populate the trusted v2 leaderboard.
10. Offline mutations are user/device scoped and typed. Logout prevents cross-account replay. Guest-to-account merge is explicit and idempotent. No arbitrary URL/body retry queue.
11. Single choice, multiple choice and exact/normalized text answer types have agreed scoring and normalization fixtures. No LLM decides scored correctness in this release.
12. Localization, readable explanations, 4–6 options, keyboard/back navigation, Android lifecycle and Web reload are acceptance cases, not polish left after feature completion.

## 7. Product scope and parity

| Capability | First working slice | Required before replacing legacy |
|---|---|---|
| Catalog | One real imported pack | All valid source packs, categories, search/filter, loading/error/empty states |
| Identity | Guest identity, server authorization | Account sign-in, session lifecycle, guest merge, ownership checks |
| Solo play | Single choice, authoritative result | Choice/multi/text, practice versus ranked, deadlines and retry policy |
| Cards | Question and explanation | Shared question/explanation/pack components, media references, source labels |
| Multiplayer | Later wave | Lobby, host rights, join/leave, reveal, scoring, reconnect, restart recovery, text chat |
| Live team quiz | Contract after initial foundation | Presenter/host views, QR and manual join, captain answer, immediate arrivals, reveal policy, team standings and recovery |
| Learning | Result history | Bookmarks and deterministic mistake review; offline downloaded practice |
| Administration | Validated CLI import | Editor, reports/moderation, draft validation, publication and audit trail |
| MCP | Read-only diagnostics first | Search/read, draft changes, validate/build/diff and scoped publication |
| Operations | Local startup | CI, monitoring, signed Android release process, restore drill and rollback |

Explicitly outside the first replacement release: subscriptions/payments/ads, chat image uploads, arbitrary new game modes, advanced FSRS scheduling, generated subjective grading, and automatic production publishing by AI. Keep these differences visible. Do not remove requested functionality merely to reduce tokens.

## 8. Execution waves and task DAG

The following IDs are planning keys, not invented Beads IDs. Lead maps them to actual issue IDs after `bd onboard`, reuses existing relevant issues and records dependencies in Beads. A task may be split if its acceptance requires more than one coherent behavior.

| Wave / task | Owner | Depends on | Deliverable and acceptance evidence |
|---|---|---|---|
| W0 / P00 | Lead | — | Confirm repository, dirty files, AGENTS, tools, baseline, authorization and scope; create parity matrix and Beads epic |
| W0 / P01 | Content | P00 | Recompute source inventory; reproduce answer-index mismatch using isolated fixture; migration risk report |
| W0 / P02 | QA | P00 | Reproduce current Go checks and diagnose Flutter baseline timeout without production edits; exact environment report |
| W0 / P03 | Release | P00 | Verify local Go/Flutter/Android/DB prerequisites and a proposed startup contract; no production changes |
| W1 / P04 | Content + lead | P01 | Card v1, public/reveal payloads, attempt and room event contracts, scoring fixtures and compatibility ADR |
| W1 / P05 | Backend | P04,P33 | API skeleton, PostgreSQL migrations, identity boundaries and transaction conventions; disposable DB integration check |
| W1 / P06 | Flutter | P04,P33 | App shell, routing, theme/RU-EN resources, API adapter and card primitives from fixtures; Web/Android smoke |
| W1 / P07 | Release | P04 | Reproducible Compose/CI toolchain and pinned dependencies, borrowing manifests only under owner lease |
| W2 / P08 | Content | P04,P05 | `quizctl import/validate/build/diff`, stable ID mapping and one real pack; correct-answer golden fixtures |
| W2 / P09 | Backend | P05,P08 | Start attempt, submit answer, finish, history; tests for score forgery, access, replay, deadline and snapshot |
| W2 / P10 | Flutter | P06,P08 | Catalog → play → explanation → result → history with a real API; 4/5/6 options and responsive states |
| W2 / P11 | QA + review | P07,P09,P10 | FIRST VERTICAL GATE: same real pack works in browser and Android, result persists and agrees with server |
| W3 / P12 | Content | P11 | Full migration reconciliation: every source question accounted for, invalid content blocks publication |
| W3 / P13 | Backend | P11 | Accounts/session lifecycle, guest merge, choice/multi/text scoring, history and v2 rankings |
| W3 / P14 | Flutter | P11 | Full catalog/search, accounts, play variants, history/rankings, accessibility/localization |
| W4 / P15 | Backend | P13 | Room state machine, identity/host authorization, event sequence, idempotency, restart and reconnect behavior |
| W4 / P16 | Flutter | P14,room contract in P04 | Lobby/play/reveal/chat screens; fixture implementation may run parallel to P15; real integration awaits P15 |
| W4 / P17 | QA + review | P15,P16 | Two-device room tests, duplicate messages, reconnect, deadline boundary, kick/leave, restart and host loss |
| W5 / P18 | Backend | P13 | Bookmark, mistake-review, report and typed sync APIs with user-scoped idempotency |
| W5 / P19 | Flutter | P14,sync contract | Drift cache/downloads, offline practice and typed pending operations; real sync acceptance awaits P18 |
| W5 / P20 | QA + review | P18,P19 | Web reload/offline shell, Android process restart, logout/account switch and guest merge proof |
| W6 / P21 | Backend | P12,P13 | Editor permissions, draft/version/publish endpoints and moderation, audit and rollback of active content pointer |
| W6 / P22 | Flutter | P14,editor contract | Editor/moderation UI reusing card rendering; role-restricted workflows |
| W6 / P23 | Tools | P08,P21 | SDK-based MCP resources/tools, CLI parity, typed errors, path boundary and permission tests |
| W6 / P24 | QA + review | P21,P22,P23 | Same invalid content rejected in CLI/editor/MCP; answer keys unavailable to player tools; authorized publish audited |
| W7 / P25 | Release + backend | P12,P17,P20,P24,P35 | Data migration rehearsal including team-session schema on a copy, counts/checksums, password compatibility, backup restore and rollback rehearsal |
| W7 / P26 | QA + review | P25,P32,P38,P39 | Full parity/critical-path checks, accepted editorial and QR team flows, agreed load target and observed results, Web/Android release artifacts |
| W8 / P27 | Lead + release | P26 | Reviewable cutover package: exact destination, artifacts, data diff, monitoring and rollback; deploy only within authorization |
| W8 / P28 | Lead | P27 and successful acceptance | Remove obsolete paths only after retention/rollback decision; archive legacy docs and finish ownership handover |

Additional editorial track requested by the user:

| Task | Owner | Depends on | Acceptance |
|---|---|---|---|
| P29 | Advisor | P00 | Short product/content brief: audience, tone, topic, cognitive mix, supported interactions, acceptance examples |
| P30 | Quiz writer | P04,P29 | Ten-question pilot in a leased draft subtree, source records, plausible distractors and explanations; no publication |
| P31 | Fact checker | P30 | Independent solve before seeing the key; source verification; every item accepted/revised/rejected with reasons |
| P32 | Content + QA | P08,P31 | Revised accepted pilot passes schema/CLI validation and card rendering; later exercise the same batch through editor/MCP after P24 |

The creative track can run when a slot and exclusive paths are available. It does not block the initial legacy-content slice. P26 includes the accepted pilot/editorial workflow as evidence that the newly requested creative role is usable. Optional hints may be drafted only after their reveal/scoring policy is agreed; this team role does not introduce a player-facing live AI tutor by implication.

The live-team track P33–P39 is detailed in `LIVE_TEAM_QUIZ_EN.md`: contracts → join/identity → authoritative concurrent rounds → presenter/host and phone UI → multi-client/restart/load verification → reviewed event pack. Run P33 immediately after P04/P29 and before P05/P06: P04 defines the base contract, P33 its team extension, and the combined version is frozen for consumers. Implementation joins the room/frontend work after W3. P25 includes the final team schema; P26 explicitly requires P32/P38/P39. This new user requirement extends the critical path and must be included in estimates; do not reuse earlier rewrite duration estimates unchanged.

W4–W6 are shown in a readable order; tasks with frozen contracts and disjoint writers may overlap after W3. Do not run more work just to fill all slots. A ready queue is determined by dependencies and ownership, not wave numbering alone.

```mermaid
flowchart LR
  W0[Baseline and inventory] --> C[Base and team contracts with fixtures]
  C --> B[Backend foundation]
  C --> F[Flutter foundation]
  C --> I[Build foundation]
  B --> V[Real quiz vertical slice]
  F --> V
  I --> V
  V --> P[Parity and full import]
  P --> R[Rooms]
  P --> O[Offline and review]
  P --> E[Editor and MCP]
  R --> G[Migration and release gates]
  O --> G
  E --> G
  G --> K[Authorized cutover]


## 9. Contract and implementation gates

Before P05/P06, settle these in P04 plus the accepted P33 team extension: ID/revision semantics; option shuffle mapping; scoring/partial-credit policy; text normalization; ranked versus practice/reveal policy; response error envelope; attempt status and idempotency behavior; room/team event/version envelope; session transport for Web and Android; QR/manual admission and result-link access. Later contract changes require a versioned amendment, fixture update and an explicit affected-consumer gate. Unresolved details stay explicit and block only affected consumers; setup/report tasks can continue while the reveal clarification is pending.

Default product proposals for the ADR: one point for a correct single choice; multi choice requires exactly the expected set; text uses explicit accepted variants with defined Unicode/case/whitespace normalization; no speed bonus until agreed and tested. Do not silently change historical rules: compare these proposals against legacy behavior and record the decision. This provides a narrow initial spec for cheaper workers.

Every code task supplies the smallest meaningful test for its behavior. Critical concurrency, ownership, migrations and data transformations need integration/negative checks, not only mocks. Documentation-only edits need link/consistency checks, not contrived unit tests.

Full suites and Flutter builds run once per integrated gate on a stable checkout. Narrow checks can run independently if they do not share mutable fixtures, ports, databases or code generation. Use localhost port 0 where possible, unique disposable DB/schema names, an injectable clock and deterministic randomness. Serialize full Flutter builds/codegen through the lead's scheduling lease; do not create an unreliable homemade lock protocol.

Expected commands are selected from the implementation's actual toolchain. Typical checks: `go test ./...`, `go vet ./...`, targeted database tests, race checks on a supported runner, `flutter analyze`, focused widget/unit tests, integration tests on Chrome/Android, `flutter build web` and Android build. If the Windows toolchain cannot run race checks, use Linux CI and report the pending gate. No passing claim for an unavailable emulator, interrupted command or skipped suite.

For each gate, record commit or scoped content hashes, command, working directory, exit status, relevant result and evidence path. A reviewer may rely on fresh evidence for unchanged code; rerun when fixes or environment changes invalidate it. Do not repeat entire suites merely because another agent joins.

## 10. Token and cost controls

These are operating targets, not hard token limits enforced by TOML:

| Item | Target | Reason |
|---|---|---|
| Task packet | 400–900 words plus file/contract pointers | Enough exact requirements without conversation history |
| Worker context | Relevant source, 1 shared skill, 1 role skill, selected schema | Avoid loading the whole repository or all skills |
| Worker final | 150–300 words and evidence paths | Keep the lead context small |
| Lead recovery summary | At most about 1,200 words | Durable state after compaction or model switch |
| Mechanical batch | A few same-shape edits with one acceptance rule | Avoid one model call per trivial file |
| Default active agents | 2 workers; third slot for review or independent work | Limit contention and total context duplication |
| Repeated failure | After two substantive unsuccessful fixes, split or escalate | Stop cheap retries becoming expensive loops |

Do not impose an arbitrary output cap that prevents reporting a correctness problem. Do not put `token_budget` or unsupported agent fields in configuration. Log actual usage when the harness exposes per-task usage; otherwise record unavailable. Account-wide usage is not a precise task bill.

Measure the first three representative tasks: a mechanical batch, a backend behavior and a Flutter screen. Record model, actual/unknown token usage, duration, fix rounds and first-pass acceptance. Compare total accepted work, including lead and reviewer cost. No promised saving percentage is justified before that experiment.

Routing examples:

- Luna: change known labels in eight files; run a specified suite; transcribe reviewed fixtures.
- Terra: implement an endpoint or screen from a frozen contract; localize a reproducible failure.
- Sol: resolve incompatible contracts; determine transaction/reconnect semantics; adjudicate a risky migration.

For missing context, provide the missing schema/file. For repeatable test failure, investigate the first cause. For a transient service failure, one bounded retry may be appropriate. For rate-limit/account exhaustion, stop issuing calls until the real limit clears or the user changes available capacity. Switching Sol to Luna is not assumed to bypass shared account limits. Do not interpret every transport error as quota exhaustion.

## 11. Lead execution loop and recovery

1. Read applicable AGENTS instructions and run `bd onboard`. Capture existing dirty state and remote; preserve existing work.
2. Read this plan once and `HUB_PROTOCOL_EN.md`. Read the lead hub inbox; create a short STATUS recovery file and Beads mapping. Use the actual Beads CLI help for version-specific commands. Use real Beads IDs for hub tasks, and reconcile both at every gate.
3. Choose ready tasks with disjoint ownership. Issue task packets from `TASK_PACKET_EN.md`, binding the source revision, contracts, exact paths and acceptance.
4. Add/assign the ready task in the hub and dispatch explicitly named roles/models with minimum context. Workers take it with their own unique hub label. Workers never spawn their own teams. Record Codex identity, hub label and ownership before dispatch. Only accepted prerequisites are schedulable, even though the hub itself also permits done dependencies.
5. While workers run, resolve upcoming contracts, prepare fixtures/review packets and inspect accepted integration. Do not duplicate their implementation.
6. Collect the READY hub message/report, inspect actual changed/new files, freeze the reviewed paths and request independent review at the risk-appropriate model. Advice and creative content use directed hub messages and problem threads; a reviewer receives an explicit handoff.
7. Route concrete findings to the owner. Re-review the changed scope; preserve already valid evidence. Never suppress a finding merely because the plan proposed the design.
8. At a gate, stop writers, integrate and run required combined checks. After the real scoped commit exists, record hub done and the independent review/accept event, then update Beads/STATUS and post a hub sync. If a commit is blocked, keep READY with the blocker; never fabricate a commit to satisfy hub done. Claim completion only from inspected evidence.
9. Follow applicable repository commit/sync/push rules for authorized new work, checking the exact staged diff. Do not include old report/issue changes accidentally or retry a previously denied publication under a new route. If external publication remains blocked, preserve the deliverable locally and report that the repository handoff gate is incomplete.
10. Resume from Beads, STATUS and git/evidence, not conversation recollection. Do not re-dispatch completed tasks after compaction. Continue independent ready work around a real blocker.

Pause dependent work only for an unresolved requirement, unavailable capability or required external authorization. Routine reversible implementation decisions belong to the lead. Avoid making the user approve every task, test or dependency choice.

## 12. Definition of replacement completion

Completion requires all required parity items, reproducible Web/Android builds, reconciled content/data, authoritative scoring and access checks, room recovery tests, the accepted QR-based live team mode, the creative-writing/fact-check workflow, offline account isolation, editor/MCP validation parity, observed staging health, restore/rollback rehearsal, a documented operating owner, and an accepted cutover within authorization. A good demo of P11 is a milestone, not the whole rewrite.

No claim that these profiles will make a smaller model infallible. The practical mechanism is precise contracts, constrained edits, executable acceptance and selective escalation. The plan reduces unnecessary context and rework while retaining the product requirements.
