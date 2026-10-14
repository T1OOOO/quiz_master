# LOTR legacy identity importer worker report

Status: DONE. Submitted for independent review as host_hub task
task-e080b3c3bd4c4301b0a57b3632490e4d.

Runtime identity: codex/gpt-6.1-sol, host_hub session
session-01d4329ba62e4186aaec1d8ffd804ad8.

## Changed files

- next/server/internal/content/import.go
- next/server/internal/content/import_identity_test.go

The importer accepts optional raw question option_ids and revision_number.
Explicit option IDs are validated without normalization and drive OptionID,
grading, and manifest CanonicalID values. Explicit revisions must be positive
integers. When either field is absent, positional option IDs, the long-ID
fallback, and revision 1 remain unchanged.

The regression copies the actual LOTR Return of the King 100-question fixture
to a temporary path, imports the unmodified copy, overwrites that same path
after adding only the target metadata, and imports again. It proves q95 keeps
option identities opt-1/opt-2/opt-3/opt-5 and grading opt-2, q93/q95 are
revision 2, the manifest retains the explicit IDs, and all 98 non-target
Question and QuestionMap values remain identical at the same source URI.

## RED receipt

Command: go test -p=1 ./internal/content -run '^TestImportExplicitQuestionIdentityMetadata' -count=1

Working directory: C:/ap/quiz_master/next/server

Exit code: 1

Actual output:

    --- FAIL: TestImportExplicitQuestionIdentityMetadata (0.06s)
        import_identity_test.go:70: unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadata2121847304\001\lotr_return_king_bts_100.json#/questions/92
    --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues (0.12s)
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_IDs_null (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2614820522\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_IDs_wrong_type (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2593426216\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_IDs_wrong_length (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues850627694\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_IDs_duplicate (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues253785775\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_ID_blank (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues3446716139\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/option_ID_illegal (0.01s)
            import_identity_test.go:140: want option_ids, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues256213229\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_null (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues472303196\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_wrong_type (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2240650581\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_zero (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2607325588\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_negative (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues3084328146\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_fractional (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2375902219\001\legacy.json#/questions/0
        --- FAIL: TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues/revision_overflow (0.01s)
            import_identity_test.go:140: want revision_number, got unknown_field: C:\Users\ALEXEY~1\AppData\Local\Temp\TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues2269519424\001\legacy.json#/questions/0
    FAIL
    FAIL	quiz_master/next/server/internal/content	1.065s
    FAIL

This is the expected RED: the importer rejected both requested fields as
unknown before the production change.

## GREEN and bounded verification receipts

Focused GREEN:

    $ go test -p=1 ./internal/content -run '^TestImportExplicitQuestionIdentityMetadata' -count=1
    ok  	quiz_master/next/server/internal/content	0.944s

Exit code: 0

Full content package:

    $ go test -p=1 ./internal/content -count=1
    ok  	quiz_master/next/server/internal/content	2.024s

Exit code: 0

Relevant quizctl validation:

    $ go test -p=1 ./cmd/quizctl -count=1
    ok  	quiz_master/next/server/cmd/quizctl	15.948s

Exit code: 0

gofmt was applied to the two owned Go files. git diff --check exited 0;
Git emitted only its configured LF-to-CRLF advisory for import.go.

## Final SHA-256

- next/server/internal/content/import.go:
  53A2BDA07C3FCCF0342578D0884A27B7995832F4DFD9A57FD856EF62CF8AA1EC
- next/server/internal/content/import_identity_test.go:
  560F9652D87CA75C579C21A973DFEA0DC3CA498D1E5E2C09DA5DB3136D7FE013

## Remaining gates and limitations

- Source URI remains filepath.Clean(path); staging-path hash differences are
  not fixed or claimed fixed.
- No actual corpus, collection, configuration, controller, Beads, Git
  mutation, CI, Linux build, package, browser, Docker, SSH, or deployment
  change was made.
- Root must integrate the raw fields, rebuild canonical metadata and the API
  component, and run the unmodified candidate-image API/Reader runtime gate.
- Passing importer tests are not publication approval. Independent Claude
  review remains required.
