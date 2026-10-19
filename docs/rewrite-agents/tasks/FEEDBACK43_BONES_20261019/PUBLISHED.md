# Published Bones batch — 2026-10-19

Production: https://quiz.kotopedia.org

- Source36e0b68c64d1b6647923b5e5ddcc70d34e7edd60 pushed before publication.
- Build `quiz-2026.10.19-bones-36e0b68c`; Helm69 / Deployment67.
- Immutable image `sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a`.
- 281 anatomical structures:206 individual adult bones,8 skeletal groups,15 brain regions, major organs and glands. Original75 structures/47 authored questions/34 sources preserved.
- 13,588 extracted facts across13 sections; six Russian study glossaries /120 embedded self-checks.
- API208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa and all148 server quiz source files unchanged.

276 Flutter tests and analyzer passed. Independent factual/code/exact-image/outcome acceptance passed. Actual42/42 correct-answer grading and wrong-answer-zero rehearsal,305 article revision bindings, SQLite backup/restore, immutable image/CRI identity, Helm rendering, node/PVC and public exact-version/JS/static-asset checks passed. All user feedback content/screenshots were preserved.

Mobile QA: Chrome361×738 and320×568 emulation, with public-site retest. Individual-bone search/filter/source and selected-bone wrong→reveal→retry1/1 passed; both glossary and20 self-check links verified. Physical-phone testing was unavailable.

Three further original reports (6,8,11) resolved through the admin API only after independent outcome acceptance and publication. Original43-report batch now42 resolved /1 open. All-server feedback65 resolved /1 open. Ordinal26 remains open: global minimum20 is being implemented under `quiz_master-k2ux`; user explicitly chose close-topic merges plus standalone supplements. Current source work for that next batch is not part of this published image.

Actual postpublication imageFS20.157%; Ready node, unchanged safety thresholds, original PVC and rollback68 retained. Evidence is in adjacent JSON/review/mobile files.
