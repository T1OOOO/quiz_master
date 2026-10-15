# Exact final regression evidence

The first independent Claude review accepted the code quality and geometry but
requested rework of the evidence: the original RED run used the initial single
case, before the test was parameterized with 1x/2x text and safe insets. The
original report did not explicitly distinguish those test iterations. The
original report, manifest, logs and REWORK callback remain unchanged.

Root has now run the exact committed test file against the pre-fix source from
`5c5a5d9^`, after the QA build completed. Both final text-scale cases failed
the intended overlap assertion; the other three feedback tests passed. The
test's SHA-256 is in `exact-final-red.json`. The fixed Dart source was restored
byte for byte in a `finally` block and the test file did not change. Source
commit `5c5a5d9` still describes the complete application change.

This additional evidence addresses the review finding without expanding the
application patch. `exact-final-green.log` records the run after restoration.
Production and QA release builds are additional local evidence only, and the
release-browser PNG is the actual compiled production Flutter artifact served
on loopback. No new immutable Linux candidate or deployment is claimed.
