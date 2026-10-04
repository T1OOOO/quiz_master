# Wave 2 integration/code review

Scope: independent read-only review of the imported Wave 2 modules and the
declared integration surfaces. The packet identifies `e7483d9` as the base;
per the assigned no-git scope, this review did not run Git commands. It
examined the current files and the declared scoped diff only. It does not
claim runtime, public, deployment, or release acceptance.

## Requirements compliance — APPROVE, with pending heavy gates

No actionable requirements deviation found in the permitted scope.

### Imported-content parity

For both imported module folders, SHA-256 comparison finds `article.md`,
`image-briefs.json`, `questions.candidate.json`, `questions.key.json`, and
`revision-notes.md` byte-identical to their final independently accepted Wave
2 drafts. Normalizing the only allowed `module.json` changes makes each live
metadata object exactly equal to its draft:

| Module | Allowed live metadata delta | Result |
|---|---|---|
| `nature-evolution` | `status: draft` → `accepted` | exact after normalization |
| `geography-maps` | `status: draft` → `accepted`; add `prep-capitals-world`, `prep-flags-world` to empty `source_quiz_ids` | exact after normalization |

Both added maps references exist in `quizzes/` and each contains 195 questions.
The nonempty maps references are necessary for the pre-existing builder
invariant in `study/build.py`; they do not alter questions, keys, sources, or
article content.

### Builder, reader and native export

- `study/build.py` has the expected six-module set, validates source-quiz IDs,
  retains blind candidate/key boundaries, validates five-per-position answer
  balance, and exports only accepted modules to the Flutter catalog.
- `study/check_reader.py` covers exactly the same six IDs. Its export test
  checks six modules, twenty questions each, article resource paths, sources,
  omitted internal `status`/`html`, unsafe-link/HTML escaping, image paths and
  table rendering.
- I independently compared every current native catalog entry with the live
  source module projection: all six have exact metadata/objectives/source-quiz
  IDs, Markdown image-path rewriting, 20 candidate-plus-key question fields,
  and `{id,title,url}` sources. There are no unexpected catalog IDs.
- The current Flutter test explicitly loads the six expected IDs, requires 20
  questions and nonempty sources per module, and loads each module hero asset.

### Assets and scope boundaries

`study/assets/manifest.json` records both new heroes as generated decorative
art, not evidence. The native copies are byte-identical to their study assets:

| Hero | SHA-256 |
|---|---|
| `nature-evolution-hero.png` | `89ACEE1E376269D721130A85B4556840E5314597F1F2EC77F1C77613548C1241` |
| `geography-maps-hero.png` | `82B95F992FAD2032028F8B7FA4F6AA5EC1863B969AD6AADDDB0DA4A64176FE5A` |

The Flutter path reads the local `assets/study/catalog.json` and presents it as
`StudyPracticePage` self-check (`study-local` and an explicit unranked label);
there is no observed backend/ranked-quiz integration in this path. Correct
answers in this local self-check export are an existing intentional contract,
not a newly exposed ranked/public answer DTO. No dependency addition, server
change, or production deployment action appears in the declared scope.

`deploy/quiz-preview/release-study.sh` is an operational script only. Its
current preflight compares the deployment image to
`docker.io/library/quiz-master@sha256:6fd3e6d90203198b5a03975d9b3b6387821b504ae20a1bf63212ac8afd044b59`;
this review did not execute it or any deployment command.

## Code quality — APPROVE

The integration remains small and uses the existing content-generator pattern:
one authoritative module set, structured validation before export, a focused
reader test, and declared static Flutter assets. Names, boundaries and error
checks are clear. The HTML rendering keeps external links constrained to
`http(s)`/fragment targets and applies escaping plus `noopener noreferrer`;
the native asset boundary is local and fixed-size (6 modules / 120 questions),
with no network, N+1, or new dependency concern observed.

No Critical, Required, Optional, or Nit finding is warranted from the reviewed
scope.

## Verification evidence and remaining gates

The lead supplied fresh successful evidence (not re-run by this read-only
review): seven Python reader checks under normal and `-O` modes; optimized
`study/build.py --check --flutter` for 6 modules / 120 questions; and Dart
formatting. These claims are consistent with the inspected assertions and
generated catalog, but are recorded here as supplied evidence rather than a
second execution.

Flutter full tests, `flutter analyze`, and a Flutter build are **NOT_RUN**:
the required heavy lease was queued and then withdrawn. They remain the only
pending integration gates before any runtime/release conclusion.

## Frozen review hashes

`study/build.py` `AD88F02092873B0F85B3F83F3986DA760F7CAC04AE7B47216851E81B3C7C61F7`  
`study/check_reader.py` `915E8670FDEF226C916D4B8305C39D2F00611FF00B6F5A00EB5809BD0F36D635`  
`next/apps/quiz_app/test/study_test.dart` `68A68F695EA96B7BF4FC932AE15DF6058990D1B293485D505EBEF0EC90A13E7A`  
`next/apps/quiz_app/assets/study/catalog.json` `4652506857C1B581F31D54F61758FD77F5C072D92A3E82D753A7C2899453FDEE`  
`study/assets/manifest.json` `E7A51700EA8D474D81888BF3C5C1640348D89AC3EDDF3C2A86F50191D967F673`  
`deploy/quiz-preview/release-study.sh` `52DBD628348EBCE44C14D943A80A9C43FE2B9468FE5C032C5D6D07D945F4FE06`
