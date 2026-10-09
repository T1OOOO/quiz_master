# Actual managed Codex advisory; implementation pending

Run run-f592c9c629954fdf9a4b6a83c16b09b4; provider codex, requested model gpt-6-luna. Exit0, whole7-command trace read-only/nochildren checked. Native preparation only, not different-provider release acceptance. No tests/build/browser/publication executed.

## Findings

Current practice has two distinct modes:

- **Study practice:** The article’s “Practice” button opens `/study/:moduleId/practice`. `StudyPracticePage` shuffles that module’s questions, takes up to 20, tracks a local score, and uses `QuestionCard` with its existing feedback and explanation flow. It is unranked and does not submit an attempt. See [study_pages.dart](C:/ap/quiz_master/next/apps/quiz_app/lib/study_pages.dart:685).
- **Journey quiz:** `CatalogPage` uses the quiz catalog and `journeyProvider` for server-backed attempts, rounds, answer submission, and results. It has separate state and behavior; the proposed mixed practice should not route through it. See [journey_pages.dart](C:/ap/quiz_master/next/apps/quiz_app/lib/journey_pages.dart:39).

## Minimal insertion plan

1. Add a **Mixed practice** entry to `StudyLibraryPage`, beside the library introduction and before the module grid. It should navigate to a dedicated mixed-study route.
2. Add that route in `main.dart` near the existing `/study` routes. `main.dart` is outside the inspected study/test paths, so this route edit is an additional required insertion point.
3. In `study_pages.dart`, reuse `StudyPracticePage` and its current `QuestionCard`, answer handling, feedback timer, pause behavior, and completion/retry UI. Give it a mixed-mode input (or equivalent small distinction) that builds a question list from all loaded modules, shuffles it once, and takes 10. Keep each selected question paired with its owning `StudyModule`; the current feedback dialog needs that module for source links and explanations.
4. Keep the existing module route and its 20-question behavior unchanged. Mixed mode remains local and unranked; it should not alter `JourneyState` or submit attempts.

## Test requirements

Add cases in [study_test.dart](C:/ap/quiz_master/next/apps/quiz_app/test/study_test.dart):

- The library entry navigates to the mixed route.
- Mixed practice displays `1 / 10`, draws questions across modules when fixtures contain multiple modules, and completes at exactly 10.
- Selected question IDs are unique; fewer than 10 available questions yields a shorter run rather than duplicate questions or an index error.
- Feedback for a question from another module shows that module’s explanation and sources.
- Retry resets score, question index, and feedback state.
- Existing single-module practice still runs its current up-to-20 behavior.

## Edge cases and limits

Empty catalogs should show the existing missing/empty study message rather than starting a zero-length session. If the total question pool is below 10, use all available questions. Keep question IDs unique across modules or qualify IDs with module ID for card keys and option IDs, since module-local IDs could collide. Preserve source ownership for feedback. The existing in-memory shuffled order is not a durable/random-seed contract.

I read the `qm-flutter`, `ponytail`, and `graphify` skill instructions. The project-local `qm-flutter` skill was available; the requested skills list was empty. No files were changed, and no tests were run.

Skipped route implementation and execution checks as requested. Main limitation: exact behavior for a pool with fewer than 10 questions is a proposed edge-case policy, not an existing product requirement.