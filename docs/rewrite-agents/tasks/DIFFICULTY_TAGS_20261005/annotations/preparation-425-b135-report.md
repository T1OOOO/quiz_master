# preparation-425-b135: author handoff

Scope: the 135 exact ordered quiz identities in `PREPARATION_425_B135_IDS.json`, against frozen source baseline `e802ed21db936bdb9809bab2d137903eb0aa425e` and taxonomy `qm-tags-v1` semantic SHA256 `07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151`.

All 135 complete raw records were read in ordered batches of 25, 25, 25, 25, 25, and 10, including stems, every option, keyed answer, and explanation. The candidate records are literal individual assessments in that same order; no source quiz, accepted decision, manifest, taxonomy, or Git state was edited.

Difficulty counts: 2=9, 3=26, 4=37, 5=34, 6=18, 7=9, 8=1, 9=1; no score 1 or 10 was assigned. Low confidence: `prep-folklore-006`. Flagged records: `prep-film-directors-35` (`role-distinction`); `prep-folklore-001`, `prep-folklore-002`, `prep-folklore-007`, and `prep-folklore-010` (`version-specific-claim`); `prep-folklore-006` (`factual-claim-needs-source`, `regional-term`); `prep-folklore-009` (`regional-term`). These flags preserve concerns for review; they do not certify the underlying claims.

Fresh checks (cwd `C:\ap\quiz_master`):

- `python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/preparation-425-b135.json --partial` → `Validated 135/4078 annotations; source integrity preserved.`
- Ordered candidate keys equal the frozen manifest: 135/135, all 135 unique. Accepted scan found 2,665 accepted record keys and zero overlap with this candidate.
- SHA256 matched `INVENTORY.json` for all six referenced source packs: `prep_books_modern`, `prep_compositions`, `prep_film_actors_1`, `prep_film_actors_2`, `prep_film_directors_1`, and `prep_folklore`.

Remaining limits: ratings are editorial estimates for the stated Russian general-knowledge audience, not calibrated response data. The narrow regional and variant-specific folklore claims retain flags for independent factual review. This is author readiness for review, not acceptance, application, publication, or factual certification.
