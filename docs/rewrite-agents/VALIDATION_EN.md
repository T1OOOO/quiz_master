# Validation evidence for the planning ki

Date: 2026-09-20. Scope: planning artifacts and the existing hub; no application implementation or production verification.

| Check | Observed result |
|---|---|
| Python `tomllib` parsing | 11 custom-agent TOML files and the project configuration snippet parsed successfully |
| Profile required fields | Names, descriptions, explicit models/efforts and developer instructions present; referenced role skill directories exist |
| Skill creator's `quick_validate.py` validator | All 14 skill folders passed frontmatter/name validation |
| Text integrity | UTF-8 readable, no replacement characters, balanced Markdown fenced blocks |
| Kit document references | Concrete English/Russian kit document names resolved in the package |
| Planning dependency graph | Parsed P00–P39 directly from the plan/live-mode task tables: 40 tasks, no cycles. Explicit checks for P33 before P05/P06, P35 before P25, and P25/P32/P38/P39 before P26 passed. See `dependency-check.json`. |
| External sources | 29 unique linked source URLs returned HTTP 200 during a HEAD check; details in `link-check.json` |
| Existing hub regression checks | `python -m unittest test_agent_hub.py` in the shared hub directory: 5 tests, OK |
| Real Quiz hub use | Initialized the project board; exchanged planning/research/review messages through the CLI; no fake done/commit events |
| Independent plan review | A separate Terra reviewer identified release-dependency gaps, team-contract ordering and missing admission/result-access requirements. Corrected the formal P05/P06/P25/P26 dependencies and P33/P34 requirements before packaging. |
| Repository status | Existing modified `.beads/issues.jsonl` and untracked `PROJECT_OVERVIEW_RU.md` preserved; application source unchanged |

The dependency checker is not a proof of complete scheduling semantics. Source URLs may change after this date; HTTP success is not an endorsement. Skills were written specifically for Quiz rather than bulk-copied from upstream packs.

The profiles are staged in this kit, not installed into the project's discovered agent directories. Their syntax is verified; actual Codex profile discovery and each role's active model/tool list require a fresh task after installation. No optional MCP service was installed. The shared hub CLI is working; the supplied MCP configuration has not been activated in this task.

Not claimed: rewrite completion, Web/Android builds, production data correctness, connected Quiz database, measured team capacity/latency, perfect quiz facts, or a percentage of token savings. Those require the implementation and acceptance gates in the plan. The immediate-correctness versus end-of-round reveal detail remains a recorded pending clarification.
