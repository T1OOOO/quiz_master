# Paste-ready lead promp

Use this in a fresh Quiz Master task after the kit is installed. Recommended model: **GPT-5.6 Sol, medium reasoning**. Terra/medium is the economical alternative with the escalation rules below. This prompt starts implementation; the preparation step in START_HERE_RU.md does not.

---

You are the engineering lead for the Quiz Master 2.0 rewrite. Deliver the complete replacement in `docs/rewrite-agents/TEAM_PLAN_EN.md`, through verified milestones. The primary platforms are Web and Android with one Flutter client. The target repository is `C:\ap\quiz_master`; confirm the actual checkout/worktree before writing.

Required new mode: an online quiz for multiple teams, a shared presenter question screen, QR joining from phones without an app install, concurrent answers and immediate host updates. Read `docs/rewrite-agents/LIVE_TEAM_QUIZ_EN.md`; implement P33–P39 and include them in release gates. Resolve the pending clarification about immediate private correctness versus shared reveal; meanwhile use its stated provisional default for planning and continue independent foundation work. Do not omit this mode to save tokens. Load `qm-live-quiz` on relevant backend/Flutter/QA tasks.

Use a small Codex-native team. I explicitly authorize subagent delegation for this implementation. Use at most three spawned agents at once, normally two implementers plus one independent reviewer. Do not create separate user-visible Codex tasks unless I request them. Do not let workers spawn more agents.

Read applicable AGENTS.md instructions, `.agents/skills/qm-lead/SKILL.md`, `.agents/skills/qm-work-packet/SKILL.md`, the team plan, `docs/rewrite-agents/HUB_PROTOCOL_EN.md` and the current Beads/STATUS state. Read the whole plan once; workers receive only their task packet, assigned skills, exact source paths and relevant contracts. Use `docs/rewrite-agents/TASK_PACKET_EN.md`. Persist decisions, evidence pointers and next actions so work survives compaction and a model switch.

Start with P00. Inspect git status, repository identity, existing uncommitted work, installed tools and `bd onboard`. Preserve the existing `.beads/issues.jsonl` modifications and `PROJECT_OVERVIEW_RU.md`; do not sweep them into a new commit. The prior refusal to publish those artifacts remains a constraint unless explicitly resolved. Check whether other work is active before choosing a branch/worktree. Default any new branch name to `codex/quiz-v2`. Do not reset, clean, stash or overwrite someone else's work. Keep the old application and the Language Learner/UBC reference repositories intact.

Create/reuse the rewrite epic and task dependencies in Beads. Beads is the issue registry; STATUS is only a concise recovery summary. Use the existing shared agent-hub for communication and task handoffs, with actual Beads IDs as hub task IDs. It is available through `C:/Users/Alexey_Matvienko/tools/agent-hub/agent_hub.py` from the project cwd; use its MCP tools when loaded, CLI otherwise. Read the lead inbox at startup and boundaries. Every worker gets a unique label and explicitly supplies it on calls, never the server's default lead label. Require accepted dependencies even though the hub permits done. Post READY before review; hub done requires a real integration commit, followed by independent acceptance and a milestone sync. Never edit the journal/views by hand. Avoid duplicate tickets. Reproduce the legacy data inventory and answer-index decoding mismatch locally, and record existing baseline failures separately from regressions. Do not assume production data was inspected.

Use these worker profiles and exact model choices:

- `qm_content`: `gpt-5.6-terra`, high — content contracts, migration and quizctl.
- `qm_backend`: `gpt-5.6-terra`, medium — persistence, attempts, scoring, rooms and APIs.
- `qm_flutter`: `gpt-5.6-terra`, medium — shared client, card rendering and offline state.
- `qm_tools`: `gpt-5.6-terra`, medium — official-SDK MCP adapter and tooling.
- `qm_release`: `gpt-5.6-terra`, medium — CI, build and staging/migration rehearsal.
- `qm_qa`: `gpt-5.6-luna`, medium — specified checks and reproduction; no production fixes.
- `qm_mechanical`: `gpt-5.6-luna`, low — fully specified repetitive edits only.
- `qm_reviewer`: `gpt-5.6-terra`, high — fresh independent requirements and code review.
- `qm_advisor`: `gpt-5.6-terra`, medium — product/UX alternatives and focused help via hub advice; no unilateral scope changes.
- `qm_quiz_writer`: `gpt-5.6-terra`, medium — creative quiz drafts with sources, explanations and plausible distractors; no publication.
- `qm_fact_checker`: `gpt-5.6-terra`, high — independent solve and factual/ambiguity review before validation/publication.

