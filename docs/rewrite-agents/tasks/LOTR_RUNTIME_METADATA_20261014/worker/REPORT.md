# LOTR runtime metadata test compatibility report

Status: DONE. Ready for independent Claude review.

Host hub task: task-eacecade1e4a40aa872354e1b39fca88

Runtime identity: codex/gpt-6.1-sol, host_hub session
session-01d4329ba62e4186aaec1d8ffd804ad8.

## Owned change

Only next/server/internal/content/import_identity_test.go was changed.

The actual LOTR fixture is decoded with json.Decoder.UseNumber. Before the
baseline import, the test removes option_ids and revision_number only from raw
questions lotr_rk_93 and lotr_rk_95, marshals that decoded object, and writes it
to one temporary source path. It then adds the reviewed q93/q95 metadata to the
same in-memory object, overwrites the same temporary path, and performs the
explicit-metadata import.

Existing assertions remain in place for:

- absent-field revision 1 and positional option-ID defaults;
- q95 option identities 1, 2, 3, 5 and grading option 2;
- q93/q95 revision 2;
- manifest SourceIndex/CanonicalID identity;
- 98 unchanged non-target Question and QuestionMap values at the same source
  path;
- malformed option_ids and revision_number rejection.

This setup works whether the actual source fixture already contains reviewed
identity metadata or not.

## Root raw-ready evidence

Root reported that only revision_number 2 on q93/q95 and q95 option IDs
1, 2, 3, 5 were integrated, and that the actual quizctl import of 100 questions
exited 0 before this worker test ran.

The current raw fixture SHA-256 was independently read after the signal:

    C6F6CBF899DE42E197B5D041C6F9206207CAF28624DA9DDEBDEA540CDDB8B7E6

## Actual command receipts

Formatting:

    gofmt -w 'internal/content/import_identity_test.go'

Working directory: C:/ap/quiz_master/next/server

Exit code: 0

Output: empty.

The single authorized targeted Go test was run only after Root's raw-ready
signal:

    go test -p=1 ./internal/content -run '^TestImportExplicitQuestionIdentityMetadata' -count=1

Working directory: C:/ap/quiz_master/next/server

Exit code: 0

Wall time reported by the command runner: 6.9067881 seconds.

Actual output:

    ok  	quiz_master/next/server/internal/content	1.168s

No other Go or full-suite test was run by this worker.

## Final SHA-256

- next/server/internal/content/import_identity_test.go:
  DDD7F6BE121BE766EA4B4C63EEA3AAE16D96A3ABBCFF492B71A9233AE6F08F19
- quizzes/Cinema/LOTR/lotr_return_king_bts_100.json, read-only:
  C6F6CBF899DE42E197B5D041C6F9206207CAF28624DA9DDEBDEA540CDDB8B7E6

## Limitations and remaining gates

- No importer, raw source, canonical content, Reader data, release data,
  controller, configuration, Beads, Git, CI, build, browser, SSH, package, or
  deployment edit was made by this worker.
- Root owns full quality gates, canonical/API component rebuild, runtime
  candidate-image validation, source/component freeze, and publication.
- This passing targeted unit test is not publication approval.
