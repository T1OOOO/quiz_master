# Food annotation report

Frozen inventory revision: `e802ed21db936bdb9809bab2d137903eb0aa425e`

Reviewed scope: 11 `Гастрономия` packs / 299 questions. The pack list and count are taken directly from `INVENTORY.json`; there are no omitted scope records. `food.json` SHA-256: `d7fc50a5ce2f25117f33bfd6deff8d12683f6e0d9a018d8d315790d159227bbf`. Concatenated sorted frozen pack-hash digest: `8c0c25e391e7dd638ab7f26a97d07439b3d3ebfed315703e544472d65a0f65d8`.

## Method

Every record retains the canonical quiz identity and uses `qm-question-annotations/v1` with the current `qm-tags-v1` reference (`fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`). Root's explicit vocabulary amendment added four Philology topics and changed only this taxonomy digest; food records were rebound without applying those unrelated tags. Difficulty is an editorial estimate for a Russian adult general-knowledge audience after reading the stem, keyed option, all alternatives, and explanation. It reflects recognition, terminology, quantitative precision, and the plausibility of alternatives; it is not a response-rate claim.

Scores: {2: 2, 3: 43, 4: 153, 5: 47, 6: 42, 7: 7, 8: 5}. Confidence: {'high': 144, 'low': 18, 'medium': 137}. Context tags contain only the visible domain/topic pair; country, cuisine, and ingredient tags stay editorial-only. For 73 questions whose visible fact has no suitable topic in the controlled taxonomy, context is the safe domain only and the private `taxonomy-topic-gap` flag records the vocabulary limitation.

## Flagged independent-review queue

`answer-format-ambiguous`: 1, `cultural-generalization-needs-source`: 32, `factual-error-suspected`: 2, `food-safety-oversimplified`: 1, `law-claim-needs-source`: 8, `medical-claim-needs-source`: 1, `needs-independent-fact-check`: 18, `ranking-time-sensitive`: 2, `superlative-needs-source`: 23, `taxonomy-topic-gap`: 73.

The flagged claims are not treated as harder because they may need verification. The strongest queue is the two incorrect-sounding `Tourné` knife records, the malformed mirepoix ratio answer, food-safety guidance, legal prohibitions, rankings/superlatives, broad cultural claims, and the vocabulary gaps. Rework removed substring-derived ingredient tags and excluded a topic from public context when the visible stem did not support it. No source bytes or answer keys were edited.

## Limits

This is an editorial annotation artifact only. It does not establish factual publication acceptance, independent fact review, calibration, or source-content changes. The controlled vocabulary has no generic `topic:food-general`; those records retain a private nearest-topic tag to meet the required taxonomy shape, while public context is limited to `domain:food` and the gap is queued for taxonomy review.
