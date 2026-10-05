# Preparation 423-A annotation handoff

## Scope and source reading

This is exactly the first 75 **currently unannotated** `quiz` records after
filtering `metadata.quiz_metadata.source_records()` to
`path.startswith('quizzes/Preparation/')` and preserving its stable traversal.
The complete Preparation source has 750 records; 410 already occur in the
existing `annotations/` or `accepted/` artifacts, leaving 340. This candidate
covers the required first 75 of those 340, in this exact composition:

- `prep-ballet`: 20 records, `music-oct3-004` through `music-oct3-044` in raw
  question order;
- `preparation-books-classic`: all 30 records, `prep-books-classic-01` through
  `prep-books-classic-30`;
- `preparation-books-modern`: first 25 records, `prep-books-modern-01` through
  `prep-books-modern-25`.

Raw sources were read in three complete batches of at most 25 records. Each
batch included the full stem, every displayed option, `correct_answer` index,
resolved keyed option and explanation:

| Batch | Traversal positions | IDs |
|---|---:|---|
| 1 | 1–25 | all 20 Ballet, Classic Books 01–05 |
| 2 | 26–50 | Classic Books 06–30 |
| 3 | 51–75 | Modern Books 01–25 |

The frozen inventory is source revision
`e802ed21db936bdb9809bab2d137903eb0aa425e`. Fresh SHA-256 calculations
matched the inventory for every represented raw pack:

| Pack | SHA-256 |
|---|---|
| `quizzes/Preparation/prep_ballet.json` | `b3703cff1c310775f216f2c6f2a5d28c36c775bacbc9bd2f191471acc3ad97f8` |
| `quizzes/Preparation/prep_books_classic.json` | `3bb8051dab5dbe0bc59ccce359814950a7ee64eb4b19233e407a501774b930d8` |
| `quizzes/Preparation/prep_books_modern.json` | `93f318f32a0f45ff8b71521982dffbeb3c2e0b16b4efd078b04780c2bbf0e874` |

## Annotation decisions

`preparation-423-a.json` uses the frozen `qm-question-annotations/v1`
envelope and `qm-tags-v1` taxonomy reference
`09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.
Every record has a sorted domain plus a specific topic, and context is a
player-safe subset describing visible/announced Ballet or book-literature
context. The two Tolkien person tags remain editorial-only; no person,
country, place, cuisine or ingredient tag is exposed in context.

Scores are editorial estimates for Russian adult general-knowledge players,
not response-rate claims. Each rationale is unique and refers to the displayed
alternatives: the Ballet set distinguishes competing named composers, while the
book sets distinguish authors within the actual language, period or genre of
the alternatives. Score histogram: `1: 1`, `2: 17`, `3: 21`, `4: 15`, `5: 12`,
`6: 5`, `7: 4`; no score was assigned by filename, source difficulty, or a
default rule.

Two source-visible qualification flags are preserved for later editorial/fact
review: `traditional-attribution` on the Homer answer for *Odyssey*, and
`collaborative-authorship-context` on *The Count of Monte Cristo*. This work
does not independently certify any source fact and makes no answer, option,
stem or explanation edits.

## Checks

Run from `C:\ap\quiz_master`:

```text
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/preparation-423-a.json --partial
```

Result:

```text
Validated 75/4078 annotations; source integrity preserved.
```

An additional scoped comparison of this file with the filtered raw traversal
returned: `count=75`, `unique_ids=75`, `slice_match=True`,
`unique_rationales=75`; all three fresh raw SHA-256 values matched the frozen
inventory. `git diff --check --` on the annotation file passed.

Candidate SHA-256:
`9ec372498d17e6d56b878244da521db6c84d588bb45f7213bd139dd562aacaa3`.

## Post-review delta

Root's independent source review identified exactly one answer cue in
`music-oct3-038`. The actual stem reads «Кто написал музыку к «Жар-птице»
Стравинского?», then offers «Игорь Стравинский» as one option. After rereading
the full raw record, the only annotation-row changes are:

- `difficulty_level`: `5` → `1`;
- `skill:direct-recall` → `skill:recognition`;
- rationale now records the name-in-stem cue and the actual three alternatives;
- added private editorial flag `answer-in-stem`.

Every other field in that record and every other record is byte-preserved. The
raw source hashes above remain unchanged. This correction addresses editorial
difficulty only; it neither changes nor independently certifies the source fact.
Validation was run under bounded75's granted interactive lease
`lease-806d2d85e7e3487e840118764edbe8a8`.

Artifact hashes for the delta:

| Artifact | Before correction | After correction |
|---|---|---|
| Annotation JSON | `9ec372498d17e6d56b878244da521db6c84d588bb45f7213bd139dd562aacaa3` | `6b6b6cf03a7f8a4ebafe715d9e474e659489e6d77eb302b4974796418588e2a2` |
| Author report | `878ded845c4adf3f65f875c6c60db8e9c56c2c3ee052bf1d95709263aa0b4889` | reported with the final READY evidence after this update |

## Remaining review

Independent editorial review is still required. This report is author evidence
only: it neither applies metadata to raw packs nor certifies facts, accepts the
candidate, commits it, or publishes content.
