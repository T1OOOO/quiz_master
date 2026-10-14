# LOTR rk93/rk95 canonical integration proof — 2026-10-14

## Scope and exception

This is a two-item canonical candidate only. It incorporates the accepted V3 wording/source pilot for `lotr_rk_93` and `lotr_rk_95`; `rk96` was not changed. The sole whole-pack metadata exception authorized by Root is the frozen taxonomy reference:

```json
{"taxonomy_id":"qm-tags-v1","taxonomy_sha256":"07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151"}
```

`metadata/tags.v1.json` was loaded by the actual Go content implementation and returned that identity. It makes the two items' sorted registered `editorial_tag_ids` and player-safe `context_tag_ids` valid. Source title, category, description, source ID, locale, and the other 98 local-source question records were retained. This does not equate local-source hashes with the currently served `/app` runtime hashes.

## Canonical candidate

The changed production-scope files are:

- `quizzes/Cinema/LOTR/lotr_return_king_bts_100.json`
- `next/content/lotr-return-king-bts-100/draft.json`
- `next/content/lotr-return-king-bts-100/manifest.json`
- `next/content/lotr-return-king-bts-100/bundle.json`

The local candidate bundle is explicitly versioned `lotr-wording-pilot-2026.10.14-v3` at the frozen candidate timestamp `2026-10-14T06:12:00Z`, with bundle SHA-256 `07c988b847447ab3402653283c2f462aa9b80f21de21bcc58408b67960d73ad7`.

| Question | Canonical local revision | Correct option | Stable options |
| --- | --- | --- | --- |
| `lotr-rk-93` | `2:dc3c5b2b3b119a472993d32ae4c0321eea64532904956dad26075507cd362fa7` | `lotr-rk-93-opt-6` | `opt-1` … `opt-6` |
| `lotr-rk-95` | `2:a359dc8245a34bbafbf4c21b8fa096f13a49597196bee92885026e973d0f948e` | `lotr-rk-95-opt-2` | `opt-1`, `opt-2`, `opt-3`, `opt-5` |

For rk95, the manifest maps raw indices `0,1,2,3` to canonical IDs `opt-1,opt-2,opt-3,opt-5`. The old `opt-4` (Tirion) and `opt-6` (Lindon) are absent. The nonzero raw key remains index `1` and the private key remains `opt-2`.

Current full-file SHA-256 values:

```text
raw      41d17284e4c947a3fa0b4dde2ee72cacdd7552789cb6c51951c96cf4b86e3877
draft    1a5934780727b92bdb524c37137f819be53e7e948be0bdb5bba44c8f346741d7
manifest d563a5bb7b01f6a0337d2742c165b0510db0a15b4f457b8da237f770106e65b1
bundle   0493caf17023d7e470f8c28b8dbb782ba0309c5d21141dffff8dd9c16ff190b2
```

`content.Rehash` was called through `next/server/.run/lotr_update_canonical.go` and independently re-read through `lotr_rehash.go`; it reported the two question hashes above and draft revision `1:f0b8ad57df6ebd4a5758b2d82d82a587cb56e493dcc9ce63a4570a9f06b1748e`.

## Preservation and checks

The frozen pre-edit bundle is retained only in ignored `next/server/.run/lotr_return_king_bts_100.before.bundle.json`. Comparing it with the candidate proved 100 questions, 98 byte-equivalent public question objects outside rk93/rk95, and no changed non-target private-grading record. `quizctl diff` returned exactly rk93, rk95, the expected whole-quiz revision hash, and the expected bundle hash; its difference exit is `1` by contract.

Successful commands (all run from `C:\ap\quiz_master` unless noted):

```text
go run .\next\server\cmd\quizctl validate --taxonomy .\metadata\tags.v1.json --in .\next\content\lotr-return-king-bts-100\draft.json                         exit 0
go run .\next\server\cmd\quizctl build --taxonomy .\metadata\tags.v1.json --in .\next\content\lotr-return-king-bts-100\draft.json --out .\next\content\lotr-return-king-bts-100\bundle.json --force --version lotr-wording-pilot-2026.10.14-v3 --published-at 2026-10-14T06:12:00Z  exit 0
go run .\next\server\cmd\quizctl validate --taxonomy .\metadata\tags.v1.json --in .\next\content\lotr-return-king-bts-100\bundle.json                         exit 0
go run .\next\server\cmd\quizctl import --taxonomy .\metadata\tags.v1.json --in .\quizzes\Cinema\LOTR\lotr_return_king_bts_100.json --out .\next\server\.run\lotr-import-check --force       exit 0
go test ./internal/content                                                                                                                                    exit 0
go test ./cmd/quizctl -run 'TestSourceCorpusHasDistinctAnswerLabels|TestAuditReportsEveryFileWithoutPublishing|TestAuditRejectsEmptyOrMissingDirectory|TestCLIEndToEnd|TestAuditAndCatalogHonorExplicitFrozenTaxonomy'  exit 0
```

The frozen-timestamp explicit build command was repeated to ignored `next/server/.run/lotr-rebuild.bundle.json`; its full-file SHA-256 was byte-identical to the candidate bundle (`0493caf17023d7e470f8c28b8dbb782ba0309c5d21141dffff8dd9c16ff190b2`).

The timestamp-only rework reran the local and runtime `quizctl build` commands with `--published-at 2026-10-14T06:12:00Z` (each exit 0), then validated both rebuilt bundles with the frozen taxonomy (each exit 0). The actual Go runtime projection helper reran successfully and matched 98 unchanged public questions with zero mismatches; the local old/new comparison found 100 questions in each bundle, 98 unchanged non-target public objects, and zero changed non-target IDs. `quizctl diff --before next/server/.run/lotr_return_king_bts_100.before.bundle.json --after next/content/lotr-return-king-bts-100/bundle.json` returned exit 1 as expected and listed only rk93, rk95, the quiz revision, and the bundle revision.

The earlier combined `go test ./internal/content ./cmd/quizctl` run did not pass at `next/server/cmd/quizctl/catalog_test.go:31`: pre-existing `TestCatalogExportsWholeCorpusAsMetadataOnly` expected 131 packs but observed 135. It was not rerun for this timestamp-only rebuild, and no catalog or unrelated content was changed to mask the fixture-count failure.

## Runtime projection for Root's next gate

`integration-runtime-draft.json` and `integration-runtime-bundle.json` are a separate, non-published projection. It changes only every draft question's source URI to `/app/quizzes/Cinema/LOTR/lotr_return_king_bts_100.json`, then calls actual `content.Rehash`; no local canonical source URI was normalized. Semantic canonical comparison against `integration-public-baseline.json` matched all 98 untouched public questions, including their revision hashes.

The runtime-projection bundle validates and is explicitly versioned `lotr-wording-pilot-2026.10.14-v3-runtime-projection`, published-at `2026-10-14T06:12:00Z`, bundle SHA-256 `d0ef1ae3af36b3191d96ea722262a842011c118bd85585d6e3c0af3d920d8278`, and full-file SHA-256 `7f7fcc19aab983691c445771e3dd3833ca2f70c7f280cbb927b2c90e19093c38`.

| Question | Runtime-projection revision for Reader binding |
| --- | --- |
| `lotr-rk-93` | `2:4c90dc9b8f716e6de64e9153694ebb9576a024983cff098f8c16f4d7adf302e4` |
| `lotr-rk-95` | `2:36e5d42e3e8a3f639c9249ede4a04fcb6186fa8e3a826325f4ec4998b20db513` |

No Reader data, application assets, runtime cache, publication, commit, or release action is included in this work.
