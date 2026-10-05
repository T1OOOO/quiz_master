# Nature pets annotation report

First-pass editorial annotations for the frozen cats/dogs scope in `quiz_master-qr4.3`.

- Coverage: 725/725 quiz questions, 34 packs; all IDs use the frozen `cats_`/`dogs_` question scope.
- Source inventory: `e802ed21db936bdb9809bab2d137903eb0aa425`.
- Taxonomy: `qm-tags-v1`, SHA256 `2ff002603ad7794957962c89c9ccd32a5ddb7a43c72b0b17ae3d6c5e50ae6bf1`.
- Annotation file SHA256: `5bd141d4a09da40941b5e33000ec5800c8e9273001081c1cfbef46510a3b363b`.
- Sorted identity-list SHA256: `3fa1a7eb305e205baead8a296017606c228b56883efc2d4dd42cd96b7771bf5d`.
- Difficulty distribution: 2=7, 3=51, 4=130, 5=293, 6=151, 7=77, 8=15, 9=1; no 1 or 10.
- 18 records carry the private `overabsolute-wording` flag. Context tags are player-safe and subsets of editorial tags; country/place/person tags were kept private/omitted unless directly needed.

Validation run from `C:/ap/quiz_master`:

```text
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/nature-pets.json --partial
Validated 725/4078 annotations; source integrity preserved.
```

The first pass read each assigned stem, all options, keyed answer and explanation during the source traversal. Existing per-question difficulty values were treated as a review starting point and checked against the stem/options and the Russian adult familiarity rubric; they were not used as a pack-wide rating. Rationales remain private and preserve the source explanation context. Root should independently review medium-confidence and flagged rows before integration.
