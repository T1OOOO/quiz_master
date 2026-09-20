# Selected skills and provenance

Selection date: 2026-09-20. Criteria: direct task fit, identifiable upstream author, concrete workflow, small context footprint, compatibility with the Quiz stack, verifiable outcomes and licensing/packaging clarity. Directory popularity was a discovery signal, not a quality guarantee. The [skills.sh directory](https://www.skills.sh/) and actual upstream sources were inspected.

The kit contains **original focused `qm-*` skills**, not a vendored copy of these repositories. External skills are references to consult selectively; nothing was globally installed. This avoids pulling incompatible workflows, unavailable dependencies and large generic instructions into each worker.

## Best fit selected for each role

| Role | Selected external skill/reference | Local Quiz skill and adaptation |
|---|---|---|
| Lead | [obra: subagent-driven-development](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md) | `qm-lead`: bounded briefs, model routing and independent review; adapt to disjoint parallel tracks and the existing hub/Beads |
| Content/contracts | [obra: test-driven-development](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md) plus Language Learner content contracts | `qm-contracts-content`: executable conversion/contract fixtures; no mechanical requirement for tests on documentation |
| Backend | [samber: golang-testing](https://github.com/samber/cc-skills-golang/tree/main/skills/golang-testing) and [golang-error-handling](https://github.com/samber/cc-skills-golang/tree/main/skills/golang-error-handling) | `qm-go-backend`: behavior-based tests and error context; no mandatory gotests, oops, testify rewrite or nested audit team |
| Flutter | [official Flutter architecture skill](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-apply-architecture-best-practices) and [widget tests](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-widget-test) | `qm-flutter`: separate UI/data concerns and test real interactions; retain approved Riverpod stack, not a borrowed DI framework |
| MCP tools | [Anthropic: mcp-builder](https://github.com/anthropics/skills/blob/main/skills/mcp-builder/SKILL.md) | `qm-mcp`: useful tool boundaries, concise outputs and evaluable workflows; Quiz owns permissions and publication semantics |
| QA | [obra: verification-before-completion](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md), [official Flutter integration tests](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-integration-test) | `qm-qa`: fresh evidence, explicit skips and platform checks; no pointless repeated full suites |
| Code reviewer | [Addy Osmani: code-review-and-quality](https://github.com/addyosmani/agent-skills/blob/main/skills/code-review-and-quality/SKILL.md) | `qm-review`: requirements plus correctness/readability/architecture/security/performance, with concrete findings |
| Release | [OpenAI: gh-fix-ci](https://github.com/openai/skills/blob/main/skills/.curated/gh-fix-ci/SKILL.md) for failed Actions; verification-before-completion for gates | `qm-release`: reproducible artifacts and migration rehearsal; GitHub skill applies only to an actual failing Actions job |
| Mechanical helper | [official Dart static analysis skill](https://github.com/dart-lang/skills/tree/main/skills/dart-run-static-analysis) plus verification-before-completion | `qm-mechanical`: exact edits and narrow checks; language-specific skill only when editing that language |
| Product advisor | [obra: brainstorming](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md) | `qm-advisor`: compare a few options and identify the missing decision; no repeated full design approval ceremony |
| Creative quiz writer | [dmccreary: quiz-generator](https://github.com/dmccreary/claude-skills/tree/main/skills/quiz-generator), compared with [SkillMedev: quiz-generator](https://github.com/SkillMedev/skills/blob/main/skills/quiz-generator/SKILL.md) | `qm-quiz-writing`: source-grounded questions, plausible distractors and explanations in Quiz's own draft model |
| Fact checker | Quiz-generator's quality checks plus independent-review/verification practices above | `qm-fact-check`: a separate original rubric for independent solving, factual evidence and ambiguity; no inspected upstream skill alone establishes general factual reliability |

For the creative role, dmccreary is the strongest inspected subject-specific reference, not a drop-in install: its declared license is CC BY-NC 4.0, its workflow targets intelligent textbook chapters, and its MkDocs/fixed option format conflicts with Quiz. It is not bundled. The short original Quiz instructions use general question-writing principles and the project's own requirements; review licensing before any future wholesale reuse of third-party material. SkillMedev is an alternative reference, not an installed dependency.

The baseline upstream recommendations are **not all activated at once**. Read the `qm-*` role skill first; consult a named upstream skill for a task that needs its detail. New upstream downloads must be reviewed at a pinned revision before installation. Do not run a command that installs an entire skill pack simply because the repository offers one.

## Useful neighboring-project evidence

| Local source | Adopt | Do not copy |
|---|---|---|
| `C:/Users/Alexey_Matvienko/AntigravitiProjects/language_learner/.dsh/skills/ll-team/SKILL.md` | Explicit role briefs, separate content writer/reviewer/advisor, concrete gate handoff | Provider-specific chains, absent shim paths, automatic interpretation of all transport errors as quota |
| Language Learner `.agents/skills/golang-testing/` and `golang-error-handling/` | Observable Go tests and contextual errors | Unnecessary dependencies, broad subagent fan-out, unrelated rules |
| Language Learner `.agent/skills/flutter-ui-verification/` | Inspect actual screenshots and runtime errors | Claiming a screenshot exists without seeing it; forcing browser-only evidence for Android |
| Language Learner contracts and card components | Draft/publish separation, immutable snapshots and reusable renderers | Whole linguistic DSL, Red Cat tone, pronunciation/SRS assumptions |
| `C:/Users/Alexey_Matvienko/AntigravitiProjects/universal_block_connector_next/AGENT_PLAN.md` | Frozen contracts, file owners, stage gates and serialized full builds | Its ban on Riverpod/Freezed/codegen; Qt migration-specific rules |
| UBC `.agents/skills/flutter-apply-architecture-best-practices/` | Selected layered architecture guidance | ChangeNotifier/GetIt recipes that conflict with the chosen stack |
| `C:/Users/Alexey_Matvienko/tools/agent-hub/README.md` and `agent_hub.py` | Actual shared board, per-label cursors, problems/advice and review events | Treating labels as authentication, done as accepted, or hub paths as enforced file locks |
| Local `ponytail`, code-review and debugging skills | Prefer existing facilities, fix a proven cause, review a scoped diff | Cutting required features to appear minimal; loading all generic policies into every packet |

No Language Learner, UBC or global skill configuration was modified. The actual shared hub was initialized for Quiz and used for planning messages.

## Platform documentation supporting the configuration

- [OpenAI model guidance](https://learn.chatgpt.com/docs/models): source for model family positioning; the Sol/Terra/Luna task routing here is our engineering recommendation, not a measured guarantee.
- [Codex subagents](https://developers.openai.com/codex/multi-agent): custom TOML profiles, explicit models and concurrency settings; a team can consume more total tokens than one agent.
- [Codex skills](https://developers.openai.com/codex/skills): progressive disclosure and repository skill discovery.
- [Flutter architecture](https://docs.flutter.dev/app-architecture/guide): UI/data separation with an optional domain layer; adapt the structure to actual complexity.
- [Drift Web support](https://drift.simonbinder.eu/platforms/web/): Web storage has platform setup requirements; app-shell offline behavior is a separate concern.
- [MCP SDK](https://github.com/modelcontextprotocol/typescript-sdk): official implementation base for the new content adapter.

The plan's exact token savings, throughput, factual quality and runtime activation are not benchmarked. Syntax checks, local hub tests and inspected sources are reported separately from those unmeasured outcomes.
