# Article reader overlay fix (quiz_master-rzc)

The published article reader at390x844 lets the global feedback FAB cover body text. Root inspected next4 published screenshots and a native read-only explorer independently traced the cause: ShellRoute wraps its child Navigator in _FeedbackOverlay's Stack, while QuestionArticleLink opens its sheet on that nested Navigator. The sibling FAB is painted above the reader.

Owner: Root. Files: question_articles.dart, question_articles_test.dart and this evidence folder. The shared article opener reaches quiz feedback/results, study explanations and Quizipedia; no caller changes are needed. The other Quizipedia spot chooser is outside this repair. No content, API, taxonomy, feedback status or dependency changes.

Fix: open the article sheet on the root Navigator so it covers the shell overlay. The global feedback button is available again after the reader closes; it is intentionally behind the modal while reading. No reader-specific reporting callback or new state framework is introduced.

Verification: a nested Navigator/Stack regression must fail because the shell feedback control remains hit-testable over the old reader. After the one-line fix it must be blocked while the reader is open and restored after close; test system Back reopening/dismissal as well. Run full Flutter suite and analyzer, obtain independent Claude review, commit/push, build fresh production Flutter once, perform browser article QA using that build, then server preparation/review/publication and public verification. No GitHub Actions. Keep26 real feedback reports open until their own published verification. Do not claim physical Android or screen-reader verification.

Historical production baseline: quiz-2026.10.12-culture-c15eefc, Helm39,131packs/4020questions/218articles, image044ad58832bf336b2443949e6beb2f8ed8e04c53802cd66ac232ce58401b9793. Source c15eefc; checkpoint6c5f20f. Preserve all69 foreign hashes and other projects/resources. This project has no mandatory resource-queue waiting.
