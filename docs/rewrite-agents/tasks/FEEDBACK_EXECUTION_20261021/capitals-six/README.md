# `prep-capitals-1`: reviewed six-option packet

This packet is the reproducible local canonicalization record for the YP19
capital-cards change. It does not authorize a server import, deployment,
feedback-status change, or commit.

## Accepted evidence

| File | SHA-256 |
| --- | --- |
| `accepted-draft-v3.json` | `ec6aa50dbb8bbddce2642e871bdc89046a26a747f608c5c9430ede89c443e58f` |
| `source-evidence.md` | `57def723fbc1f67c9eb2b4a13b91fbe2e73046799413e823df846ab6dbbf5fb7` |
| `final-review-v3.json` | `aa094cbada1938ea5e184005ab2e4735bd27baa4909e388f7b68a3a53e9ad619` |
| `final-review-v3.md` | `722b025e55dda55c4218edeb8d4178db34dc84878678f87c9b8a23f593095de6` |
| generated `source.legacy.json` | `e00d79bfc964fd7800bc7f446b5c86c7f70aa8008ebbf76e28ba6a9d2dcc25ea` |
| generated `provenance.json` | `7519fbf49562921b93b183582a1d33c37c41ca14c3888d680b70776b4a500893` |

`build_packet.ps1` hashes the three accepted packet inputs before producing
the controlled legacy source. It also verifies that the final review is bound
to the accepted v3 draft. Its source-hash note records the real raw-byte
canonical draft hash that v3 reviewed; the incompatible private declaration is
retained only as an explicitly unverified historical field.

## Reproduce locally

Run from the repository root with PowerShell 7; Windows PowerShell 5 cannot
reliably parse these UTF-8 Russian strings without a BOM.

```powershell
pwsh -NoProfile -File docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/build_packet.ps1

$out = '.run/feedback_execute_20261021/capitals-six/recheck'
go run ./next/server/cmd/quizctl import --in docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/source.legacy.json --out $out --force
go run ./next/server/cmd/quizctl build --in "$out/draft.json" --out "$out/bundle.json" --force --version 2026.10.21.yp19-capitals-six --published-at 2026-10-21T09:35:54Z
go run ./next/server/cmd/quizctl validate --in "$out/draft.json"
go run ./next/server/cmd/quizctl validate --in "$out/bundle.json"
pwsh -NoProfile -File docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/verify_candidate.ps1 -Baseline .run/feedback_execute_20261021/capitals-six/original-canonical/draft.json -CandidateDirectory $out
```

The first reviewed candidate and its deterministic repeat are private evidence
under `.run/feedback_execute_20261021/capitals-six/`; they are intentionally
not versioned packet outputs. The final canonical hashes are:

| Canonical file | SHA-256 |
| --- | --- |
| `next/content/prep-capitals-1/draft.json` | `68f61b50d06f5ddeddc23f52c0386483c908fd7d9748a4a5c888884679832985` |
| `next/content/prep-capitals-1/bundle.json` | `f6372d69a929dc8ddb8d623668a0cf0c6672a820179888e7bb3634b87e6af8ae` |
| `next/content/prep-capitals-1/manifest.json` | `755692aff8a11be862e53c8f074637124db6573675d6ccd7e6cfa67c4603ade1` |

## Checks and attempt boundary

The packet verifier checks every public option ID and text against the draft,
all 40 accepted additions, all 80 legacy option IDs and texts, stable correct
option IDs, private-only grading, and the three accepted stem/explanation
repairs. It passed after canonical replacement.

The SQLite snapshot tests passed:

```powershell
go test ./next/server/internal/sqlite -run 'Test(AnnotatedPartialAttemptPinsMetadataAfterRepublish|RoundsCoverEveryQuestionOnceAndPinShuffledSnapshots)' -count=1
```

They cover pinned snapshots when content is republished, so existing attempts
are not recalculated from this newer canonical bundle. The PostgreSQL
integration lifecycle test was attempted with:

```powershell
go test -tags integration ./next/server/internal/attempts -run TestPostgresAttemptLifecycle -count=1
```

It could not connect to `localhost:5432`; no database was started or changed.
The normal production-SQLite suite passed with the focused content and
`quizctl` suites.

## Next content-release import procedure

Do not run `quizctl import` directly into an already populated
`next/content/prep-capitals-1`: its manifest collision guard correctly rejects
a different controlled source hash. A release owner must import into a fresh
private staging directory, verify the generated triple against the hashes
above, and use the reviewed `replace_canonical.ps1` under exclusive ownership
to replace exactly `draft.json`, `bundle.json`, and `manifest.json`. Then run
both `quizctl validate` commands again.

Server publication is outside this packet. The current production image reads
the legacy `/app/quizzes` tree, so changing this canonical triple alone does not
publish the twenty six-option questions. A separate reviewed content release
must replace exactly the legacy capitals source, derive its runtime bundle with
the actual source URI, and rehearse grading and an existing attempt on a copied
SQLite database. Runtime source URIs participate in content hashes; runtime
bundle hashes therefore differ from the controlled canonical packet. Preserve
attempt snapshots tied to older bundles and never overwrite `attempt_bundles`
or mutate prior attempts. The frozen frontend release keeps all165legacy files
unchanged.
