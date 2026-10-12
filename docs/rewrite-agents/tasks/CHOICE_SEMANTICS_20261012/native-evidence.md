# Choice semantics evidence — 2026-10-12

Hub task: `task-a6ee0747f47942d280758aaa118b5360` (`quiz_master-xkr`)

## Change

`_ChoiceControl` retains `stableId` as `Semantics.identifier`, which Flutter documents as a native accessibility/test identifier not exposed to app users. It no longer assigns that internal ID to the spoken `Semantics.value`. The public label, selection state, enabled state, pointer activation, and existing Enter/Space handling are unchanged.

The regression in `test/public_contract_and_cards_test.dart` uses the deliberately internal value `private-option-1` and checks both `single_choice` and `multiple_choice`: the spoken label remains `Option 1`, `SemanticsData.value` is empty, and `SemanticsData.identifier` retains the stable ID.

## Actual checks

1. RED before the production edit:
   ```powershell
   flutter test test/public_contract_and_cards_test.dart
   ```
   Failed in the new regression with `Expected: empty; Actual: 'private-option-1'` at `public_contract_and_cards_test.dart:275`.

2. GREEN after the minimal edit:
   ```powershell
   dart format lib/main.dart test/public_contract_and_cards_test.dart
   flutter test test/public_contract_and_cards_test.dart
   flutter analyze lib/main.dart test/public_contract_and_cards_test.dart
   ```
   The targeted widget test completed `+17: All tests passed!`; analyzer reported `No issues found!`.

3. Wider check:
   ```powershell
   flutter test
   ```
   Completed with one unrelated failure in `test/discovery_test.dart`: `full catalog can be browsed without creating a guest` still requires the stale text `131 quizzes · 4008 questions`. This task does not own that catalog-count fixture. The new choice-semantics test passed in this wider run.

4. Live-app probe:
   `dart_flutter.dtd listDtdUris` found no running debug/DTD process. No hot reload was possible, and this task explicitly prohibits a web build.

## Review readiness

Ready for a different-provider review of the two owned source files. No content, catalog, asset, build, deployment, or Git operation was performed.
