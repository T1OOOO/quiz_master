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
