# Remaining server feedback: mobile verification and publication

Beads owner: `quiz_master-rudc`. Baseline source: `cc99b021`.
Fresh read-only production retrieval found 43 open and 23 resolved reports.
Private report bodies, identifiers and screenshots stay under the restricted
`.run/feedback43_20261019/private` directory and are not part of this packet.

The user clarified that ordinary quizzes should appear alongside study material.
Publication is explicitly authorized. Resource-queue waiting is waived by the
project rule; ownership, independent review and release gates remain binding.

## Acceptance groups

Original report ordinals below are local retrieval positions, not server IDs.
They are an acceptance checklist; none is considered resolved before production
verification of the corresponding behavior.

| Reports | Evidence required |
| --- | --- |
| 1 | Correct answer waits two seconds; pause/resume works without a Continue button. |
| 2–8 | Bundled illustrations, readable contents/contrast/tables, accessible image fallback, visible links to related ordinary quizzes. |
| 9, 10, 12, 13, 45, 48, 51, 63–66 | Direct topic practice, readable mobile atlas controls, manual map zoom, visible country selection, all 88 constellations and concrete wrong/correct/retry practice checks across all 13 sections. |
| 11 | Expanded sourced skeleton and brain coverage, explicit group counts, optional Latin, no invented diagram anchors or claim of exhaustive microscopic anatomy. |
| 14 | Measure real quiz opening; confirm one bootstrap/catalog pair followed by one attempt request. |
| 15, 16, 17, 29, 32 | Exact-revision reference links after answer reveal; explain the referenced question's distractors and provide verified listening/source links where relevant. |
| 19, 24 | Jump between questions, preserve answers, manually mark uncertainty, recover immutable submissions, review the final question before finishing. |
| 20 | Ordinary quizzes available beside learning material, per user clarification. |
| 21, 22 | Russian labels and complete published catalog, rather than a three-question demonstration. |
| 25, 27, 28, 31, 33, 36, 40, 41, 57 | Compact full-width quiz cards, topic thumbnails/backgrounds, readable category grid and no obsolete seasonal header. |
| 26 | Difficulty selection remains available; verify actual pack counts and handling of small banks honestly. |
| 42, 56 | Direct quiz launch without a long numeric-round picker; meaningful topic organization must be verified rather than inferred from removal of the picker. |

## Ownership and integration

The navigation and study/library workers initially owned separate Dart files.
The lead took over navigation after independent review found lifecycle/retry
defects and reproduced five failures with controller and mobile widget tests.
The lead also owns Quizipedia, fact extraction, content import and the release
controller. The anatomy worker changed model/UI only; editorial additions were
drafted separately and require independent factual acceptance before import.

The next release controller uses fresh Helm 66 / Deployment 64 pins and must
register the exact canonical containerd digest reference before publication.
Historical reviewed executors are preserved. A successful build or test run
alone does not authorize resolving a report or claiming a publication.

Mobile evidence must name Chrome viewport emulation unless a physical Android
device is actually available. Keep unrelated legacy deletions and editorial
drafts untouched. Commit/push only this packet's stable owned files with
`[skip ci]`; do not invoke GitHub Actions.
