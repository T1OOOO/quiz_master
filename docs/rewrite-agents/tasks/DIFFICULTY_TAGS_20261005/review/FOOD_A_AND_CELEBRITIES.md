# Independent review: food 423-A and celebrity phobias

Reviewer label: `metadata-food-a-celeb-review`
Task: Beads `quiz_master-qr4.5`
Checkout revision inspected: `a1fd8bf`
Review state: **REWORK**

## Scope and evidence

This review read every supplied source record with its stem, all alternatives, raw
key and explanation: the 75 food rows in three batches of 25, and the 33
celebrity/phobia rows in batches of 17 and 16. It also read all 423 dictionary
entries in `metadata/tags.v1.json` (taxonomy hash
`09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`).

Reviewed frozen candidates:

| File | Records | SHA-256 |
|---|---:|---|
| `annotations/food-423-a.json` | 75 | `fc027750b0d3f43b8221d54f7d0154b4165c705f53905baf8c5f3a24616fa39f` |
| `annotations/phobias-celebrities-root33.json` | 33 | `9177d6e936d1bc56fcb629cba395562b5388bcf60752e40ecd90e6e6758fba79` |

Fresh commands from `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check .../annotations/food-423-a.json --partial
# Validated 75/4078 annotations; source integrity preserved.
python metadata/quiz_metadata.py check .../annotations/phobias-celebrities-root33.json --partial
# Validated 33/4078 annotations; source integrity preserved.
```

The first 75 food IDs exactly equal `food-reworked.json[:75]`, both files have
unique IDs and unique rationales, all referenced tags resolve, every context set
is a safe subset of its editorial set, and neither candidate places an entity,
country, cuisine, ingredient, person or place tag in public context. The full
source-integrity check above also compares the live source semantic hashes with
`INVENTORY.json`; it passed.

Food has 36 low-confidence and 39 flagged rows. Celebrity phobias has 33/33
low-confidence and 33/33 flagged rows. I did **not** independently certify any
of the 108 underlying factual claims. In particular, the celebrity biographies
remain pending source review; the existing biographical and diagnosis-inference
flags appropriately keep that uncertainty private.

## Requirements-compliance verdict: REWORK

The 423-A food metadata otherwise meets the annotation contract. Its subject
tags follow the actual question rather than distractors (including the
geography/ecology items in a food pack), its rationales are individual and
option-aware, and `q_gastronomy_общие_факты_1_33_food_91` correctly remains
low-confidence and flagged for the Japanese law claim. Its public context only
states visible general subjects. No ingredient-paste false match was found.

The following two celebrity scores conflict with the rubric because the stem and
options make the selected answer substantially inferable without the claimed
biographical recall:

1. `q_phobias_part_5_12` — Trigger: the stem already says Oprah's reason is a
   fear of chewing gum and the keyed option is the direct, comprehensive policy
   “Полный запрет на жевательную резинку”; the rationale itself calls it
   “закономернее”. Current level 4 therefore overstates the required knowledge.
   Correction: change `difficulty_level` to **1** (or at most 2 with a recorded
   rationale for retaining any uncertainty), retaining `stem-answer-cue` and
   the source/diagnosis flags.
2. `q_phobias_part_9_25` — Trigger: “Темноты (скотофобия)” is the only answer
   with an explanatory technical label, while “Матрицы” is a joke distractor;
   this sharply narrows the choice before the Keanu Reeves assertion is known.
   Current level 4 is not a medium focused-recall item under the rubric.
   Correction: change `difficulty_level` to **2** and retain
   `answer-option-cue` plus the existing pending-source flags.

## Annotation-quality verdict: REWORK

1. `q_gastronomy_напитки_и_алкоголь_41_food_p5_42` — Trigger: the keyed
   explanation and rationale explicitly present the tall-chef-hat account as a
   historical legend, but the only flag is
   `cultural-generalization-needs-source`. That flag does not describe the
   disputed origin claim. Correction: retain the row and add a fact-review flag
   such as `historical-claim-needs-source` (and, if used by this batch,
   `needs-independent-fact-check`); do not rewrite the source fact.

All other scores are editorially plausible for the stated Russian adult general
quiz audience once their displayed alternatives are considered. This is not a
factual approval of their source claims.

## Separate assessment: Quizipedia test-only diff

The seven-line change in `next/apps/quiz_app/test/quizipedia_test.dart` is
test-only. It increases only the rightmost target pan from `-155` to `-205`
after the first movement is consumed by gesture recognition, and adds an
explicit assertion that the computed local tap point lies inside the viewport.
The assertion directly captures the reported clipped-hole failure and does not
weaken map coverage or touch production code. `git diff --check` is clean
(aside from Git's LF-to-CRLF warning). This narrow test change is acceptable on
its own. The reported full 91-test pass was not independently rerun, by the
assigned scope.

No annotation, source, implementation, index or repository-state file was
edited by this review.
