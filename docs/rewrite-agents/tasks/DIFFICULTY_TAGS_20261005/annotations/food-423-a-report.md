# Food 423-A annotation handoff

## Scope and source reading

This is the expressly authorised partial first tranche: exactly the first 75 records in
`annotations/food-reworked.json` order, not alphabetical order.

- First ID: `q_gastronomy_традиции_и_этикет_42_food_606`
- Last ID: `q_gastronomy_общие_факты_1_37_food_109`
- Coverage: 75 unique `quiz` records; no missing, extra, or reordered IDs against that
  source slice.
- Raw source reading: three complete batches, records 1–25, 26–50, and 51–75. Each was
  read with the source `text`, all options, `correct_answer` index and resolved keyed
  option, and explanation.

The frozen inventory remains commit `e802ed21db936bdb9809bab2d137903eb0aa425e`.
The four source packs represented by the slice and their frozen SHA-256 values are:

| Pack ID | SHA-256 |
|---|---|
| `gastronomy_miscellaneous_off_topic` | `0e0e2663573cecd34d044c3341a2a4c22eb65a084b474e341b8c2b209bbd1bb5` |
| `gastronomy_мясо_и_рыба` | `92717b90aa827bbbc2dee784ee61b15f2d05b2a55d5891f9739995dd5111e3ff` |
| `gastronomy_напитки_и_алкоголь` | `22e7eaae9cd731f2800f19b2f9688c73f1a84b0764aacca5248f5f2341b56d1d` |
| `gastronomy_общие_факты_1` | `efc1e25c32a06edec1e0bdfa11709752ac9bab2927fb903ca8ff6541314f2ebf` |

## Annotation decisions

`food-423-a.json` uses schema `qm-question-annotations/v1` and current taxonomy
`qm-tags-v1` hash
`09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.
Scores are editorial estimates for the stated Russian adult general-quiz audience,
not performance measurements. Every rationale is written from the displayed options:
it identifies a specific recall or comparison burden and does not use the rejected
keyed-answer template.

The applied 423 vocabulary resolves former gaps when the actual subject matches:
`food-safety` (1), `edible-fungi` (2), `restaurant-industry` (1), `food-senses` (1),
`culinary-profession` (4), `food-products` (1), `space-food` (1), `food-history` (3),
`grain-pasta` (2), and `food-law` plus `law-regulations` (1). In particular,
`food_91` is tagged with Japan, food, society, food-law and law-regulations. Entity
tags remain private; public context is restricted to visible generic domains/topics.

## Checks

Run from `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/food-423-a.json --partial
```

Result:

```text
Validated 75/4078 annotations; source integrity preserved.
```

An exact ID comparison with `food-reworked.json[:75]` returned `True`; count and
unique count were both 75. The initial annotation file SHA-256 was
`fc027750b0d3f43b8221d54f7d0154b4165c705f53905baf8c5f3a24616fa39f`.

## Post-review delta

Following the Food A semantic review, exactly one field changed. Record
`q_gastronomy_напитки_и_алкоголь_41_food_p5_42` retains its score, tags, context,
rationale, confidence and prior `cultural-generalization-needs-source` flag, and
adds `historical-claim-needs-source` for the tall-chef-hat legend. The new annotation
SHA-256 is `01ae4d48af551c068a5730b7337f1e4da8e50d71ca978c3dbfb95a1be03cd861`.

## Remaining review work

No independent factual certification was performed. Existing and newly retained
private flags call out the claims needing that review: rankings/superlatives,
historical years, health or food-safety assertions, law claims, cultural
generalisations, and answer-format ambiguity. This partial artifact is ready for
root's independent review and must not be treated as applied content or publication.
