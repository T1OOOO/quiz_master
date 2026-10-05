# difficulty-content-20261005 implementation handoff

Status: READY FOR REVIEW (not accepted, committed, published, or deployed).

## Scope delivered

- `next/server/internal/content/**`: optional exact `difficulty_level`, four bands
  (1–3 Easy, 4–6 Medium, 7–8 Hard, 9–10 Nightmare), optional taxonomy reference,
  private editorial tags, safe public context tags, deterministic taxonomy loading
  and validation, plus legacy archive compatibility.
- `next/contracts/quiz-contract/v1/**`: closed draft, public-question and bundle
  schemas now carry the v1 metadata projection; private bundle tag metadata remains
  outside public questions. Contract checker/summary document the new shape.
- `next/server/internal/sqlite/**` and `httpapi/**`: exact lower-case difficulty
  filter on catalog/start requests; omitted round starts all matches, explicit
  zero-based round filters before the existing 20-question partition; valid empty
  band returns `422 no_match`. Catalog includes all four zero-capable band counts.
- `next/server/cmd/quizctl/**` accepts explicit `--taxonomy`; server configuration
  accepts `QM_CONTENT_TAXONOMY_PATH` with `metadata/tags.v1.json` default. Old
  stored bundles do not require a live dictionary during replay.

## Changed/new files

`next/contracts/quiz-contract/v1/{README.md,check_contract.py,summary.json,schemas/draft-quiz.schema.json,schemas/public-question.schema.json,schemas/published-bundle.schema.json,schemas/error-envelope.schema.json}`;
`next/server/{cmd/api/main.go,cmd/quizctl/main.go,internal/attempts/{rules.go,service.go},internal/config/config.go,internal/content/{types.go,import.go,validate.go,taxonomy.go,content_test.go,conformance_test.go,realpack_test.go,difficulty_tags_test.go},internal/httpapi/{attempts.go,selection_test.go},internal/sqlite/{attempts.go,collection.go,collection_test.go,difficulty_rounds_test.go}`.

Contract summary content hash: `8bb47ad26c94bade21146b318dea66544412fdebb67dde31612f1d3c995685e5`.
The frozen taxonomy semantic SHA was independently recomputed from UTF-8,
sorted-key, compact JSON (without `taxonomy_sha256`) and matched
`2ff002603ad7794957962c89c9ccd32a5ddb7a43c72b0b17ae3d6c5e50ae6bf1`.
Selected file SHA-256 values: `taxonomy.go`
`13A2EDF62C78506F7303895183041350945367EF5D5D13FEB47CEE47FA79F5CC`,
`difficulty_tags_test.go`
`C8930B5D44914F1519AE18B9372FE19772ECBA88FB7169F368E9C2C617CBCCCC`,
`difficulty_rounds_test.go`
`9482FFFBDE98A0FEA189300DDEF7F9D6198C6A047B1322C1D3FBC06F9D85D5C2`,
and `summary.json`
`66C42EBFDDF0CA5A5D974448BCB38BFADFF73D7D75652A661320C0C28B47BE92`.

## Checks

- `python -B next/contracts/quiz-contract/v1/check_contract.py --write-summary`:
  PASS; 39 named negative fixtures rejected and updated summary written.
- PowerShell `ConvertFrom-Json` over all four changed JSON schemas: PASS.
- `gofmt` over every changed Go source/test: PASS.
- `git diff --check -- next/server next/contracts/quiz-contract/v1`: PASS.

## Limitation / remaining integration risk

No Go test binary was executed. The task packet identifies Windows test binaries as
group-policy blocked, and root had no lawful build/test lease. A compile-only
attempt was rejected by host policy before execution. Run focused content/sqlite/
http API tests and the full Go suite on the granted Linux runner after root merges
the source annotations; the live collection test now expects the frozen 126 packs
and 3,958 quiz questions. Review the taxonomy loader against the final dictionary
and source annotations together, then validate a historical partially answered
attempt against an old stored bundle.
