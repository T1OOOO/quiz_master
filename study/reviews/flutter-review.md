# Independent Flutter study review — 2026-10-04

Reviewer label: `review-flutter-study-0oj-final`. Frozen scope inspected:
`study_pages.dart`, `main.dart`, `source_style.dart`, `study_test.dart`, l10n,
pubspec/lock, and `assets/study/`. No files other than this report were edited;
no Flutter build, analyzer, browser, Git, or manual Android run was performed.

## Verdicts

- **Requirements compliance: REQUEST CHANGES.** The catalog/assets, deep links,
  article/TOC/resource images, HTTPS-only sources, local unranked answer mapping,
  20-question flow, retry, and source-backed feedback are implemented. The two
  feedback-state defects below violate the required keyboard/timer boundary.
- **Code quality: REQUEST CHANGES.** The implementation reuses the existing
  `QuestionCard`, `ExplanationPanel`, router, Riverpod provider, and localized
  strings well, with small explicit data models and a bounded local artifact.
  Its modal state must be made a real interaction boundary and its timer must
  respect lifecycle/non-data transitions.

## Required findings

1. **`next/apps/quiz_app/lib/study_pages.dart:621-626` — feedback does not
   disable or replace the underlying `QuestionCard`.**
   Trigger: select an answer, then press Enter/Space on the already focused
   choice (or activate a background choice where the overlay does not absorb
   the hit). The card is deliberately passed `reveal: null` and no
   `submitting: _wasCorrect != null`; `QuestionCard._disabled` therefore stays
   false. `_answer` happens to reject the callback, but keyboard focus and
   semantics remain in the obscured question instead of the feedback controls.
   Consequence: the centered overlay is not an accessible modal and violates
   the keyboard-focus requirement. Smallest correction: key the card by
   `question.id`, pass `submitting: _wasCorrect != null`, place a non-dismissible
   modal barrier beneath the dialog, and autofocus Pause/Continue when it is
   shown. This preserves the no-layout-jump Stack design while blocking the
   background state.

2. **`next/apps/quiz_app/lib/study_pages.dart:474-507, 630-661` — the
   auto-advance timer survives application suspension and a provider
   loading/error transition.**
   Trigger: choose a correct answer, background the app for more than one
   second, then resume; or cause `studyModulesProvider` to refresh/fail during
   the one-second window. The timer is cancelled only on widget disposal,
   module-ID changes, Pause, Continue, and advance. It may therefore advance
   unseen on resume, and can increment `_index` while the loading/error view is
   displayed. Consequence: a learner can lose a question without reading the
   feedback; timer cleanup is incomplete for the stated lifecycle boundary.
   Smallest correction: observe lifecycle state and cancel/pause pending advance
   outside the resumed state, and cancel it when provider data leaves the data
   branch (with a regression test for both paths).

## Directly verified positive scope

- Routes cover `/study`, `/study/:moduleId`, and `/study/:moduleId/practice`;
  SourceScaffold back/home and drawer paths preserve the existing quiz library.
- The provider loads the bundled catalog; direct count found 80
  `correct_answer` entries plus the catalog and all four hero PNGs. The data
  remains local to the explicitly unranked flow. `PublicOption` IDs include the
  immutable original option index, and the selected ID maps back to that index;
  no attempt/repository submission path is called.
- Article Markdown renders `resource:assets/study/` images, contents targets,
  and only opens absolute HTTPS URLs. The bounded 920px article/820px practice
  containers, `ListView`, `Wrap`, and `SingleChildScrollView` avoid a known
  unbounded-layout path; no source-level overflow bug was proven. Actual
  device/browser layout was not run here.
- ARB and generated RU/EN accessors agree for the study chrome. Direct
  dependencies are hosted on pub.dev and lock to `flutter_markdown_plus 1.4.0`
  (from declared `^1.0.12`) and `url_launcher 6.3.3`; their platform packages
  are transitive lock entries.

