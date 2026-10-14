# Native read-only input lookup — held research

Native explorer `/root/lotr_inputs`, Hub task `task-61df59d2ff974a56a04ed14bb044aba7`, reported the following after its finite lookup. This is an input map, not independent factual approval or authorization to publish the wording proposals. No runtime changes were made.

The task was submitted with structured findings and no changed files. `study/question_articles` was outside the explorer's allowed scope, so it did not inspect Reader implementation; the article-rebinding warning below follows question-revision semantics rather than an article-code review.

Raw source: `quizzes/Cinema/LOTR/lotr_return_king_bts_100.json`; source IDs `lotr_rk_93` and `lotr_rk_95`. Canonical files: `next/content/lotr-return-king-bts-100/draft.json`, `bundle.json`, `manifest.json`.

- rk93 revision1 SHA256 `349f08fd08ad1bded1cae123653e01a4f166fb3f8bf2d58304266c5bbad616d4`; Great River question. Options: Izen, Sirion, Bruinen, Brandywine, Glanduin, Anduin. Raw zero-based correct index5 corresponds to private `opt-6` Anduin.
- rk95 revision1 SHA256 `3e9c8b775c9379d9f145023e71b7f4c69ddf373c9ca30b4b4f63896c3070995a`; White Ships city question. Options: Pelargir, Mithlond, Edhellond, Tirion, Alqualonde, Lindon. Raw correct index1 corresponds to private `opt-2` Mithlond.

The manifest maps indexes to matching option IDs; private bundle grading retains these keys. Individual question hashes change only for edited question fields; unchanged questions retain their hashes. Whole draft/quiz revision and bundle SHA change with a patch, requiring whole-pack publication and exact article revision rebinding. Rehash implementation: `canonical.go:227-232`; loader `ReadDocument` at `validate.go:275`, `NewService` at `service.go:33`; catalog route `httpapi/attempts.go:67`. Bundle path is configurable via `QM_CONTENT_BUNDLE_PATH` (`config.go:26,47-51`); default is Home Alone. Do not assume that default represents production's aggregate catalog.

Reported registered relevant tags: `franchise:middle-earth`, `topic:lore`, `domain:geography`, `topic:world-geography`, `era:middle-earth-third-age`, `domain:literature`. Use `domain:screen`/`medium:film` only for explicit adaptation questions. Root still requires concrete candidate/private-key/article source review and rejects the known mixed distractors/workflow prose; rk96 stays held. The source file hash was abbreviated in the first message, so no expanded value is fabricated here.
