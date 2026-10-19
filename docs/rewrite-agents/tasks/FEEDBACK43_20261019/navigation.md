# Feedback 43 navigation

Status: READY for independent review; this report is not an acceptance or publication record.

The quiz journey now lets a player select any question from a compact horizontal navigator. Each
question has one of three visible, screen-reader-labelled states: answered (server receipt),
unanswered, or uncertain (a locally staged answer that has not been sent). Revisiting an answered
question keeps it read-only, so navigation cannot submit it again. Completion now waits until every
attempt snapshot has a receipt rather than assuming receipts arrived in question-index order.

Verification on 2026-10-19 from `next/apps/quiz_app`:

- RED: `flutter test test/feedback43_navigation_test.dart` initially failed because
  `JourneyState.stagedByIndex`, `QuestionProgress`, and the progress helpers did not exist.
- GREEN: `flutter test test/feedback43_navigation_test.dart` passed.
- `flutter analyze lib/journey.dart lib/journey_pages.dart test/feedback43_navigation_test.dart`
  passed with no issues.
- Existing narrow-phone regressions passed at 390x736 and 360x640; the large-text scrolling case
  passed.
- A full `flutter test` run reached 129 passing tests before failing unrelated current atlas/library
  feedback tests (`feedback43_atlas_test.dart` and `feedback43_library_test.dart`); it did not
  complete within the bounded run.

The existing two-second correct-answer auto-advance and pause/resume control remain unchanged.
`openQuiz` already loads the session and selected catalog concurrently before creating one
authoritative attempt; no safe redundant request was found to remove within this scope.

Risk: no live Flutter debug target was running, so hot reload could not be performed. The
navigator's button targets are compact to preserve the tested 360px viewport; its labels expose
the full question number and status to assistive technology.
