# Minimum 20 — bounded implementation plan

## Decision

A published **playable round** must contain at least 20 distinct canonical questions. Do not pad a short round by repeating a question, moving a question between difficulty bands, or mixing a merely similarly named category. A source pack may remain published as reference content, but it must not expose a playable round until either it reaches 20 itself or an editor-approved semantic pool reaches 20.

One possible implementation is a server-side **reviewed round-pool registry** plus a minimum-length guard. This is an advisory proposal, not an accepted design; static derived canonical banks with explicit legacy aliases may be substantially smaller and should be evaluated first. It reuses already published source questions and their existing grading data. It does not rewrite source bundles, URLs, answer keys, difficulty labels, or question revisions.

## What the current implementation does

`next/server/internal/attempts/rules.go:61-85` defines a 20-question partition but treats every nonempty set below 20 as one valid round: `QuestionRoundCount(1..19) == 1`, and the final round ends at the source length. `QuestionRound` therefore allows a1–19-question set. However, for source sets>=20 the existing floor division ALREADY absorbs the remainder into the final full round:41→20+21;39→one39. No remainder fix is needed.

Both production paths use that helper without a minimum check:

- `next/server/internal/sqlite/collection.go:195-219` for pack and difficulty-selected rounds.
- `next/server/internal/attempts/service.go:170-202` for the in-memory/service path.
- `next/server/internal/httpapi/attempts.go:106-179` accepts `quiz_id`, optional `round`, and optional `difficulty`, then dispatches to those methods. `GET /v1/catalog` also returns a difficulty-selected catalog at lines 67-103.

The source question ordering and snapshot behavior must remain intact: `startQuestionRound` copies only the selected question slice before `start` (`collection.go:223-227`), while the normal service snapshots the selected bundle. Any new pool must retain this property and pin exactly the source question revisions and private grading used by an attempt.

## Actual inventory and the open issue

`minimum20-catalog-audit.json` records 144 packs and 4,486 question slots. It lists 48 packs below 20, with a theoretical 352-question deficit if every source pack had to be independently expanded.

The exact catalog has 252 nonempty known-difficulty bands below20, plus9 nonempty `unknown` bands below20:261 including unknown. These counts refer to different explicitly named sets, not conflicting inventories.

The books repair is real but local: `preparation-books-modern` has 42 questions (`easy=22`, `medium=20`), so its total route and its easy/medium routes can have full 20-question rounds. `preparation-books-classic` has 30 total but only one medium item, so its total route is eligible while a medium-only route is not. The broader report 26 remains open through Bead `quiz_master-k2ux`.

The following are category-level upper bounds for reusing short source parts, **not approval to combine them**. They show why an automatic category merge would be wrong:

| Source category among short packs | Short packs | Questions in those packs | Maximum complete 20-question pools if every item were editor-approved |
|---|---:|---:|---:|
| Природа | 15 | 245 | 12 |
| Кино | 12 | 110 | 5 |
| Филии | 7 | 103 | 5 |
| Гастрономия | 4 | 53 | 2 |
| Филология | 4 | 50 | 2 |
| Музыка | 2 | 14 | 0 |
| Игры | 1 | 10 | 0 |
| Наука/Космос | 1 | 10 | 0 |
| Психология | 1 | 9 | 0 |
| Кино/Ремесло | 1 | 4 | 0 |

A category label is insufficient semantic evidence: for example, the 10-question `theme-game-worlds` and 10-question `planet-paradoxes-20261010` have no eligible same-scope source identified by this audit. They need new independently reviewed questions or must remain unavailable as playable rounds. They must not be filled from unrelated games or general science.

## Pool registry contract

Add one versioned, reviewed content configuration owned by the content/backend implementation task, for example `next/content/round-pools.json`. Each entry is explicit rather than inferred from category:

```json
{
  "pool_id": "<stable-public-id>",
  "title": "<editorial title>",
  "source_quiz_ids": ["<existing-id-1>", "<existing-id-2>"],
  "allowed_difficulties": ["easy", "medium", "hard", "nightmare"],
  "semantic_scope": "<short reviewer-approved rationale>",
  "review_receipt": "<content-review identity/hash>"
}
```

Validation at collection load must fail closed when a source ID is unknown, repeated, unreviewed, or produces duplicate canonical question IDs. It must also reject a pool whose title/category merely papers over an unrelated mix. The registry does not change the source bundles. It describes a separate public route whose question set is the ordered concatenation of the approved sources.

For each route request:

