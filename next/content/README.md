# Local private content pipeline

`home-alone-1-part-1/` contains one controlled migration fixture: the 25 questions
from `quizzes/Cinema/HomeAlone/home_alone_1_part_1.json`. The draft and bundle contain
private grading and are **not client assets**. These files have not been published
or fact-checked. All source prose is retained verbatim; source explanations and
quiz title/category/description live in the private manifest because v1 has no
corresponding draft fields.

From the repository root:

```powershell
go run ./next/server/cmd/quizctl import --in quizzes/Cinema/HomeAlone/home_alone_1_part_1.json --out next/content/home-alone-1-part-1
go run ./next/server/cmd/quizctl validate --in next/content/home-alone-1-part-1/draft.json
go run ./next/server/cmd/quizctl build --in next/content/home-alone-1-part-1/draft.json --out next/content/home-alone-1-part-1/bundle.json --version 2026.09.20.p08 --published-at 2026-09-20T10:00:00Z
go run ./next/server/cmd/quizctl validate --in next/content/home-alone-1-part-1/bundle.json
go run ./next/server/cmd/quizctl diff --before path/to/old/bundle.json --after path/to/new/bundle.json
```

Existing outputs are refused; add `--force` to replace explicitly. `import --out`
is a directory with fixed `draft.json` and `manifest.json` names; `build --out` is
an exact file destination. Traversal and symlink destinations are rejected.
An existing manifest protects against replacing a different source with a
colliding quiz ID, even with `--force`. Stale `.quizctl-lock` after a killed
process is deliberately not auto-deleted; inspect the destination before removal.
The caller must have exclusive control over destination directories: protection
against a hostile process replacing parent directories is outside this local CLI.

All commands accept `--schemas` for the accepted local schema directory. No
schemas are fetched from the network. `validate` also accepts multiple trailing
file arguments and rejects duplicate quiz IDs across them. Validate the draft and
its corresponding bundle separately since they intentionally share a quiz ID.

Executable exit codes: **0** success (diff: identical), **1** semantic differences,
**2** invalid input, usage or I/O failure. `go run` itself translates a child's
nonzero code to its own exit 1, printing `exit status N`; CI needing exact codes
should first `go build -o quizctl ./next/server/cmd/quizctl`. Diff validates both
inputs and prints only quiz/question IDs and revisions/bundle hashes. It never
prints answer keys, accepted variants or prose. Publication-only metadata changes
appear as a bundle revision change.

## Mapping and integrity

Legacy ASCII IDs are lowercased, runs outside `[a-z0-9-]` become `-`, and outer
hyphens are trimmed. Short and digit-leading IDs receive `id-`. The result must
match `[a-z][a-z0-9-]{2,63}`; unmappable and overlong IDs fail without truncation.
Two different source question IDs mapping to the same ID are fatal. Option IDs
are `<question-id>-opt-<1-based-position>` (or `opt-<position>` when the 64-character
limit requires it); uniqueness is scoped to a question, as in the contract.
The manifest maps every source quiz/question/zero-based option index and records
the SHA-256 of the exact source bytes. Relative input paths remain relative,
normalized to `/`; use the documented source spelling for byte reproducibility.

`correct_answer` is always required and bounds-checked, including multiple choice.
Missing/null/empty `correct_multi` remains single choice. Nonempty multi requires
at least two unique integer indexes, includes `correct_answer`, and is stored in
source-option order. Difficulty is unknown when absent/null; 1–3 easy, 4–7 medium,
8–10 hard; all other values fail. No numeric coercion or inferred category occurs.

The maintained `jsonschema/v6 v6.0.1` validates Draft 2020-12 including date-time
format; cross-record checks additionally enforce unique IDs, grading-kind and
reference alignment, coverage, normalization uniqueness and recomputed hashes.
Revisions identify **private draft content**. Each question hash omits only its
own `revision`; the draft hash omits only its own `revision` and includes question
revisions. Public bundle revisions retain those identities. Bundle validation
reconstructs the private draft before recomputing them; the bundle SHA omits only
`bundle_sha256`. `build` rejects stale revisions; it never repairs them silently.
The library's explicit `Rehash` supports deliberate edits before validation.

Canonical JSON sorts object keys, keeps array order, uses compact UTF-8 and does
not escape Unicode/HTML. Integer contract fields use normal decimal JSON. File
bytes add one LF; hashes exclude that LF. Version/time are always caller supplied.
Full Unicode NFC/casefold uses the already pinned `x/text v0.34.0`, with a tested
Cherokee uppercase correction for that version. Whitespace matches P04/Python
`split`, including U+001C–U+001F; vectors are under the content testdata directory.

Writes stage and sync temporary siblings, then atomically publish each file;
Windows uses a no-replace move unless forced, POSIX uses a no-replace hard link
or forced rename. The pair is preflighted together and ordinary commit failures
are rolled back. A crash between file publications can leave a mixed pair; this
is not a multi-file database transaction. Keep the manifest and validate its
source hash/mappings with the provided evidence verifier after interrupted work.

Run `go test ./next/server/internal/content ./next/server/cmd/quizctl` for the
golden, negative, conformance, real-pack and actual-executable end-to-end tests.
