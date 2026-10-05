# Independent delta and Food 423-B/C review

Reviewer label: `metadata-food-a-celeb-review`
Task: Beads `quiz_master-qr4.5`
Checkout inspected: `a1fd8bf`
Overall verdict: **REWORK for B/C tag corrections; ACCEPT for the requested A and celebrity deltas.**

## Delta acceptance

I compared the current changed records against the values inspected in the prior
independent review. The Food A record
`q_gastronomy_напитки_и_алкоголь_41_food_p5_42` retains its level 7, tags,
context, rationale, confidence and original cultural-generalisation flag, and
adds exactly `historical-claim-needs-source`. This satisfies the prior finding.
Current Food A SHA-256 is
`01ae4d48af551c068a5730b7337f1e4da8e50d71ca978c3dbfb95a1be03cd861`.

The celebrity delta also satisfies both prior findings. Only the requested score
and option-aware rationale changed in each reviewed candidate:

| ID | Accepted current level | Reason |
|---|---:|---|
| `q_phobias_part_5_12` | 1 | The stated fear of gum makes a complete ban directly inferable. |
| `q_phobias_part_9_25` | 2 | The only technical label and the Matrix joke make darkness unusually easy to select. |

Their tags, safe public contexts, confidence and pending-source flags remain
appropriate. Current celebrity SHA-256 is
`173829cb1b131cc75e7ced207240524d25b318c7d58d96ef6edaede690f6c6bc`.
This is metadata acceptance only, never factual certification of the 33
celebrity/clinical claims.

## Food B/C source review and integrity: ACCEPT

I read all 150 raw source questions: Food B in records 1–25, 26–50 and 51–75,
and Food C in the same three bounded 25-record batches. Each review included the
stem, all six options, stored key, resolved keyed option, explanation and
candidate metadata. This includes every low-confidence and flagged row as well
as every unflagged row; no external factual claim was certified.

Fresh checks from `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check .../annotations/food-423-b.json --partial
# Validated 75/4078 annotations; source integrity preserved.
python metadata/quiz_metadata.py check .../annotations/food-423-c.json --partial
# Validated 75/4078 annotations; source integrity preserved.
```

Both artifacts have exactly 75 unique records, 75 unique rationales, and exact
ordered coverage of `food-reworked.json[75:150]` (B) and `[150:225]` (C).
The checks also compare the live source semantic hashes with `INVENTORY.json`.
The reviewed candidate hashes are:

| Candidate | SHA-256 | Low / flagged |
|---|---|---:|
| Food B | `6258ee26b070ae3fafe6f5f7a8feac0d6badc1e2a34ff1ad485aa9c3092e7ed0` | 13 / 30 |
| Food C | `51432d6ee8570faa6445bed1c26bf47d09d169deb2c2855184bd3b2275ad211e` | 22 / 31 |

Scores are option-aware, fit the 1–10 rubric, and are distinct from the factual
flags. Context sets are public-safe generic domains/topics rather than private
country/cuisine/ingredient entities. The explicitly suspicious source material
(for example German Chocolate Cake, mirepoix's malformed options and tourné)
remains flagged instead of silently being rewritten.

## Tag quality: REWORK

The following tags describe a distractor or a broader assumed ingredient rather
than the actual question subject. They must be corrected before B/C acceptance:

1. `q_gastronomy_общие_факты_1_54_food_194` (Food B) — Trigger: the question
   is about carnauba wax used to polish gummy bears. `ingredient:sugar` comes
   only from the sugar-syrup distractor/generic product composition. Correction:
   remove `ingredient:sugar`; retain food/desserts metadata.
2. `q_gastronomy_общие_факты_1_98_food_p5_21` (Food B) — Trigger: Belon is an
   oyster, therefore a seafood item, not a fish. Correction: remove
   `ingredient:fish`; retain `ingredient:seafood`.
3. `q_gastronomy_специи_и_ингредиенты_20_food_p5_85` (Food C) — Trigger: the
   stated 3:1 vinaigrette proportion says only “oil”; it does not identify olive
   oil. Correction: remove `ingredient:olive-oil` rather than infer a specific
   oil from the classic preparation.
4. `q_gastronomy_сыры_и_молочные_продукты_9_food_193` (Food C) — Trigger:
   Turkish manti are dumplings, not pasta. `ingredient:pasta` and
   `topic:grain-pasta` misclassify the actual subject. Correction: remove the
   pasta tag, replace the topic in both editorial and context sets with
   `topic:food-products`, and retain the Turkey/cuisine/food/terminology tags.

No production code, source content, index, or candidate annotation was edited by
this review.
