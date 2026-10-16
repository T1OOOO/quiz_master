# Actor-question Russian grammar audit — 2026-10-16

## Scope

This is a finite, proposal-only audit of the 40 public stems in
`public-stems.json` for `prep-film-actors-2`. It does not alter a question,
answer, option, factual statement, film title, year, canonical source, runtime
asset, or NVN input. Every row is bound to the exact public revision SHA-256
from the 200-response snapshot.

## Decision rule

The construction `кто сыграл ...?` normally governs the animate character
name in the accusative case. Proposals therefore make only the smallest
declensional correction. Names whose Russian rendering is invariant in the
accusative are left unchanged. No source research was needed because this is a
linguistic form review and no factual claim changes.

## Results

`proposals.json` accounts for all 40 questions: 32 `change`, 8 `unchanged`,
and 0 `uncertain`. The changes are proposals pending independent/external
review; they are not an approval to apply them to the public quiz.

## Checks completed

The proposal JSON was checked for valid parsing, exactly 40 unique question
IDs, exact ID/revision pairing with `public-stems.json`, and `before` text
equality with the public snapshot. Each row has all required fields:
`question_id`, `revision_sha256`, `before`, `after`, `decision`, and `reason`.
The frozen culture-article files were not read for edits or changed.

## Pending

Independent Russian editorial review must decide whether to accept individual
proposals. Release acceptance, canonical update, export, deployment, and
publication remain out of scope and have not been attempted.
