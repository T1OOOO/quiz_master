# Quizipedia v1 independent code review

Reviewer label: `review-quizipedia-code-1x6`
Review base: `e802ed21db936bdb9809bab2d137903eb0aa425e`
Reviewed working-tree snapshot: 2026-10-05

## Verdict

**Requirements compliance: REWORK.** The renderer and integration source satisfy the examined local-unranked, answer-secrecy, four-game, asset-error, and route/drawer requirements on static inspection, but the currently bundled catalog is stale after the accepted taxonomy amendment and its deterministic data check now fails. Required renderer acceptance coverage is also missing for real transformed map interaction and correct scoring.

**Code quality: ACCEPT with the required verification additions below.** The standalone library keeps Quizipedia out of ranked API/attempt code; its catalog parser validates references and numeric bounds; country containment handles multipart polygons and holes; local session submission blocks double scoring; and map/body selection requires Check. The root integration is narrowly scoped to the import, `/quizipedia` route, localized drawer item, and asset directory declaration.

## Required items

1. **Regenerate the catalog and both manifests after the metadata amendment.** `catalog.json` embeds `taxonomy_ref.taxonomy_sha256 = 2ff002603ad7794957962c89c9ccd32a5ddb7a43c72b0b17ae3d6c5e50ae6bf1`, while `metadata/tags.v1.json` now declares `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11` and 403 tags. Consequently `python quizipedia/test_catalog.py` fails in `test_build_is_deterministic_and_matches_bundled_bytes`: the newly built bytes contain the new taxonomy hash and do not equal the bundled catalog. Rerun the builder, verify the copied catalog/manifest hashes, then rerun the data test. This is an integration/data refresh, not a renderer defect.

2. **Add a widget test for the production map after an `InteractiveViewer` zoom/pan transform.** [quizipedia_test.dart](../../../next/apps/quiz_app/test/quizipedia_test.dart) lines 49-56 tests only `scenePoint`, but production map input at [quizipedia.dart](../../../next/apps/quiz_app/lib/quizipedia.dart) lines 1265-1280 does not call that helper; it relies on child-local gesture coordinates. The required transform behavior is therefore not demonstrated by the test suite. Exercise a transformed gesture against a known real polygon/hole and assert the selected country, including an ocean tap clearing the tentative selection.

3. **Add a direct correct-score assertion.** The session unit test at [quizipedia_test.dart](../../../next/apps/quiz_app/test/quizipedia_test.dart) lines 61-81 submits only `'wrong'` before attempting a deliberately ignored second submission, so it proves score remains zero and blocks double submission but not the correct-answer increment. Assert one correct selection increments score exactly once; retain the wrong, repeat-submit, and restart cases.

## Evidence and limits

- Light data check before metadata amendment: `python quizipedia/test_catalog.py` — 5 passed. Current check after the amendment: 4 passed, 1 failed solely on the stale taxonomy reference described above.
- Flutter test/analyze/build and device/web runtime checks are **NOT_RUN**: no host resource lease was granted. No runtime-pass claim is made.
- Reviewed renderer SHA-256: `763a36ad6da44fcb393fe40f8948a342378c7c45a3db34dfdf922b6c15be8d7f`; tests: `52c1899280ed6d26ceac474e6e05ea721836f085cb2ce8e1f58209c165047ebe`; bundled catalog: `3799945addf40643c4a8fed9aebe09d142e3df4bb2656b1cfffe1a92d6814460`; both manifests: `36585892c3f8d1b26f50b66870d4fbeb8fb44b314c1a0868034d5f3b37233355`.
- Catalog inventory inspected: 177 Natural Earth background features and 20 bound map targets, plus 6 anatomy, 6 landmark, and 8 constellation targets. The factual/image review acceptance in `review-facts.md` was deliberately not repeated.
- The 177-feature 1:110m source coverage and its stated small-island limitation remain a product/asset-scope risk to be accepted separately; it is not an assertion that the factual gate failed.
