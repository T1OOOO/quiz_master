# Task packet — copy one per bounded assignmen

Fill every applicable field before dispatch. These placeholders are intentional template fields.

```tex
TASK: <planning key + actual Beads ID>
ROLE / MODEL / EFFORT: <explicit profile, exact model ID, effort>
HUB: <real Beads ID, unique agent label, lead/reviewer recipient labels>
WORKSPACE: <absolute path; shared checkout or worktree>
BASE: <commit + relevant pre-existing dirty paths/hashes>
CONTRACT: <version/hash and exact fixture/schema paths>
GOAL: <one observable behavior and why it matters>
READ FIRST: <packet, shared skill, role skill, 3–8 relevant source paths>
OWNED PATHS: <exact files/directories; new files explicitly permitted>
SHARED FILE LEASE: <none, or manifest/codegen/migration owner and scope>
DO NOT TOUCH: <other owners; legacy/reference repositories; pre-existing changes>
REQUIRED BEHAVIOR: <precise inputs, outputs, errors, edge cases>
ACCEPTANCE: <commands/scenarios with working directory and expected result>
EVIDENCE: <assigned report path and artifact directory>
DEPENDENCIES: <completed issue/contract; mocked fixture allowed only if stated>
MCP/TOOLS: <needed capabilities, local/staging target, available fallback>
ESCALATE: <missing contract, out-of-scope edit, two failed fixes, access/tool blocker>
CONTEXT BUDGET: <soft target; return pointers instead of large logs>
REPORT: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED


Worker instructions: read the packet and assigned skills; inspect only relevant code; perform the authorized implementation and meaningful checks; do not spawn agents or operate the shared git index. Read your hub inbox, take the assigned task, and post READY/blocker messages under your own label. Ask the lead about an ownership/contract change. Save evidence in the assigned report and return a short result. Hub done waits for a real integration commit and acceptance follows independent review.

Report shape:

```tex
Status / task / model:
Behavior delivered:
Changed and new files:
Contract/version consumed:
Checks: command, cwd, exit code, result, evidence path, reviewed hashes/revision.
Missing or skipped checks:
Concerns/blockers with exact file and reproduction:
Usage if exposed; otherwise unavailable. Fix rounds and duration:
Next required dependency/action:


Lead review packet: task brief + scoped diff including untracked new files + current source/contract pointers + evidence. Record a stable revision or hashes and stop writes to reviewed files. A reviewer returns requirements verdict, quality verdict and concrete findings; the implementer's self-review is not the independent verdict.
