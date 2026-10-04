# Mobile question layout — 2026-10-04

User reported the gastronomy etiquette question with lower choices below the phone viewport. The existing question scroll view was working, but fixed quiz chrome plus spacious six-choice cards exceeded the available height.

## Reproduction and change

Regression tests failed before the fix at390×736 and360×640: the sixth/earlier choice was not hit-testable. Intermediate measured360×640 layout: quiz title y56..118; question card y208..679; scroll viewport y208..628. Each dense RadioListTile was44px plus6px wrapper padding, giving a50px outer control. The471px card exceeded its420px viewport.

The quiz title and round now share one flexible row. The separate48px library-link row is removed; shared Home and Back navigation remain available. Narrow screens use18px question text,16px choice text,12px card padding and4px choice spacing. Long content still scrolls, and system text scaling remains enabled. Desktop styling and answer IDs are preserved.

## Verification

- RED observed before production edits: both phone cases failed on clipped answers.
- Final `flutter test --no-pub --concurrency=1 --reporter expanded`: all72 tests PASS. Both phone cases assert all six full controls fit within the actual scroll viewport, each control is at least48px high, and selecting option6 submits stable ID `opt-6`. A320×568/text-scale2 long-answer case verifies scrolling and submission without layout exceptions. Existing media, keyboard, multiple-choice, feedback, study and desktop tests pass.
- `flutter analyze --no-pub`: no issues found.
- `flutter build web --release --no-pub --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --pwa-strategy=none`: exit0,61.2seconds. Existing deprecated PWA flag/unused Cupertino font notices remain.
- Independent `qm_reviewer` review approved requirements and all five code-quality axes after correcting viewport-bound assertions. Reviewer inspected source/tests only; lead executed the gates. This is independent-session review, not cross-provider acceptance.
- `git diff --check` for the changed client files: PASS.

Production/browser evidence is appended after the exact release. Physical Android-device verification has not been run; existing Android issue remains open. Unrelated study wave3/content20/Beads changes are excluded from this fix.
