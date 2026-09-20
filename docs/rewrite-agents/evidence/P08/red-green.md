# P08 observed red/green evidence

All commands ran from `C:\ap\quiz_master` against the unfinished P08 worker
scaffolding, then the completed implementation. No production/legacy files or
accepted schemas were changed.

1. `go test ./next/server/internal/content` exited 1 after adding the golden and
   negative import/hash/diff cases. Representative failures: multi case remained
   `single_choice`; malformed/duplicate/out-of-range multi arrays were accepted;
   difficulty 0 and -1 were accepted; malformed scalar answers returned the wrong
   code; blank stems and normalization collisions passed; canonical hashing escaped
   Unicode/HTML; invalid publication time passed; changed question diff returned
   `no changes`. After the mapping/validation/hash/diff implementation, those same
   tests passed.
2. The normalization vector runner initially exposed a fixture JSON spelling error
   (`\v` is not valid JSON); the fixture was corrected to `\u000b`. The valid test
   then exposed an actual x/text v0.34.0 Cherokee mismatch: `Ꭰꭰ` folded to `ꭰᎠ`
   instead of P04/Python's `ᎠᎠ`. A targeted canonical-uppercase correction passed
   the unchanged valid vector. NFC, sharp-S, Greek sigma, Turkish I, ligatures,
   Cyrillic, whitespace and zero-width cases also pass.
3. `go test ./next/server/cmd/quizctl` exited 1 in the real executable end-to-end
   test because the original CLI returned `unsupported command "validate"`.
   The implemented import/validate/build/diff flow then passed byte-identity,
   mutation diff, real pack, invalid input and overwrite cases.
4. Adding the forced-import collision case produced exit 1: importing
   `HOME-ALONE-1-PART-1` over the existing `home_alone_1_part_1` destination returned
   success. Manifest preflight under the output lock now returns `id_collision`,
   and the executable test passes.
5. `go test ./next/server/internal/content -run 'TestRawSchema|TestOutputDestination'`
   exited 1: file path cleanup erased an explicit `..` segment, and raw schema
   errors omitted the question pointer. The corrected path check runs before
   cleaning; schema errors retain only sorted JSON pointers and never validator
   messages containing instance values. Both unchanged tests passed afterward.

The final fresh full/focused suites, exact durations, exit codes and independently
recomputed artifacts are in `checks.json`. Cases added for already-working paths
are characterization/coverage tests, not falsely claimed as observed regressions.
