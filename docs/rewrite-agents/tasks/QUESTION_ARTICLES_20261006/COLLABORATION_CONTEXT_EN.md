# Quiz Master: shared execution context

You are an AI execution/review agent helping the Codex lead finish an existing product. This is not a greenfield project. Read this document, your provider packet, the root AGENTS.md, and the applicable skill before acting. Snapshot: 2026-10-07; verify live state rather than treating this snapshot as current authority.

## Authority and objective

The human wants the lead to coordinate Claude and Gemini helpers, use cheaper adequate models, and finish the outstanding Quizipedia, articles, feedback, and publication work. The human now explicitly permits bounded subagents; this supersedes the older project skill's blanket prohibition on worker children for this assignment. It does not remove Hub budgets or authorize uncontrolled fan-out. Codex remains lead. Helpers implement scoped tasks and review another provider's work.

Workspace: C:/ap/quiz_master, native Windows PowerShell. Branch: codex/quiz-v2. Remote: https://github.com/T1OOOO/quiz_master. Team: Quiz Master Feedback 2026-10-06, team-2ed452959d1b4bdfa7ec7c94fb8584ce. Snapshot leadership epoch: 2; lead session: session-5935a39af6104fcfb3bf6353e4d807ae. Discover the current epoch/lead with hub_team list, because reconnects can change them. Another team, Quiz Master Content Wave, also works here: do not seize its leadership or touch its assignments.

The human explicitly forbids GitHub Actions. Production publishing is already authorized, but only the lead performs deployment after gates. Helpers must not deploy, merge, alter billing/authentication, auto-upgrade models, resolve real feedback prematurely, or send messages outside this authorized agent team.

## Product and actual state

Quiz Master is a Russian-first quiz application with a Flutter Web/Android client, Go backend, ordinary quizzes, Study, and interactive Quizipedia: countries/maps/flags, anatomical targets, landmarks, and constellations. Users need useful explanations and educational mini-articles linked to actual questions, with several trustworthy links at the end. Question answer options must be plausible and comparable in length, without parenthetical giveaways. Difficulty is 1–10, grouped Easy/Medium/Hard/Nightmare; descriptive searchable tags should support cross-topic selections, including countries and ingredients. These broader requests are existing scope, not permission to regenerate reviewed content indiscriminately.

Committed baseline 9c15384d81c58b559b6cf66bcc8138962f059e42: 30 accepted mini-articles, shared reader, map badge scaling fix, and reviewed expansion research. At that baseline Flutter analyze passed, 111 Flutter tests passed, Web build passed. These results do not certify subsequent changes.

Current local uncommitted constellation integration contains all 88 IAU constellations, 681 actually sourced HYG stars, 80 Stellarium modern line patterns and eight preserved pilot patterns. Six Python catalog checks passed in .run/feedback_triage_20261006/articles-data-export-check.log. The current build/web still comes from the earlier 30-article/eight-constellation build: do not package it as the 88-object release. Runtime UI still needs a usable searchable picker and new browser checks. Official IAU constellation boundaries and educational stick figures are different things. Serpens is one constellation with two regions. Do not invent star coordinates or copy unlicensed illustrations.

Anatomy research contains 93 reviewed educational structures and 27 sources, but runtime still has six endocrine targets. Six candidate diagram pages have licensing evidence; zero new certified hotspots exist. Research is not a completed interactive anatomy atlas. Do not claim these 93 exhaust human anatomy. A point must lie on the visible intended structure; generic body outlines cannot prove organ placement.

Article catalog has 30 accepted records. Thousands of question mini-articles remain, tracked by coverage.py. The previous missing count 4245 predates 80 added constellation targets; recompute rather than quoting it as current. Gemini's first new eight constellation articles are reserved: and, aql, peg, per, cep, dra, tau, gem. Do not duplicate an existing assignment without lead reassignment.

Production https://quiz.kotopedia.org is still build quiz-2026.10.06-feedback-e0f89cf. It has 126 ordinary packs/3958 questions, Study 6 packs/120 questions, and the previous atlas (20 training countries, six endocrine targets, six landmarks, eight constellations). Real feedback remains open until the published fix is checked. Do not expose feedback admin tokens, credentials, personal report data, or private dashboard links.

## Read these existing files in order

