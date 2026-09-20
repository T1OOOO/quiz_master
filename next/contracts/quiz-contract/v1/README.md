# quiz-contract/v1 (proposed)

This is a proposed base contract. It is not published or accepted until lead review and the P33 live-team extension are accepted.

## Boundaries

- `schemas/draft-quiz.schema.json` is editor-only canonical content. `grading` is private.
- `schemas/published-bundle.schema.json` is a controlled/server bundle containing the canonical immutable public quiz/questions plus exactly matching private grading. Its SHA-256 input is the canonical JSON object with `bundle_sha256` omitted (UTF-8, sorted keys, compact separators).
- `schemas/public-question.schema.json` is the playable pre-reveal DTO. It cannot contain grading fields, explanations, accepted text variants, or correct answers.
- `schemas/reveal.schema.json` adds the displayed correct answer and explanation only after the permitted reveal phase. It never carries the full private text-variant key.
- `schemas/attempts.schema.json` freezes revisions, bundle version/hash, ordered option IDs and position mapping at attempt start; the pinned bundle must equal the controlled published bundle. A write binds attempt/participant/question revision/typed answer/idempotency payload to an accepted UTC receipt; finish history repeats pinned question revision and its receipt reference. `payload_digest` is SHA-256 of canonical UTF-8 JSON (sorted keys, compact separators) of exactly `attempt_id`, `participant_id`, `question_id`, `question_revision`, and `answer`; it excludes the idempotency key.
- `schemas/room-event.schema.json` is only the base envelope. P33 owns team admission, captain, scoring, standings and immediate-correctness fields. Base v1 recursively rejects them, including nested event data, and reserves a versioned extension design for P33.

## Scoring proposal

Single choice is one point only when the submitted stable option ID exactly matches the private key. Multiple choice is one point only when the submitted ID set exactly equals the key; there is no partial credit. Normalized text is one point only when its normalized value equals an explicitly accepted variant. The pipeline is: Unicode NFC, Unicode `casefold`, then collapse every Unicode whitespace run to one ASCII space and trim. There is no speed bonus. The server computes every result.

Reveal content is bound to the canonical private key and public option text for the same pinned revision. Text reveal exposes one permitted display answer only, never the accepted-variant list. P33 must decide whether a team may receive correctness before the shared reveal. This v1 contract neither permits a pre-reveal correctness payload nor decides that product policy.

## Check

From `C:\ap\quiz_master`, run this twice; the stdout and `summary.json` are deterministic:

```powershell
python -B next/contracts/quiz-contract/v1/check_contract.py --write-summary
```

The checker is intentionally standard-library only. It parses and verifies declarations for all seven schemas, enforces their closed consumer shapes through the executable validators, validates cross-file invariants/scoring, and proves each named negative fixture is rejected. P08 must replace/augment this narrow executable specification with full JSON Schema dialect validation, canonical bundle hashing/publishing, source import validation, and cross-language conformance tests.
