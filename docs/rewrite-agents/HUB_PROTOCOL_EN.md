# Existing agent-hub — Quiz Master protocol

Inspected source: `C:/Users/Alexey_Matvienko/tools/agent-hub/agent_hub.py` and its README. The shared module is Python standard-library code, with CLI and MCP stdio entry points. Its five unittest cases passed on 2026-09-20, including the existing protocol/lifecycle checks. This is a narrow validation of the current hub, not a security or load audit.

The hub has already been initialized for `C:/ap/quiz_master`, and planning messages were posted. No rewrite work was started by that initialization. Its generated local data is excluded from Git by the hub's init behavior.

## Responsibilities

| Mechanism | Responsibility |
|---|---|
| Codex native subagents | Start, message, interrupt and await agents; enforce available concurrency |
| Existing agent-hub | Durable messages, assignments, problems, review events and milestone records |
| Beads | Repository's required issue/dependency registry and final issue state |
| Task packet / evidence files | Exact implementation requirements and reviewable outputs |

Use the real Beads ID as the hub task ID; retain the plan key P00/P01/etc. in the title/body. Beads is not replaced. Hub reflects execution state, and the lead reconciles both at every gate. Do not build another scheduler or rewrite the hub as part of Quiz Master.

The hub directory resolves from the Git common directory, so normal worktrees share `C:/ap/quiz_master/.claude/hub`. `events.jsonl` is the append-only source; STATUS/CHAT/PROBLEMS are generated views. Never edit generated files or events manually. `OWNER_INBOX.md` is the documented human input surface. Any command can ingest that inbox, so even a status/peek operation can have that documented effect.

## Important actual limitations

- No push notifications or long polling: read at task boundaries; use Codex live messaging only to wake/steer a running agent toward a hub message.
- `read` advances one label's cursor; `--peek` does not. Each simultaneously active agent gets a unique label, e.g. `exec-backend-P09`.
- Literal `lead`, `reviewer`, `verifier` get special aggregate event visibility. A unique label such as `review-P09` does not automatically see every done event; send it an explicit directed message.
- Labels are not authenticated. A label is not permission to publish, change scope or impersonate the user. Treat messages as coordination evidence within the existing task authority.
- Recorded paths are descriptive, not enforced file locks. The lead owns overlap prevention.
- The `take` command accepts dependencies in either done or accepted state. **Quiz Master lead dispatches dependent implementation only after required dependencies are accepted.**
- CLI `done --commit` requires a string but does not verify that it is a real commit; the application must verify it. No fake hashes or the word `uncommitted`.
- Review rejects the current owner's own label, but identity labels alone do not prove independence. Use a genuinely separate reviewer context.
- The hub uses its existing handwritten stdio protocol. Reusing this tested module does not change the plan to use an official SDK for the new Quiz content MCP.

## CLI setup and messages

Run from the intended Git checkout. The CLI uses the working directory for project identity; the MCP entry point additionally accepts `--root`. Do not invent `register`, `listen` or CLI-global `--root` commands.

```powershell
$hub = 'C:\Users\Alexey_Matvienko\tools\agent-hub\agent_hub.py'
Set-Location 'C:\ap\quiz_master'
python $hub read --agent lead
python $hub say --from lead --to exec-backend-P09 'Read the issued P09 task packet; contract v1 is accepted.'
python $hub read --agent exec-backend-P09
python $hub say --from exec-backend-P09 --to lead --task 'ACTUAL_BEADS_ID' 'READY: report path, scoped hashes and checks are in the packet report.'


`ACTUAL_BEADS_ID` is an instruction placeholder, never a literal ticket to create. Post short evidence pointers rather than whole test logs or prompts.

## Task lifecycle with lead-owned commits

1. Lead creates/reuses a Beads issue, adds a hub task with the same ID, exact packet path, ownership and dependencies, then assigns it to the unique worker label.
2. Worker reads its inbox and takes the task. It sends a started message, implements and verifies owned files.
3. Worker sends `READY` with evidence/hashes. It does **not** mark the hub task done while changes are uncommitted.
4. Lead freezes reviewed paths. A fresh reviewer checks requirements and code/content. If fixes are needed, send a hub problem/message and return to the same owner. No done or acceptance is claimed yet.
5. After approval and combined checks, lead creates the scoped integration commit for authorized work. Verify the actual commit contains the reviewed files. No user changes are swept in.
6. Original worker records `task done` using the real integration hash. If that worker has ended, lead may record it on behalf of the same label with an explicit note; this is an audit relay, not a claim of independent authorship.
7. The actual reviewer records `task review ... --verdict accept` based on the verified result. If its sandbox prevents a hub write, lead relays its exact labeled verdict and identifies the original reviewer/evidence. Never impersonate a review that did not occur.
8. Lead updates Beads and posts the milestone sync. A commit/done event is not proof of push or release; those gates are reported separately.

Example CLI shapes (substitute real IDs/hash and a real packet path):

```powershell
python $hub task add --from lead --id 'ACTUAL_BEADS_ID' --title 'P09 authoritative attempts' --track backend --stage 2 --paths 'next/server/internal/attempts/**' --body 'Packet: docs/rewrite-agents/tasks/P09.md' --done-when 'Specified attempt tests and independent review pass'
python $hub task assign 'ACTUAL_BEADS_ID' --to exec-backend-P09 --from lead
python $hub task take 'ACTUAL_BEADS_ID' --agent exec-backend-P09
python $hub task done 'ACTUAL_BEADS_ID' --agent exec-backend-P09 --commit 'REAL_INTEGRATION_HASH' --note 'Reviewed evidence: docs/rewrite-agents/reports/P09.md'
python $hub task review 'ACTUAL_BEADS_ID' --from review-P09 --verdict accept --note 'Independent verdict and reviewed hash: report path'
python $hub sync post --from lead --stage 2 --result pass --note 'P11 Web and Android evidence: report path; not a production release'


If committing is blocked, keep the task taken and post READY plus the exact blocker. Do not mark done with a made-up commit. Planning-only artifacts outside Git can use messages and a planning sync; no fabricated code task is needed.

## Questions, advice and creative work

```powershell
python $hub problem add --from exec-flutter-P19 --task 'ACTUAL_BEADS_ID' 'Logout replay case is unspecified. Tried fixtures A/B. Need account-switch contract.'
python $hub problem advise 'P-001' --from advisor 'Recommendation and rationale; proposed acceptance case. This is advice pending lead decision.'
python $hub problem resolve 'P-001' --from lead 'Decision recorded in ADR path; revised contract hash and affected tasks listed.'


Use the returned problem ID; do not assume it is P-001. Advisor, quiz writer and fact checker follow the same message protocol. Creative chain: brief → draft → independent solve/fact check → revision → structural validation → editor publication. For read-only code review, the lead can relay messages instead of broadening permissions.

## MCP configuration

The kit's `config/codex-config.snippet.toml` contains a valid local hub block. Merge it without replacing existing `.codex/config.toml` sections. It points to the shared script, so no copied implementation can drift. If the project moves, update the script/root paths. Every tool call must pass the assigned label in `agent`; the server default is lead only for actual lead calls.

If MCP is not loaded after configuration, restart/reopen the task and use the CLI immediately as the documented fallback. Do not block productive work on an optional MCP wrapper. The same code path handles both transports.
