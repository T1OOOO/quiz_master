# Film craft pilot: duplicate and coverage notes

Accessed 2026-10-13. The release corpus was inspected with a targeted native
`rg` search across `quizzes/**/*.json` and
`next/apps/quiz_app/assets/study/question-articles.json` for Russian and English
terms covering Foley, ADR, J/L cuts, stop motion, sound design and montage.

- `quizzes/Cinema/People/cinema_people_20261011.json` has a different
  question about Margaret Sixel's award for editing *Mad Max: Fury Road*.
  It does not test split edits.
- `quizzes/Cinema/HomeAlone/home_alone_1_part_1.json` uses the word
  "монтаж" for a scene in a film, not editing terminology.
- The search found no released question whose answer tests Foley, ADR,
  J- versus L-cuts, or the frame-by-frame mechanism of stop-motion.
- `metadata/tags.v1.json` was inspected. Every draft item uses only existing
  IDs: `domain:screen`, `domain:arts`, and `topic:film-production`.

This is a narrow lexical/semantic duplicate screen, not a claim that all 4,044
released questions have had their facts re-audited.
