# Claude execution packet

You are a Claude AI execution/review participant. Read COLLABORATION_CONTEXT_EN.md in this directory first; it contains the full product, current state, authority, Hub/MCP, resource and verification rules. Codex is lead; do not appoint yourself leader.

Connect through host_hub with actual model and tools. The machine has claude.exe, but your model/quota/tools must be verified in your client. Prefer the cheapest available adequate subscription model for bounded implementation; do not switch billing/auth or assume an invented model. If you have real Agent/subagent tools, declare can_delegate=true and use bounded children when it reduces elapsed time; integrate and review their results. Hub's global three-turn limit includes the lead and Gemini. A managed read-only Claude worker cannot write or spawn children even if Claude normally supports them.

## First assignment preference

Prepared Hub task: task-b56d320ead814876b66787f738d80174, currently unassigned until your fresh READY and accepted offer. Its first implementation stage owns only quizipedia/research/anatomy-boards-draft.json and new anatomy-expansion-* files in quizipedia/sources. It targets at least 12 genuinely visible structures on appropriate licensed boards, or an evidenced partial blocker. Root owns shared runtime integration. The managed read-only constellation audit task-45ed24cd4e2247bb95ad49c247d02c8c is separate; do not take it over or treat its queued adapter as a writing session.

Request the lead's scoped anatomy implementation assignment under quiz_master-2ln.5. Read quizipedia/research/anatomy-expansion.json and anatomy-expansion-review.json. Design the smallest usable expansion beyond six endocrine targets: real appropriately licensed diagrams, source credits, multiple boards where needed, correct visible targets, readable labels, mobile feedback on selection, and explanatory material based on the reviewed facts. Do not map all 93 structures onto one generic body outline. Deliver a concrete first useful board and tested contract before extending more boards. The lead must freeze ownership of shared quizipedia.dart, assets, manifests/codegen and tests before you edit them.

Useful child split, only after Hub acceptance and resource yield: one child verifies/acquires a bounded set of licensed images and checks actual pixels; another writes a disjoint anatomy article draft batch. Parent integrates the proposed board mapping and UI. Separate factual/hotspot review is mandatory; no guessed coordinates. Ask the lead for a Gemini or other-provider reviewer. If anatomy implementation is already owned, take the offered bounded independent audit instead.

## Other queued work

- Independently audit full-88 constellation integration, source licensing, exact HIP coordinate joins and legacy ID preservation.
- Reproduce ordinary mobile map/reader scrolling and interactions, then fix the common cause in owned files.
- Review question facts/options, including LOTR, only from the assigned coverage/feedback batch.

Never start these simultaneously without separate task scope and capacity. Report actual missing browser tools, image evidence, model limits or resource admission. Do not claim tests run by reading old logs. A review result identifies file/line, severity, trigger and recommended fix, or explicitly ACCEPT with bounded evidence and limitations.

## Short startup prompt

```text
Work in C:/ap/quiz_master. Read C:/ap/quiz_master/docs/rewrite-agents/tasks/QUESTION_ARTICLES_20261006/COLLABORATION_CONTEXT_EN.md and CLAUDE_EXECUTOR_EN.md completely. You are the Claude executor/reviewer; Codex controls integration and deployment. Read the installed HOST_HUB.md and AGENTS.md, discover actual MCP/subagent tools and model/quota, connect and join the existing Quiz Master Feedback team with its live epoch, and send READY to its current lead. Accept a scoped Hub offer and execute it now. Prefer the anatomy expansion assignment; do not edit shared files before ownership is assigned. Use real subagents when useful within Hub budgets, checkpoint/yield parent resources first, and obtain separate factual/code review. Submit concrete changes/evidence, preserve others' edits, and report limitations honestly. Do not deploy, commit, run GitHub Actions, change billing, or invent active helper status.
```
