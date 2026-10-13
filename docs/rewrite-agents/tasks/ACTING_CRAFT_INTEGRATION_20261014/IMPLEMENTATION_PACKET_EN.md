# Acting Craft8 local integration packet

## Scope and accepted inputs

This packet covers only the new local pack `acting-craft-20261014`, its canonical
draft/bundle/manifest triplet, and its eight draft Reader articles. It does not
export Reader assets, change the catalog or cache, build the client, deploy, or
claim publication.

The imported inputs are the accepted current pilot files, not the rejected v1–v3
snapshots:

- `candidate.json`: `69f73ac2e685c1c3068e1f3fad85196c0f17b56fcde6df93cd3265cf020ff554`
- `editorial.json`: `8642add1d5868c93f69504be9915dae21bb8c4266da23194c8078cb3220479e3`
- `independent-review-v4.json`: `708c8c80f3c292b7c4ad43c9203981351bb626414590de955c52c961db1ee073`

The review record reports `actual_hub_state: ACCEPTED`. All eight source stems,
four-option arrays, zero-based answer positions, editorial explanations, article
prose, and source records were checked against those inputs by the bounded verifier.
Correct option positions are `0,1,2,3,0,1,2,3`.

## Metadata handling

Each question uses the registered taxonomy IDs `domain:arts`, `domain:screen`,
and the lead-authorized, registered, player-safe `topic:actors`. This is a
metadata-only derivation; no accepted fact, choice, key, explanation, article, or
source was changed. The unregistered editorial tags `craft:makeup`,
`craft:rehearsal`, and `craft:movement` were not propagated. In particular,
`craft:makeup` was stale for the revised rehearsal question.

## Actual commands and outcomes

All commands ran from `C:\ap\quiz_master`.

1. `python .run\acting_craft_integration_20261014\integrate_assets.py prepare` — exit 0.
2. `go run -p=1 ./next/server/cmd/quizctl import --in quizzes/Cinema/acting_craft_20261014.json --out next/content/acting-craft-20261014 --taxonomy metadata/tags.v1.json` — exit 0; imported 8 questions.
3. `python .run\acting_craft_integration_20261014\integrate_assets.py normalize` — exit 0; changed only the canonical draft source URI to `/app/quizzes/Cinema/acting_craft_20261014.json` and recomputed revisions.
4. `go run -p=1 ./next/server/cmd/quizctl validate --in next/content/acting-craft-20261014/draft.json --taxonomy metadata/tags.v1.json` — exit 0; 8 questions.
5. `go run -p=1 ./next/server/cmd/quizctl build --in next/content/acting-craft-20261014/draft.json --out next/content/acting-craft-20261014/bundle.json --version 2026.10.14.acting-craft-v1 --published-at 2026-10-14T00:00:00Z --taxonomy metadata/tags.v1.json` — exit 0; bundle SHA `af99508914afa77ac47861015dd5fb53ac0581f04a390698f174b43a87f89060`.
6. `go run -p=1 ./next/server/cmd/quizctl validate --in next/content/acting-craft-20261014/bundle.json --taxonomy metadata/tags.v1.json` — exit 0; 8 questions.
7. A fresh deterministic `quizctl build` to `rebuilt-bundle.json`, followed by `quizctl diff --before ...bundle.json --after ...rebuilt-bundle.json` — both exit 0; diff reported `no changes`.
8. `python .run\acting_craft_integration_20261014\verify_integration.py` — exit 0. It verifies exact candidate/editorial parity, source explanations, canonical runtime URI, private grading to the exact option ID, absence of grading and editorial tags in public bundle questions, eight revision-bound articles, and sixteen exact descriptive source links.

The first import attempt was rejected with `taxonomy_reference` because the new
raw source lacked the required `taxonomy_ref`. The working Music Craft raw source
and importer showed the cause. The only repair added the existing
`metadata/tags.v1.json` reference; the successful import above is the final
recorded import.

## Frozen artifacts

- Raw: `quizzes/Cinema/acting_craft_20261014.json` —
  `a3fa877452956691f048d1cd129756a64a6e94de23a09d7752680c6a4ed11963`
- Draft: `next/content/acting-craft-20261014/draft.json` —
  `431384f39ef4251f1c152b18b3e91d10bf084e7ad39ec2a9b7a232909e96969e`
- Bundle: `next/content/acting-craft-20261014/bundle.json` —
  `0378dfb462aee36b31d0026381e5d804c1fda410da5166a571150c13c480b3ee`
- Manifest: `next/content/acting-craft-20261014/manifest.json` —
  `e0f79300cb149778f81678d391785c30b41f6a86e26309e34b6b2570aef77c62`
- Reader draft: `study/question_articles/drafts/acting-craft-20261014.json` —
  `dc949de1780840797e22ff3a9ac4cc2e575c611dc821775dbd445a9ac321492f`

The manifest source hash is the importer-defined line-ending-normalized raw
source hash `5df21fce18ef2710d5b821eeb0a3ad3ca7d854146b0cccf479cdcaca688f8013`.
`integration-evidence.json` carries the full per-question revision map and the
canonical JSON SHA-256 of each Reader article:

| Article ID | Canonical JSON SHA-256 |
| --- | --- |
| question:acting-craft-pilot-001 | 886ded886f21a10056c24645ef14b22de095f6680fedcf89242c4f9f7a7222ad |
| question:acting-craft-pilot-002 | 256cbe16bd4c987e3e30aaaac33db8957ebd5d3066c57f9767fcd4c2a0476279 |
| question:acting-craft-pilot-003 | 479780f569e75707460cb1f699a276591470aa75fb8fdc3ce682c87eee350230 |
| question:acting-craft-pilot-004 | 32a6edd125b796dffe90131e019adfb530e8506d473f544327cbeca3b975e270 |
| question:acting-craft-pilot-005 | 3c9675868d9a88dd0c30b6f4ea4f61c32eecfacd66b773768f162f1d1f34272b |
| question:acting-craft-pilot-006 | 5d34fc0aee263723bd5a262dade267ed10a85e2b52be0b9db085c3365ee36a85 |
| question:acting-craft-pilot-007 | d4b4d87086992a1706a01d840c613b77c95a8ae1eb7d1c88dd2ba25c29cbaf0a |
| question:acting-craft-pilot-008 | 580f2a50d6e83bae36dd60e68222b59afd0551e154cb180650b8bc98bb80c37b |

## Limits and remaining gate

At verification time, published assets still contained 133 packs, 4052 questions,
and 252 Reader articles. This task performed no catalog or Reader export mutation.
The frozen local artifacts require a different-provider integration review before
the lead exports them or performs cache, application-build, release, or publication
work.