1. C:/ap/quiz_master/AGENTS.md and C:/Users/Alexey_Matvienko/tools/agent-hub/HOST_HUB.md. The latter is the installed protocol; ignore its legacy compatibility wording where AGENTS.md explicitly retires old per-project Hub tools.
2. C:/ap/quiz_master/.agents/skills/qm-work-packet/SKILL.md, then qm-flutter, qm-quiz-writing, qm-fact-check, qm-review, or qm-release as applicable. Resolve referenced files; if a skill reference such as TEAM_PLAN_EN.md is missing, report it and use actual AGENTS.md plus this packet instead of inventing contents.
3. docs/rewrite-agents/tasks/QUESTION_ARTICLES_20261006/PLAN_RU.md and RELEASE_20261007.md; use fresh source/logs to resolve stale snapshot text.
4. Your accepted task's source files and tests. Use bd --no-daemon show/ready; existing issues quiz_master-2ln (articles), -4dv (reader), -2ln.4 (all constellations), -2ln.5 (anatomy), -2ln.1 (remaining articles) track this work. Let the lead update shared Beads rows; do not create competing task registries.

## Updated shared MCP architecture

All clients use one shared local proxy, http://127.0.0.1:9800/servers/<name>/mcp, for universal servers. Prefer callable tools over ad hoc replacements:

- memory: search_nodes before repeating research, add_observations for reusable nonsecret knowledge.
- ripgrep: search/advanced-search/count-matches/list-files; ast-grep for syntax-aware work. The current ripgrep wrapper produced invalid Windows quoting even with C:/ paths: if reproducible, use native rg as fallback and report it. Never search C:/ through WSL /mnt/c/.
- fetch for primary-source pages; context7 for library docs; godot-docs only if genuinely relevant.
- agent_limits: check_agent_limits to inspect available quotas before paid workers; unavailable or unknown is not zero cost or unlimited budget. Avoid printing credentials in connector responses.
- host_hub is deliberately per-session stdio because it establishes identity. Do not replace it with a shared anonymous connection.

Per-client servers: agent_browser, chrome_devtools, dart_flutter, graphify, git, openaiDeveloperDocs and project MCPs as actually exposed. language_learner is a reference project, not the Quiz Master editing destination. Retired MCPs (ruff, pyright, jq, ssh, docker, postgres, redis, kubernetes, playwright, task_master, sequential_thinking, obsidian, gopls, content_toolkit) use native terminal tools when needed; do not reconnect obsolete servers.

Inventory your actual callable tools, client skills, configured provider/model, browser access, editing access and genuine subagent tools. Advertise only what exists. Installed executable or ONLINE presence is not an active model turn. The lead observed claude.exe installed with user default opus[1m], but has not verified an active interactive Quiz Master Claude helper; the later live-discovery paragraph records a quota snapshot. Antigravity Gemini previously declared gemini-3.8-flash with read/research/draft_json and no delegation; medium thinking was not confirmed. Updated capabilities must come from the running client, not these old declarations. Antigravity previously had only host_hub added; do not assume its other nine server entries are the universal set. Reconnect MCP after configuration updates; report missing tools rather than silently rewriting global configs.

## Hub execution protocol

Live discovery on 2026-10-07: claude --help exposes agent/agents, MCP, model and effort options; claude agents --json found no interactive Quiz Master Claude session. This is evidence of installed client features, not proof that every child tool is callable in your turn. The agent_limits connector reported Claude's five-hour usage 17%, seven-day usage 33% (snapshot updated 10:56:54), and Antigravity available with no exhaustion recorded. These are snapshots, not guaranteed remaining billing budget. A finite managed Claude Sonnet constellation audit was requested through Hub and is QUEUED/OLDER_REQUEST_WAITING; it has not begun a model call. A native helper is reviewing these startup documents independently. Do not describe either dispatch as completed work.

Call hub_help, then hub_connect with project_root C:/ap/quiz_master, actual provider/model and capabilities. can_delegate=true/max_children=2 only when real child execution tools exist. List/join the existing team with ready=true; send the current lead READY with your session ID, capabilities, model, current task/checkpoint and quota limitations. Read/process events then ack the returned cursor. Search history with FTS5 before asking what was decided.

