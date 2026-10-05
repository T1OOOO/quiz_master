# Philias 423 independent metadata review

## Verdict: REWORK

The two staged files have complete, valid coverage and generally sound editorial
scoring/tagging.  Rework is limited to the two annotations below; it is not a
publication, factual-certification, or source-content acceptance.

| Question ID | Required metadata action | Evidence |
| --- | --- | --- |
| `q_philias_300_84` | Add an explicit answer/explanation-name mismatch flag and route the source for term verification. Do not silently treat `Тачеризм` (the keyed option) and `Фроттеризм` (the explanation's named term) as the same answer. | The raw key is option 1, `Тачеризм`; its explanation begins `**Фроттеризм**`. The current low-confidence row flags generic terminology/diagnostic concerns, but not this literal internal disagreement. This review makes no claim about whether the two terms are synonyms. |
| `q_philias_100_20` | Remove `interest-sexual-attraction-conflation`, or replace it with a flag that is actually supported by this source. | Its stem and explanation consistently describe ordinary appreciation of trees/forests; neither introduces a sexual attraction or diagnosis. |

## Scope and read evidence

Reviewed at revision `a1fd8bf12ba8affddd2f865a6479e04a0ed0438f` using the
frozen 423-tag dictionary (`taxonomy_sha256`
`09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`).

| Input | SHA-256 | Result |
| --- | --- | --- |
| `annotations/philias-root75.json` | `6c08856bf4f56b444caec1c55b0d2cf7ef9cc199752682b75b1ca89e9331ce48` | exact `Philias[:75]` order |
| `annotations/philias-root90.json` | `f878cfd1350ccf9ddc978f4d94f4557b4faca69a4223186be5f7cd42d8ffe4d7` | exact `Philias[75:165]` order |
| Ten `quizzes/Philias/*.json` sources | `8d7aa2f73512a70dd3e58f236dc6b8dbd37e3897d60bfa91766e287001cb86c0` | aggregate SHA-256 of the sorted `path -> file-SHA256` map; all 165 records resolved |

I read every raw stem, all choices, keyed option, and explanation: three
25-record batches for records 1–75 and 25/25/25/15-record batches for
76–165. This included all 138 low-confidence rows and all 162 flagged rows,
not merely a sample. The two annotation files together have 165 unique source
IDs, exactly match the complete Philias source order, and contain no repeated
rationale text.

## Scoring and tag judgement

The assigned scores are individually reasoned from the literal choices, rather
than copied from the old `difficulty` field: 5 score-1, 10 score-2, 18 score-3,
22 score-4, 28 score-5, 25 score-6, 31 score-7, 25 score-8, and 1 score-9;
there are no score-10s. The clear direct-name items are low (robots 2, Japan 1,
blogs 1, comets 1). The rare ear-specific term is the sole 9, with six close
ear answers. The high concentration at 4–8 is justified by opaque roots and
genuinely overlapping alternatives, but remains an editorial calibration risk,
not an observed player-performance claim.

Rationales are option-aware and individually phrased. The repeated lexical
root/near-duplicate/duplicate-option problems are appropriately flagged rather
than inflated to 9–10 merely because a term looks scientific. All duplicate
option cases were flagged. Medical/diagnostic and etymology statements remain
flags requiring source verification; this review does not certify them.

Tagging uses the frozen vocabulary without additions. `country:gb`, `country:fr`,
`country:jp`, `country:cn`, and `country:ru` occur only as private editorial
tags for their explicit country prompts; none was inferred from a Greek root.
Garlic and peanut remain private ingredient tags on explicit food subjects.
Visible stars use safe `topic:astronomy`; the direct suffix and literal
philosophy-root questions carry the safe language/word-meaning or word-origin
context. No mushroom food tag was applied. No unsupported Aibo/other unrelated
entity tag is present.

## Fresh checks

Run from `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check .../annotations/philias-root75.json --partial
Validated 75/4078 annotations; source integrity preserved.

python metadata/quiz_metadata.py check .../annotations/philias-root90.json --partial
Validated 90/4078 annotations; source integrity preserved.
```

The structural checks validate schema, vocabulary membership, sorted tags,
context-safe subsets, and source preservation. They do not resolve the two
editorial findings above. No production files, Git index, build, deployment,
or publication state was changed.
