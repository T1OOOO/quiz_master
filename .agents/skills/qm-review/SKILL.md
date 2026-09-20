---
name: qm-review
description: "Independently review Quiz Master code and evidence against exact requirements and risky boundaries."
---

Read the task brief, relevant contracts, stable scoped diff including new files, nearby source and implementation evidence. Do not load the whole history or accept the implementer's conclusion without inspection. Check the actual changed files match the packet.

Return two verdicts: requirements compliance and code quality. Prioritize data correctness, ownership, answer secrecy, transaction/retry behavior, migration safety and platform regressions. Report each actionable issue with file/line, trigger, consequence and smallest adequate correction. Avoid blocking on personal style or speculative abstractions.

Critical cases include nonzero answer mapping, shuffled option IDs, public DTO leaks, stale content revisions, double scoring, time boundaries, room sequence recovery, offline account contamination and legacy leaderboard provenance. Request missing evidence for unresolved behavior. Distinguish a proven issue from a hypothesis.

A prior valid test need not be rerun unchanged just to generate another log. New code or invalidated evidence does need verification. Read-only reviewers return the verdict to the lead; they do not patch, commit or edit another agent's report. A fix is re-reviewed only over its changed scope unless it invalidates a wider guarantee.

Use a fresh reviewer instance. Critical design receives Sol review/adjudication; a lead who wrote the code cannot count itself as independent. Follow the hub acceptance sequence after the real commit. Minor deferred work is visible in Beads, never silently discarded.
