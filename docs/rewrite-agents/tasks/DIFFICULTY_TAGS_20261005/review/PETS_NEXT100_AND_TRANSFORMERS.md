# Pets-next100 and Transformers metadata review

**Reviewer:** `review-pets-transformers-20261005`
**Scope:** frozen revision `e802ed21db936bdb9809bab2d137903eb0aa425e`,
the v1 contract/rubric, current 403-tag dictionary, inventory, both annotation
files and reports, and every assigned raw question.

## Verdict

**Requirements: ACCEPT.** `pets-next100.json` has the assigned 100 IDs across
five cat packs and SHA-256
`e502a3442b25c7786069a28955a0b9a6e737fe48da842f8510527fbc3dd58177`.
`transformers-reworked.json` has all 200 IDs across eight 25-question packs
and SHA-256
`aac9af21b808494b2661e5fa20d070f4d83991d96dd93b29aeac966e63fada42`.

**Annotation quality: ACCEPT.** I reread all 300 raw stems, complete option
arrays, keyed answers, and explanations in 12 bounded batches of at most 25
records. Scores account for direct wording/name clues and elimination; media
tags occur only with visible or pack-announced media context; editorial entity
tags describe the keyed subject rather than distractors; public context is a
safe subset.

This review does not certify disputed original facts, keys, records, or
current claims. Those are retained as private flags/confidence rather than
treated as accepted source truth.

## Mechanical evidence

- Exact coverage: pets 100 records (`4+28+28+27+13`) and Transformers 200
  (`8 x 25`), with no missing or duplicate IDs.
- Current dictionary has 403 IDs. Across all 300 records, all tag IDs are
  known; all context tags are player-safe editorial subsets; no context uses a
  private country/person/place/cuisine/ingredient facet; and every score is an
  integer in 1..10.
- All raw-source preservation hashes listed in the two author reports match
  the frozen inventory. This preserves raw stem/options/order/key/explanation
  bytes; no source or annotation bytes were changed by this review.
- Pets review included all 74 flagged entries and all 24 low-confidence
  entries. Transformers review included all 100 flagged entries and all 51
  low-confidence entries because the full corpus was read.

## Semantic observations

- The Pets scores correctly lower self-revealing or strongly eliminated items:
  `q_nature_cats_breeds_cat_348` is 1 because the key itself asserts missing
  sources; `q_nature_cats_anatomy_cat_208` is 2 despite several hazardous-food
  alternatives; and exact breed, history, record, and veterinary claims rise
  to 6--8 where no option clue supplies the answer.
- The Pets private country tags correspond to the keyed country fact and are
  absent from context. The reports retain factual-review, time-sensitive,
  overabsolute, and non-unique-answer flags for the veterinary, island,
  Hermitage, record, and popularity assertions; this is the correct boundary
  for an annotation-only pass.
- Transformers correctly avoids inferring film from the Cinema directory.
  Prime/RID/Beast Wars questions carry animation/television, explicit named
  films carry film, the explicit Prime feature ending carries animation+film,
  and generic/continuity-uncertain questions omit unsupported media. Comics
  remain literature rather than being mislabeled as books or films.
- The score/rationale calibration is internally coherent: direct lexical
  clues such as Blackarachnia and Gigantion are 2--3; exact teams, episode
  details and model forms are 6--8; narrow voice/casting and source-disputed
  facts are 8--9 with low confidence when warranted. `2bebc053-90ec-43f9-a4e6-7ee5d0a39c8a`
  has no film tag; `1aedcfca-740a-4b67-ae11-3a53116a78a3` has film because
  the stem explicitly asks for a feature-length ending.

## Retained source risks

No annotation correction is required. The existing flags must remain visible
for later factual review, especially Pets wrong-key/unsupported-statistic and
absolute-health claims, and Transformers continuity, malformed-stem,
unsupported-negative-answer, overlapping-option, source/translation, and
production-premise claims. Their presence means the metadata does not claim
the original question is factually correct or uniquely answerable.