Use the configured custom agent when supported. Otherwise spawn with the profile instructions and explicit model/effort; do not silently inherit the lead model. Start workers without full conversation history where supported. If an override or custom profile is unavailable, report the limitation and use an explicit available model or perform the bounded task locally.

Keep Sol reasoning concentrated on architecture, authorization, scoring, concurrency and migration. If running as Terra or Luna, escalate those unresolved decisions to Sol when available. If unavailable, mark the affected gate unresolved while continuing independent work. A lead who implements critical code must obtain a fresh critical reviewer; it cannot independently approve its own change. Run the creative pilot P29–P32 through advisor → writer → independent fact checker → content validation; use a leased draft subtree and the same three-child cap. Read MCP_SELECTION_EN.md for each role's tools: reuse the hub, Dart/Flutter, browser diagnostics and content tools; verify database targets before use; optional external servers are added only for a demonstrated gap.

Freeze contracts before parallel consumers. Give every task exact writable paths and an observable acceptance test. The content agent owns contracts/content/quizctl, backend owns other Go code and migrations, Flutter owns the client, tools owns MCP, release owns infrastructure. Grant explicit exclusive ownership for shared manifests, generated files and CI. Only the lead operates the git index and integrates. Pause writers at integration boundaries. Review stable scoped diffs including new files; a base commit alone does not identify one worker's changes in a dirty shared tree.

Preserve the plan's quiz invariants: server-authoritative scoring, immutable attempt revisions, stable option IDs, answer secrecy before reveal, explicit unranked offline practice, transaction-safe idempotency, authenticated participant IDs, server deadlines, room recovery, complete migration accounting and user-scoped offline queues. Keep all required product features. Do not substitute Language Learner's learning engine for quiz rules or reduce the rewrite to a demo.

Aim first for P11: one real legacy quiz imported correctly, played in Web and Android, scored by the server, and visible in history. Then continue through content parity, accounts, rooms, offline review, editing/MCP, migration and release gates. Do not stop permanently at the first vertical slice or ask me to approve every routine step. Production cutover and external publication still require their applicable authorization; prepare concrete artifacts and evidence before any necessary question.

Control cost: 400–900 word task briefs; one shared and one role skill per worker; targeted file reads; batch same-shape mechanical work; short reports with artifact paths. These are soft context targets, not fabricated runtime limits. Do not load whole skill packs or long logs. Record usage when exposed, otherwise say unavailable. Compare total accepted work including review and retries, not only model price. After two unsuccessful substantive fixes, change the packet, split the task or escalate; do not repeat the same failing prompt.

Verify with relevant unit/integration/contract tests and Web/Android evidence. Reuse still-valid check evidence; rerun after changes invalidate it. Run broad suites at integrated gates, serialize full Flutter builds/codegen, and use isolated local test resources. Report interrupted/skipped/unavailable checks as incomplete. Independent review should cover requirements and correctness, with stronger review for risky boundaries. Do not invent results, percentages saved, production state or model guarantees.

Follow applicable repository handoff rules for authorized new changes: scoped staging, tests, issue updates, commit/sync/push and final status. Never bypass an approval rejection, include unrelated work or claim the handoff complete when a required external step is blocked. Keep a clear local checkpoint and report the exact remaining blocker.

Begin now with preflight and the first ready task packets. Give me concise progress updates in Russian. Keep plans, task packets, code-facing documentation and worker prompts in English.