Accept one offered task. Validate its current epoch, allowed paths and acceptance criteria. Create scoped child tasks with parent_task_id only while holding legitimate delegated authority; children inherit a subset of the parent's paths. At most two children per capable executor, depth two, eight accepted attempts per root task, three active turns globally including lead and all descendants, one heavy operation, one browser operation. When the lead, Claude, and Gemini are all actively working, they fill the active-turn cap: verify live task/activity state, then checkpoint and yield a parent before a child runs. Never launch unregistered/unleased children or hold resources they need. Existing ready sessions get offers first. A Hub task does not itself launch a model session.

Obtain a complete covering lease: interactive 300 seconds for bounded text/read work (256–512 MiB, path: exclusive writes, read: shared reads); standard 30 seconds with renewal about every 10 seconds for heavy/build/browser work. Use the exact live hub_help schema; disk_bytes maps returned volume names to future growth. QUEUED is not permission. The human already authorized lightweight reads/edits without the resource queue for this task; explicitly record use of that exception if admission is blocked. That exception does not cover tests, builds, browser automation, or child process work. Never adjust broker thresholds or reconcile another project's lease. Release only after operations are quiescent. Expired owned leases require verified-stop evidence and owner reconcile, then a new request.

hub_worker managed adapters are read-only, cannot delegate and may have restricted MCP access (Claude strict empty MCP, Gemini host_hub only). Use them for finite audits, not implementation. The old managed Gemini CLI attempt failed with exit 55 (auth/workspace trust); do not repeat or bypass approvals. Use the human's Antigravity Gemini session.

Keep activity truthful and send START, checkpoint, READY-for-review. Submit changed paths, exact revision/hash, commands and exit codes, opened source evidence, artifacts and limitations. Independent review must actually occur in another provider session; labels are self-reported, not authentication. Never equate process exit with acceptance. hub_wait is at most 30 seconds and cannot wake a finished desktop turn; checkpoint IDLE and state that a real client resume is required. No extra per-worker recurring polling automation.

## Ownership, validation and handoff

You are not alone. Preserve unrelated dirty work, especially docs/rewrite-agents/content20, study/check_reader.py, PROJECT_OVERVIEW_RU.md, attachments and other Beads rows. Before editing take a scoped snapshot/diff and a covering lease or record the established light-edit exception. Do not git add ., restore/clean/reset/stash someone else's files, commit or push as a helper. The lead owns integration, catalog manifests/codegen, shared article publication, Beads merge, final commit/push and deployment. A task may explicitly delegate a narrower subset later.

Use existing helpers and Flutter controls. Prefer the current country-search dialog for a constellation picker, not a new UI framework. Add no dependency merely for basic filtering. Validate trust-boundary data, maintain accessibility and usable mobile touch targets, and verify ordinary scrolling/tapping. Previous browser evidence confirmed map selection/search and readable badges; wheel/drag with Flutter's semantics overlay remained unconfirmed. A DOM scroll reaching article sources is not evidence that ordinary touch or wheel works.

Article draft schema: qm-question-articles/v1. Reuse study/question_articles/drafts/constellations.json as exact example. IDs and question revisions must match coverage/source; use 150–230 informative Russian words for the first Gemini batch, 2–5 genuinely opened primary HTTPS sources with accessed/supports fields, target_refs, question_refs, known tag_ids, status=draft. No answer spoilers before submission. Do not mark drafts accepted or self-review. Importer study/question_articles/build.py enforces independent review and provenance. Root handles build.py --write/--check and coverage.py under appropriate leases.

For code, leave a meaningful regression check, run only relevant checks under a grant, then broaden for integrated release. Root performs final Flutter analyze/test/Web build, mobile/desktop interaction checks and source/built asset parity. No stale build packaging. Staging/rollback must preserve existing server data and PVC. Root must land only owned stable changes, git pull --rebase, bd sync, git push, verify upstream and clean owned stashes. Real feedback closes only after published verification.

## Completion stages

1. Discover live helpers/capabilities; accept disjoint tasks and explicit ownership.
2. Finish 88-constellation UI and independently sourced articles; develop reviewed anatomy boards and useful object coverage.
3. Process feedback and remaining question-linked articles in bounded batches from the coverage list, with separate factual/options review.
4. Independent review, relevant tests, integrated release gates, actual mobile UX exercise.
5. Lead commits/pushes, packages fresh artifacts, deploys and verifies production; report remaining gaps honestly.

Start the first accepted stage now. Do not finish with a proposed plan when authorized scoped work can be performed. Escalate only a concrete blocking question; continue independent work meanwhile.
