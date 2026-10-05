# Cinema and root-phobias annotation review

## Verdict

**Requirements: REWORK. Annotation quality: REWORK.** The Home Alone rationale
set is templated rather than individual, and three rows need specific metadata
correction. No coverage, context-safety, score-range, or source-byte issue was
found.

### Required correction

1. All 185 `annotations/cinema-legacy.json` rationales need replacement with
   short, individual, option-aware reasoning. The current four keyed-string
   templates cover every row: generic association (114), exact detail (31),
   generic production (20), and generic prop (20). Inserting the keyed answer
   does not explain its distractors/cues or support the assigned score, so it
   does not satisfy the Contract's individual-rationale requirement.

2. `q_ha2_p2_25`: add private `answer-ambiguity` and lower confidence from
   `high` to `low` (or another explicitly justified non-high value). The stem
   itself combines two scenarios ("в кузове грузовика с игрушками (или когда
   убегал)"), its keyed option also combines two actions ("Накрылся одеялом /
   спрятался"), and the explanation says only "Это общий вопрос — Кевин часто
   прячется." It does not support the present high-confidence single-answer
   annotation.

3. `q_ha1_p1_10`: replace `skill:quantitative` with `skill:direct-recall`
   (or `skill:recognition`). The question is a six-colour visual-detail recall,
   not quantity reasoning. Its current score 6 is defensible once its rationale
   describes the unprompted store-scene colour distinction.

4. `q_ha1_p1_14`: change `topic:film-plots` to `topic:characters` and reassess
   score 3. Remembering minor character Gus Polinski's clarinet among six
   plausible instruments is specialised film recall without a stem cue; score
   6 is the smallest rubric-consistent replacement. Use an individual
   rationale. `q_ha1_p1_13` is screen-soundtrack identification, not a
   production-history assertion; the frozen vocabulary has no soundtrack topic,
   so `topic:film-production` is an acceptable closest topic, but its score and
   rationale also need individual review (score 6 is supported by the exact
   song/cue distinction).

Items 2–4 record source/metadata quality only. They do not alter, or certify
the truth of, an existing source key.

## Scope and evidence

This is a read-only annotation-semantic review against `CONTRACT.md` and
`RUBRIC.md`, not independent factual verification.

| Artifact | SHA-256 | Records read against complete raw stem/options/key/explanation |
| --- | --- | ---: |
| `annotations/cinema.json` | `a6db90822da7ec6b62ab7c9ca5461da0f60d647221a60e12c765198e1a6467ed` | 80 |
| `annotations/cinema-legacy.json` | `857eeb7128702253dc11da8c74530daf643022280a13b55187e118ee106cb36d` | 185 |
| `annotations/phobias-root32.json` | `079031a70835f00792741860dae81cdbadbe47067ff61bd768ea76768ff67c40` | 32 |

The 297 records were read in 14 source batches, each at most 25 records:
Thematic80 4, Home Alone 8, and root-phobias 2. The frozen inventory revision
is `e802ed21db936bdb9809bab2d137903eb0aa425e`; SHA-256 checks matched all 18
source files used here: eight `quizzes/Cinema/Thematic80/*.json`, eight
`quizzes/Cinema/HomeAlone/home_alone_{1,2}_part_*.json`, and
`quizzes/Psychology/phobias_{nature,medical}.json`.

The current dictionary has 403 tag IDs and taxonomy SHA-256
`fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`.
Mechanical validation found 297 unique raw-matched IDs, zero unknown tags,
zero unsafe or non-subset context tags, sorted unique tag arrays, valid 1–10
scores, and a domain plus specific topic/franchise for each record.

## Editorial observations

The remaining annotations use topical, version-aware screen/media tags and
keep skill/entity detail private. Context tags describe the visible subject or
announced franchise/medium; they do not publish distractor-only entities.
The Harry Potter book/film and Star Wars screen-canon boundary flags are
present. All 57 flagged or low-confidence records were included in the review.

For root phobias, pure Greek/Latin root prompts use `domain:language` and
`topic:word-origin`, while actual phobia prompts use psychology/medical terms
only where the visible question warrants them. The final three word-origin
rows use valid `skill:terminology`; their private `topic:word-origin` remains
out of context. Existing duplicate-option, suspected-key, multiple-plausible,
medical, and template flags are preserved as source-risk metadata.

Difficulty estimates are editorial, not measured calibration. The Cinema80 and
root32 estimates are coherent relative to their alternatives; legacy scores
must be reassessed with the individual rationales above. This review does not
independently verify film, franchise, medical, linguistic, or historical claims
and does not treat a source ambiguity as difficulty 10.

No production or annotation input bytes were changed by this reviewer.
