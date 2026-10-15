# Eight actor mini-article integration

Status: READY for an independent different-provider integration review. This is an integration record, not a publication or a new fact check.

## Imported inputs

- `ACTOR_FOLLOWUP_FOUR_20261015/draft.json` SHA-256: `ed42da25aa3cb2a0d4c38d1b5278d22a298d83ce8c0605a1007d2bb50fd80b7d`
  - Claude final receipt: task `task-a145c7719d2d4c35bdc55dbc8d896070`, state `ACCEPTED`, run `run-0e9fcebfa5694abebf4728fcae28b68b`, trace `49f2729cbf6164463a6a8424defedac9021087c74b395ef517363fa779f0632f`.
- `ACTOR_FINAL_FOUR_20261015/draft.json` SHA-256: `e3e8e982dcc5f5f34b3589858ec5e3551d9a8abcc4a48336103d986b1333dc79`
  - Claude final receipt: task `task-f2f5b02542094c898cc8793413bb0c5c`, state `ACCEPTED`, run `run-c72e11e4dc06460a80d03ba1ef88e987`, trace `1434601b9d7704075133f596a8c8b46a86ca07d536145e7cd7eaa6b9487020b2`.
- Frozen public snapshot `prep-film-actors-1.json` SHA-256: `ae38b61aacea958b5f773198f0fecf480e218508f857120e66bddec3d6175422`.

The canonical draft preserves the eight source objects in order, with exact bindings for `cinema-oct3-013` through `020`. The review records the actual article writer (the accepted tasks' assignee), the distinct Claude reviewers, and Root separately as the task author alongside both genuine accepted receipts.

## Outputs and preservation

- Canonical eight-article draft: `study/question_articles/drafts/cinema-actors-final-eight-20261015.json`
  - SHA-256 `5bcc7beb3888c7f621f4d2c059b31174a1c93132f1393c4d30b83ce527b54f2b`
- Canonical receipt-backed review: `study/question_articles/reviews/cinema-actors-final-eight-20261015-review.json`
  - SHA-256 `cc4785e6c34c7721c98abd36a55472325629efe27472efe126736250b091e440`
- Generated reader catalog: `next/apps/quiz_app/assets/study/question-articles.json`
  - SHA-256 `cfb7188dd04e076fefc5fa0e537684fe7a01a8e36e75f017409f96c928a333f4`

The output has 299 articles and 180 question references: 178 play against the current public catalog and two known noncatalog Study references remain. The 291 pre-existing output objects were retained exactly; their canonical sorted-object digest before and after export is `b4825c2e8c642c5142b7a4090503bb22592df92a21cfbc316ebb717013d8a8f1`.

## Checks

- `python study/question_articles/build.py --write` from `C:\ap\quiz_master`: PASS, 299 independently reviewed articles.
- `python study/question_articles/build.py --check` from `C:\ap\quiz_master`: PASS.
- `python test_build.py` from `C:\ap\quiz_master\study\question_articles`: PASS, 3 tests.
- `python test_coverage.py` from `C:\ap\quiz_master\study\question_articles`: PASS, 2 tests.
- `python check_reader.py` from `C:\ap\quiz_master\study`: FAIL in pre-existing foreign scope: `test_flutter_export_preserves_questions_and_source_links` expects 10 modules, current payload has 6. No change was made to `study/check_reader.py`.

## Limits

An independent different-provider integration review remains required. This work did not modify Flutter, API, builder/schema, question options/keys, snapshots, Beads, Git, or publication state.
