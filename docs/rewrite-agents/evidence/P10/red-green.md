# P10/P10F observed RED/GREEN evidence

Commands ran from `C:\ap\quiz_master\next\apps\quiz_app`.

1. Typed staged answers: after adding exact single/multi/text expectations and
   a real Dio wire-boundary case, `flutter test test/api_repository_test.dart`
   failed to compile because `StagedAnswer` did not exist and
   `submitAnswer` accepted an untyped `Map<String, Object>`. After adding the
   sealed staged-answer variants and serializing only at the repository
   boundary, the focused repository run passed 11 tests.
2. Empty catalogs and UTC instants: decoder cases were added for a valid empty
   catalog plus date-only, offsetless and non-UTC expiry/accepted/finished
   timestamps. Making empty catalogs displayable exposed that the previous
   "secret-bearing catalog" test had only used emptiness as its failure; that
   test was corrected to include an actual private `grading` field. The focused
   repository run then passed.
3. Snapshot/history alignment: focused negatives cover bundle mismatch, stale
   question revision, unknown/missing/duplicate options, positional-map
   mismatch, missing receipt, wrong receipt ID and wrong receipt revision.
4. History retry: the new widget case failed with Flutter's
   `setState() callback argument returned a Future` assertion. `_reload` now
   creates the future before a synchronous `setState`; the EN/RU
   error → retry → empty case passes.
5. Full journey: the old one-card generated fixture was deleted. Its replacement
   uses a deterministic injected Dio HTTP adapter and the real app/providers to
   bootstrap, load 25 questions, start, apply reversed pinned option order,
   submit each question once despite duplicate taps, finish once, fail/retry
   reveals without refinish, render score plus 25 aligned explanations, load
   history twice, navigate back, and preserve RU/dark state. The first
   `HttpServer` harness attempt was discarded because Flutter's widget-test
   network override blocked it; it is not counted as behavioral RED evidence.
   The corrected in-process transport journey passes.

Final focused result: 19 passed. Final whole-app result: 34 passed.

## Final reviewer delta

6. HTTP transport policy: a new base-URI table test failed because
   `http://api.example.test` was accepted. The repository now requires HTTPS
   for remote hosts and permits plain HTTP only for `localhost`, IPv4
   `127.0.0.0/8`, and IPv6 `::1`; the focused case passed.
7. Reveal identity/order: the new duplicate, wrong-quiz, swapped, missing and
   pinned-revision negatives failed to compile because ordered reveal
   validation did not exist. `QuizApiClient.reveals` now invokes the added
   exact one-to-one validator using the catalog quiz ID supplied by the journey.
   Direct client-response negatives prove the boundary rejects duplicate,
   wrong-quiz, swapped and missing reveal arrays.
8. The three typed wire cases now explicitly assert the bearer header and exact
   idempotency key. The genuine 25-question journey explicitly inspects the
   first visible card and proves its labels are `Option 4`, `Option 3`,
   `Option 2`, `Option 1` before answering.

Final reviewer-delta focused result: 22 passed. Fresh whole-app result: 37
passed; analysis reported no issues.
