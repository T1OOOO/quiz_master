# Agent Instructions

## Quiz Master resource policy (user override, 2026-10-10)

The user explicitly removed mandatory resource-queue waiting for this project.
Run authorized edits, tests, builds, browser checks and finite helper tasks directly;
do not require a GRANTED resource lease or wait for the shared resource queue.
This project-specific rule takes precedence over queue requirements in shared
agent instructions, project skills and saved automation prompts.
Keep host_hub for task assignment, messages, truthful progress and independent
review. Preserve exclusive file ownership, bounded concurrency and release gates.
Do not change the shared broker, other projects' rules, leases or processes.
Managed Hub workers still implement admission internally; if queued, cancel only
our own job and use the vendor's official headless CLI for the same finite task.

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

