# Quizipedia integration-delta review

**Reviewer label:** `review-integration-delta-quizipedia-20261005`
**Source revision:** `e802ed21db936bdb9809bab2d137903eb0aa425e`
**Reviewed staged snapshot:** 2026-10-05

## Verdicts

**Requirements compliance: REWORK.** The integration/test/CI delta is otherwise
sound, but the staged `quizipedia/images-manifest.json` does not yet preserve
the reviewed worktree bytes under the newly added raw-byte attributes.

**Code quality: ACCEPT after that staging correction, with runtime still
unverified.** The web build's `QM_API_BASE_URL=https://quiz.kotopedia.org`
matches the existing `String.fromEnvironment` API client setting. The manual
workflow trigger is valid. `-text` applies to direct Quizipedia JSON, source
files, and bundled assets. The route test creates the real app inside
`runAsync`, waits for the actual `FutureBuilder<QuizipediaCatalog>.future`,
and limits its discovery override to the library-navigation fixture.

## Required correction

1. **Re-add `quizipedia/images-manifest.json` after `.gitattributes` is in
   effect, then recheck the staged blob.** The worktree blob is
   `9e16f984f88c0fa1adcbbce52db7d745db42d7bb`, while the index blob is
   `67d662ef9a827f81a90702af7f753cf6f44b2e72`. This is the only mismatch
   among the checked hash-sensitive files. The worktree SHA-256 remains the
   fact-review value `39e2f7987bb6b7fb005ca58d553b33748b184e54aa4cf0bd83705d8553c2b38d`.
   The index appears to retain the earlier normalized representation. Re-stage
   the file and verify its blob equals the worktree's raw blob before the
   draft commit.

## Evidence and limits

* `git diff --cached --check`: pass.
* `git check-attr -a` confirms `-text` for
  `quizipedia/content.json`, `quizipedia/sources/world-source.json`, and
  `next/apps/quiz_app/assets/quizipedia/catalog.json`; the first two also have
  `whitespace=cr-at-eol`.
* Raw worktree/index blob audit matched all other checked inputs: content,
  hotspots, both generated manifests, both source JSON files, endocrine SVG,
  and bundled catalog.
* Current repaired route-test source SHA-256:
  `880e083680b985def4328ee844ba8232358a2500b0f5a8ce5724cbd35c316441`.
  It was not executed after its repair. No Flutter/analyze/build/CI pass is
  claimed here.

## Re-review after staging correction

**Final integration-delta verdict: ACCEPT, with runtime gates pending.** The
required re-add was performed. The index and worktree now have identical raw
blobs for `quizipedia/images-manifest.json` (`9e16f984f88c0fa1adcbbce52db7d745db42d7bb`),
and for every other independently checked hash-sensitive input: direct source
JSON, hotspot/content/manifests, both acquired source JSON files, endocrine
SVG, and bundled catalog/manifest (`0` mismatches). The image manifest's
worktree SHA-256 remains the reviewed
`39e2f7987bb6b7fb005ca58d553b33748b184e54aa4cf0bd83705d8553c2b38d`.
`git diff --cached --check` passes. This supersedes the required correction
above; it does not change the pending Flutter/CI runtime limitation.

## CI-repair delta re-review

**ACCEPT.** The index contains exactly two relevant repair files:
`next/server/internal/sqlite/collection_test.go` replaces only the three stale
source-collection expectations (`118/3878/118` to `126/3958/126`), and
`next/apps/quiz_app/lib/main.dart` adds only the required blank line before the
local Quizipedia import. The staged import block has the same 659 lines as the
previously formatted isolated game source and no textual difference. Cached
whitespace validation passes. This evaluates the reported CI failure repair;
the corrected test and CI workflow have not been rerun, so no runtime-pass
claim is made.

## Compose, real-I/O route, and release-helper delta

**ACCEPT for the reviewed changed scope.** The Compose environment supplies
absolute bundle and manifest paths required by the nonlocal API listener. The
runtime Docker image copies precisely that legacy controlled bundle and the
validation schemas, then uses `/app`, so the configured relative schema path
resolves. The bundled Home Alone document has no taxonomy annotations, so its
legacy controlled-bundle startup does not require the absent taxonomy file.

The second drawer-open repair creates the route inside `runAsync`, pumps the
Go Router transition twice, and awaits the actual catalogue future. Root
evidence in `INTEGRATION.md` records a narrow route pass and an isolated
client `flutter test` pass of all 83 tests under released lease
`lease-bdf4f6f7dd764cdf8f8e7fcdd542d9d1`; formatter also passed with zero
changes. The review did not run those commands.

The text-only release helper verifies CI Web checksums before packaging,
copies the immutable baseline API/content, validates the preserved catalog and
all bundled Quizipedia asset bytes, and creates a new build guard for the old
baseline image. It does not make a production change. The current Compose,
Dockerfile, and route-test source pass whitespace validation on static review.
Remote Compose integration and CI Web compilation remain pending and are not
accepted by this finding.

## CI migration-order delta

**ACCEPT for static CI ordering; fresh remote proof remains pending.** The
workflow now starts only `postgres` before the integration packages run. This
preserves `runner_integration_test.go`'s required sequence: apply migrations
1--2, insert a legacy pre-manifest bundle, then apply migration 3. `-p 1`
also prevents the identity and store integration packages from sharing and
truncating that database concurrently. Only after that suite does the workflow
build and wait for the API, then probe its live and ready endpoints.

The diff does not alter migration guards, backend code, test fixtures, or API
health assertions. The reported prior run had already passed Go unit/vet and
the API health path, while failing the migration fixture because the API had
pre-applied migration 3. This is a targeted correction of that test ordering.
I did not execute a remote run, so this is not evidence of a fresh CI pass.
