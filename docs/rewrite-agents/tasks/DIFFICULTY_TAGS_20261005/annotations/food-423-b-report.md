# Food 423-B annotation handoff

Scope is exactly `annotations/food-reworked.json` records `[75:150]`, retained in
that order. The output is a candidate for independent review, not applied content,
fact certification, or publication.

- Count and unique IDs: 75.
- First ID: `q_gastronomy_общие_факты_1_43_food_142`.
- Last ID: `q_gastronomy_сладости_и_десерты_8_food_146`.
- Exact ordered ID comparison against that source slice: `True`.
- Each record has a distinct, option-aware private rationale, an independent
  editorial score 1–10, confidence, and retained/additional source flags.

## Source reading and identity

I read the complete frozen raw record for every question in three batches of 25:
records 75–99, 100–124, and 125–149. Each read included the stem, all six choices,
`correct_answer`, the resolved keyed option, and explanation. No raw source file or
answer field was changed.

Frozen inventory revision: `e802ed21db936bdb9809bab2d137903eb0aa425e`.
Current hashes match the inventory:

| Pack | SHA-256 |
| --- | --- |
| `gastronomy_общие_факты_1` | `efc1e25c32a06edec1e0bdfa11709752ac9bab2927fb903ca8ff6541314f2ebf` |
| `gastronomy_общие_факты_2` | `298844c2f634be1b60f7ba01e7bd72cff892a5da3be7d411a89017805a4f127b` |
| `gastronomy_сладости_и_десерты` | `bbf1a35d66380c56b08d1ddae762274bf72e10a0f01f094bcab0f5c265562e59` |

The annotation declares `qm-tags-v1` semantic hash
`09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.
It uses the applied 423 vocabulary for actual subjects, including food products,
edible fungi, brand logos, grain/pasta, space food, culinary professions,
food-law and law regulations. Country, cuisine, ingredient and answer-derived
tags stay private; public context holds only visible generic domains/topics.

The legal, medical, historical, superlative/ranking, quantitative, cultural and
answer-format concerns remain private flags where the existing source warrants
them. The phobia record is tagged for peanut, not wheat pasta; pasta and rice tags
are applied only to their actual foods.

## Checks

From `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/food-423-b.json --partial
```

Result: `Validated 75/4078 annotations; source integrity preserved.` A separate
scope check returned 75 records, 75 unique IDs, 75 unique rationales, ordered
coverage `True`, and the stated first/last IDs. JSON SHA-256:
`6258ee26b070ae3fafe6f5f7a8feac0d6badc1e2a34ff1ad485aa9c3092e7ed0`.

Root independent review is still awaited. Scores are estimates for Russian adult
general-quiz players, not measured calibration.

## Root independent-review delta

Reviewer FOOD_423_DELTAS_B_C requested exact tag-only changes for q_gastronomy_общие_факты_1_54_food_194, q_gastronomy_общие_факты_1_98_food_p5_21. Root reread four full raw questions and confirmed wax distractor/seafood/generic oil/dumpling subject. BeforeSHA `6258ee26b070ae3fafe6f5f7a8feac0d6badc1e2a34ff1ad485aa9c3092e7ed0`, currentSHA `13bcf9429f1fe21457a6b6f59489748502ffe4afdbaafa583f578002f1cd3d9a`; all other fields and rows unchanged. Metadata validation passed in helper. Delta acceptance pending.
