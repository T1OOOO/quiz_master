# quiz-contract/v1 (proposed)

This is a proposed base contract. It is not published or accepted until lead review and the P33 live-team extension are accepted.

## Boundaries

- `schemas/draft-quiz.schema.json` is editor-only canonical content. `grading` is private.
- `schemas/published-bundle.schema.json` is a controlled/server bundle containing the canonical immutable public quiz/questions plus exactly matching private grading. Its SHA-256 input is the canonical JSON object with `bundle_sha256` omitted (UTF-8, sorted keys, compact separators).
- `schemas/public-question.schema.json` is the playable pre-reveal DTO. It cannot contain grading fields, explanations, accepted text variants, or correct answers.
- `schemas/reveal.schema.json` adds the displayed correct answer and explanation only after the permitted reveal phase. It never carries the full private text-variant key.
- `schemas/attempts.schema.json` freezes revisions, bundle version/hash, ordered option IDs and position mapping at attempt start; the pinned bundle must equal the controlled published bundle. A write binds attempt/participant/question revision/typed answer/idempotency payload to an accepted UTC receipt; finish history repeats pinned question revision and its receipt reference. `payload_digest` is SHA-256 of canonical UTF-8 JSON (sorted keys, compact separators) of exactly `attempt_id`, `participant_id`, `question_id`, `question_revision`, and `answer`; it excludes the idempotency key.
- `schemas/room-event.schema.json` is only the base envelope. P33 owns team admission, captain, scoring, standings and immediate-correctness fields. Base v1 recursively rejects them, including nested event data, and reserves a versioned extension design for P33.

## HTTP selection (SQLite collection)

`GET /v1/catalog?quiz_id=<canonical-id>&difficulty=<easy|medium|hard|nightmare>`
optionally returns only the requested difficulty band from that pack. `POST /v1/attempts`
accepts the closed body `{"quiz_id":"<canonical-id>","difficulty":"hard"}`
and pins that pack's immutable bundle/revisions. Numeric `difficulty_level` is
optional and exact (1–10); its canonical bands are Easy 1–3, Medium 4–6, Hard
7–8 and Nightmare 9–10. Draft/private bundle metadata carries editorial tags;
only approved `context_tag_ids` may appear in public questions. Unknown IDs are rejected; IDs
are map lookups, never filesystem paths. Omitting selection preserves the default
catalog and legacy `{}` start request. Authentication, ownership, receipt and
post-finish reveal rules are unchanged. Collection source JSON/private grading
is packaged only in the API runtime, never in Flutter public assets.

## Scoring proposal

### Single-player practice extension (SQLite only)

The closed start body additionally accepts `round` (zero-based integer), and
`mode: "practice"` only with explicit `quiz_id` and `round`. For a difficulty
request, omitting `round` starts every matching question; an explicit zero-based
round filters the full pack before it partitions the matching questions into at
most 20 questions, shuffled within each partition. The
immutable full grading bundle/version remains pinned to the attempt.

`GET /v1/attempts/{attempt}/feedback/{question}` returns the closed envelope
`{"correct": boolean, "reveal": <reveal.schema.json object>}` only to the
authenticated owner of a practice attempt, after that question's answer was
accepted. It is `Cache-Control: no-store`, including failures. Unanswered,
foreign and non-practice attempts are forbidden. Practice markers are stored
atomically with start in an additive SQLite table. The base receipt/public
catalog/event shapes do not gain correctness fields. Ranked/legacy attempts
remain sealed until finish; this does not change multiplayer reveal policy.

The selected Flutter single-player flow uses practice. One-choice taps submit
immediately; multiple-choice retains an explicit submit action. Correctness is
server-computed. Feedback retries reuse the accepted receipt without reposting.
Explanations and display answers are read from the attempt's pinned DB manifest.

Single choice is one point only when the submitted stable option ID exactly matches the private key. Multiple choice is one point only when the submitted ID set exactly equals the key; there is no partial credit. Normalized text is one point only when its normalized value equals an explicitly accepted variant. The pipeline is: Unicode NFC, Unicode `casefold`, then collapse every Unicode whitespace run to one ASCII space and trim. There is no speed bonus. The server computes every result.

Reveal content is bound to the canonical private key and public option text for the same pinned revision. Text reveal exposes one permitted display answer only, never the accepted-variant list. P33 must decide whether a team may receive correctness before the shared reveal. This v1 contract neither permits a pre-reveal correctness payload nor decides that product policy.

## Check

From `C:\ap\quiz_master`, run this twice; the stdout and `summary.json` are deterministic:

```powershell
python -B next/contracts/quiz-contract/v1/check_contract.py --write-summary
```

The checker is intentionally standard-library only. It parses and verifies declarations for all seven schemas, enforces their closed consumer shapes through the executable validators, validates cross-file invariants/scoring, and proves each named negative fixture is rejected. P08 must replace/augment this narrow executable specification with full JSON Schema dialect validation, canonical bundle hashing/publishing, source import validation, and cross-language conformance tests.
