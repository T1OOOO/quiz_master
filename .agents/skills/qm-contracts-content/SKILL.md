---
name: qm-contracts-content
description: "Design Quiz Master card and event contracts and migrate legacy quiz content with answer integrity."
---

Trace quizzes JSON through the current decoder; verify correct_answer versus correct_answer_index with a fixture whose answer is not option zero. Recompute counts at the actual revision and reconcile every legacy ID. Keep unknown difficulty unknown; empty legacy correct_multi does not prove multi-choice content exists.

Define draft/published schemas, stable question/option IDs, revisions, source metadata, media references, answer type and scoring fixtures. Separate private grading data from public question DTOs and reveal payloads. Freeze attempt snapshots and bundle hashes; republishing cannot mutate an existing attempt.

Build quizctl as the shared import/validate/build/diff path. Deterministic output, explicit errors, atomic publication and no silent partial import are required. Tests must catch wrong nonzero indices, out-of-range/missing answers, duplicate IDs, 4/5/6 choices, malformed revisions and stale references. SQL migrations remain with the backend owner.

Canonical content and executable schemas are yours; creative draft subdirectories are leased exclusively to qm_quiz_writer while that task runs. Do not modify those drafts concurrently. Import only after independent content review, preserving sources and the fact-check verdict. Difficulty remains estimated until measured; never invent calibration.

Borrow Language Learner's versioning/validation separation, not its whole DSL, linguistic voice or storage assumptions. Exact question examples are fixtures, not evidence that real-world claims are true.