1. Resolve a source pack normally, or resolve a registered pool.
2. For no difficulty, use only the pool's distinct source questions. For a difficulty route, filter every source by the **requested same difficulty** before aggregation.
3. Reject the request, omit the route from catalog/UI, or return a clear `not enough reviewed questions` state when fewer than 20 remain. Do not fall back to a neighboring difficulty or a different pool.
4. Partition and shuffle only after the eligible set has at least 20. Every normal round is exactly 20; no short remainder is playable. Questions are not reused across that pool's rounds.
5. Build the immutable attempt snapshot from the selected question revisions, option IDs, private grading entries, source manifest explanations, source bundle hashes, and pool configuration version/hash. Reveal and grading continue to use the source question IDs and original URLs.

The no-round `StartQuiz`/`StartDifficultyQuiz` paths also need this eligibility gate or the client must always request an explicit round. Otherwise a1–19 question attempt remains reachable even if `StartRound` is fixed. Hiding all48shortpacks is NOT an accepted completion: first supply genuinely related pools/new questions so topics remain useful.

## Smallest code-path change

1. **`attempts/rules.go`**: make round selection reject sets below20; preserve the EXISTING final-remainder absorption (41→20+21;39→one39). Keep its copying and non-repetition guarantees. A separate `EligibleRoundCount` helper should expose zero for any selected set smaller than 20, instead of the current `1`.
2. **`sqlite/collection.go` and `attempts/service.go`**: add one resolver that returns either one existing pack or one validated composite pool; use it for `CatalogFor`, `CatalogForDifficulty`, `StartQuiz`, `StartRound`, and both practice variants. The difficulty resolver must execute before round counting.
3. **`httpapi/attempts.go`**: catalog responses must expose only eligible routes/counts and attempts must return the existing validation/no-match error for an ineligible route. Do not create a client-only check that an API caller can bypass.
4. **Content loading/attempt serialization**: represent a composite as a derived immutable bundle with provenance for every constituent source. Reuse the existing bundle/manifest checks rather than introducing a parallel grading format. Snapshot tests must prove each selected question's original option IDs, correct answer, revision, explanation, and URL are unchanged.
5. **Client**: list the reviewed pool title and available difficulty buttons only when the server catalog reports a full round. It should not display a 20-question promise for 1–19 entries.

This proposal needs product/code review against the smaller static derived-bank alternative before implementation. It is not evidence that a new runtime pool/provenance subsystem is necessary.

## Concrete routing decisions

- **Legacy LOTR:** `next/content/lotr` has 3 questions. The published, existing `lotr-fellowship-100` has 50 questions (and the two other newer LOTR bundles have 100 each). Route the legacy `lotr` catalog/link to the existing reviewed `lotr-fellowship-100` route after an editorial alias receipt; do not merge the old three into it and do not duplicate them. The route must disclose its Fellowship scope rather than label it as the whole trilogy.
- **Books:** retain the repaired modern-books total/easy/medium routes. Do not expose classic-books medium until it has 20 reviewed medium questions or a reviewed same-difficulty books pool reaches 20.
- **Source parts that are genuinely a single editorial series:** candidates may be reviewed as a pool only when their source titles, source URLs, factual scope, and duplicate-ID audit show the same learnable topic. Examples require separate review; the broad labels `Природа`, `Кино`, and `Филии` alone are insufficient.
- **Games and science examples above:** leave the 10-question routes unavailable for play pending new content. This is the correct result under the stated no-irrelevant-mixing rule.

## Acceptance cases for Bead `quiz_master-k2ux`

- Record252 known-difficulty bands plus9 unknown bands,261 total, from the exact catalog.
- Every API-startable standard or practice round has at least20 distinct questions; a source or filtered pool with 1–19 is unavailable and has no fallback difficulty.
- Traversing all rounds of a resolved pool produces no repeated canonical question ID and no question is lost; final remainders are merged or balanced into full rounds.
- A difficulty round contains only the requested stored difficulty. Its source questions retain their IDs, revisions, option IDs, correct answers, grading records, explanations, and URLs.
- A composite attempt snapshot records pool/version and all source-bundle hashes; a later source/pool publication cannot mutate an existing attempt.
- Negative tests cover unknown source, duplicate source, duplicate canonical ID, unrelated/unapproved pool, missing manifest/private grading, short total, short filtered band, and an alias target that is short or no longer published.
- Independent content review accepts each proposed pool's semantic scope before it becomes catalog-visible.

## Non-goals

This plan does not promise that all 48 short source packs or all 261 reported short difficulty bands become playable without editorial work. It intentionally keeps those unavailable until a specific reviewed pool or new questions exists. It also does not alter existing difficulty calibration, answer grading, source URLs, canonical question text, or historical attempt snapshots.