## Verification evidence and exclusions

- Read `study_test.dart`: ten focused widget cases are present, including real
  asset/catalog loading, 20-answer score/retry, routes, correct/pause/wrong
  behavior, repeated callbacks, TOC/source, and narrow text-scale layout. The
  reported green run is author evidence; I did not rerun it. Neither required
  finding currently has a lifecycle/modal-focus regression test.
- Reported earlier full-suite/analyzer/build evidence is not independently
  confirmed here. No Android device, browser/manual interaction, accessibility
  audit, or production/publication claim is made.

## Reviewed SHA-256

- `lib/study_pages.dart`:
  `c5997a4af2328be90bd4f11a6763e0f60e849bfbbe9638466d041e659dcb6801`
- `lib/main.dart`:
  `82607bdc10d64c2c207368dfdea3baec7faba3b3a9747bb188af523fd8947323`
- `test/study_test.dart`:
  `91835d76e2beab8c9b7821a41fff11d593ad6f441a3cc5452933f1a8298c2780`

## Final changed-scope re-review — 2026-10-04

- **Requirements compliance: APPROVE.** Both required findings are corrected.
  `QuestionCard` is now keyed by question ID and receives `submitting` during
  feedback; the background is excluded from focus/semantics, absorbs pointers,
  and sits behind a non-dismissible keyed `ModalBarrier`. The centered feedback
  scope and Pause/Continue autofocus establish a keyboard target without moving
  the underlying question layout. The pending correct-answer advance now pauses
  for every non-resumed application lifecycle state, provider loading/error, and
  a non-current route; disposal and module changes still cancel it.
- **Code quality: APPROVE.** The smallest changes preserve the existing local
  state model and standard Flutter primitives (`WidgetsBindingObserver`,
  `FocusScope`, `ModalBarrier`, `AbsorbPointer`) rather than creating another
  state layer. The route-current guard covers navigation racing the callback.

Direct review of the three new regressions confirms their intent matches the
fixed paths: background card/submitting plus keyboard Pause, lifecycle pause,
and provider-refresh pause. The reported focused run is green, but I did not
run Flutter myself; the full run, analyzer/build, Android/device, and
browser/manual evidence remain lead-owned exclusions.

- Re-reviewed `lib/study_pages.dart` SHA-256:
  `52b426587c7e33e482da1f50ef4f792ff0a0db68100b57f55ff6c16fc315e46f`
- Re-reviewed `test/study_test.dart` SHA-256:
  `8e0b146def687912e273cc1e2408e5273ad5711098c3e9b4be581039be8e142d`

## Final tiny visual-scope re-review — 2026-10-04

- **Requirements compliance: APPROVE.** `StudyLibraryPage` now explicitly
  supplies each module's bundled `assets/study/<id>-hero.png`, so study cards
  no longer fall through to the generic Nature category image. The article
  headline explicitly uses the dark `#655444` ink on its parchment card.
- **Code quality: APPROVE.** `SourceFolderCard.coverAsset` is an optional,
  backward-compatible override; every existing non-study caller retains its
  prior category-derived cover. Removing the duplicate semantics wrapper avoids
  a redundant accessibility node rather than changing card behavior.

The two new direct widget assertions correctly examine the rendered study card's
`AssetImage` and article title colour. I did not run the currently executing
full suite or inspect a browser/Android screenshot; those remain external
evidence, not asserted here.

- `lib/study_pages.dart` SHA-256:
  `7918cfcffa08ce60cff44d2f552ded5c453829859b7414f46ec6871d3dbb6d39`
- `lib/source_style.dart` SHA-256:
  `60ceab8b74d5ecbfae5e6aefc227ccb768a80a5484eff629a431793277318169`
- `test/study_test.dart` SHA-256:
  `b22d4cceba93449b5881850ef013f7388ed3183e5bdcd709880092b570dc5963`
