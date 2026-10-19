# Independent Code Re-Review: `minimum20` Change Set (Scoped Source)

- **Overall Verdict**: **ACCEPT** (scoped source review; excludes pending full Go/Flutter test completion and Linux candidate runtime/article verification)
- **Stage 1 — Requirements Compliance Verdict**: **ACCEPT**
- **Stage 2 — Code Quality Verdict**: **ACCEPT**

---

## Verification of Resolved Findings

1. **Legacy Alias Deep Links, Active Canonical ID & Discovery Inventory (Resolved)**
   - [`legacyPlayableQuizAliases`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey.dart#L19-L76) and [`playableQuizId`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey.dart#L78-L79) match all 56 source-to-target mappings in [`content.RoundAliases`](file:///E:/Projects/quiz_master/next/server/internal/content/round_aliases_generated.go#L4-L61) (including `'gastronomy-cheeses-and-dairy': 'gastronomy-animal-products'`, `'theme-pixar': 'animation-studios-pixar-dreamworks'`, `'theme-game-of-thrones': 'theme-tv-series'`, `'theme-star-wars': 'cinema-science-fiction-worlds'`, `'music-encore-20261011': 'music-people-20261011'`, and `'lotr': 'lotr-trilogy'`).
   - [`JourneyController.openQuiz`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey.dart#L224-L250) resolves `final canonicalId = playableQuizId(id)` and assigns `_quizId = canonicalId` before calling `api.catalog(quizId: canonicalId, difficulty: difficulty)`, `startAttempt`, and `feedback`, while preserving the strict `catalog.quiz.id != canonicalId` guard against arbitrary server quiz ID mismatches.
   - [`_CatalogPageState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey_pages.dart#L46-L63) computes `activeQuizId = catalog?.quiz.id ?? (widget.quizId == null ? null : playableQuizId(widget.quizId!))` and uses it for pack metadata lookup ([`journey_pages.dart:58,140`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey_pages.dart#L58)) and next-round navigation ([`journey_pages.dart:244-248`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey_pages.dart#L244-L248)), while [`ExplanationPanel`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/main.dart#L733-L741) passes `reveal.quizId` and `reveal.revision!.sha256` to [`QuestionArticleLink`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/question_articles.dart#L135-L172) (preserving historical attempt source identity when viewing stored source reveals).
   - [`_DiscoveryPageState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/discovery.dart#L206-L223) filters `packs.where((pack) => pack.questions >= 20)` when computing both parameters of `l10n.catalogInventory`.
   - [`feedback43_alias_test.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/feedback43_alias_test.dart#L60-L85) verifies both canonical practice feedback via `'lotr'` → `'lotr-trilogy'` and fail-closed rejection (`'invalid_response'`) on `'unknown-server-id'`.

2. **`quizctl catalog` Alias Validation & Minimum-20 Filtering (Resolved)**
   - [`catalogPlayablePacks`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/main.go#L243-L266) validates all aliases whose source exists in `known` (rejecting empty IDs, `source == target`, `!known[target]`, and `aliases[target] != ""`) while ignoring aliases absent from partial fixtures, and exports only unaliased packs with `pack.Questions >= attempts.MinimumAttemptQuestions`.
   - [`catalog_aliases_test.go`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/catalog_aliases_test.go#L9-L44) covers legacy alias omission, `<20` exclusion, missing target, self-alias, alias chain rejection, and unrelated fixture aliases.

3. **`catalog_test.go` Corpus Totals & Derived Target Assertions (Resolved)**
   - [`TestCatalogExportsWholeCorpusAsMetadataOnly`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/catalog_test.go#L30-L78) asserts `len(packs) == 105`, `total == 4520`, presence of the derived pools (`gastronomy-animal-products`, `cinema-people-20261011`, `music-people-20261011`, `cinema-science-fiction-worlds`, `theme-harry-potter`, `theme-tv-series`, `animation-studios-pixar-dreamworks`, `theme-game-worlds`), and verifies `!ids[source]` and `ids[target]` across all entries in [`content.RoundAliases`](file:///E:/Projects/quiz_master/next/server/internal/content/round_aliases_generated.go#L4-L61).

4. **Release-70 Candidate Verifier (`rehearse.py`)**
   - [`require_article_bindings`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py#L244-L270) falls back to `/v1/source-catalog?quiz_id=<quiz>` whenever `/v1/catalog` is absent or returns a derived pool whose question revision hash does not match the historical source `revision_sha256`, and still requires an exact `revision_sha256` match on the source catalog across all 241 references.
   - [`new_question_manifest`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py#L203-L227) and [`require_new_question_grading`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py#L229-L242) verify source/draft/acceptance SHA-256 receipts and grade all 38 newly imported questions (both positive and negative paths, receipts, and finish history) without exposing private keys in public DTOs.

---

## Certified Review Scope & Boundaries

- **Directly Inspected in This Re-Review**:
  - [`next/apps/quiz_app/lib/journey.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey.dart)
  - [`next/apps/quiz_app/lib/journey_pages.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/journey_pages.dart)
  - [`next/apps/quiz_app/lib/discovery.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/discovery.dart)
  - [`next/apps/quiz_app/lib/main.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/main.dart)
  - [`next/apps/quiz_app/test/feedback43_alias_test.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/feedback43_alias_test.dart)
  - [`next/server/cmd/quizctl/main.go`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/main.go)
  - [`next/server/cmd/quizctl/catalog_aliases_test.go`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/catalog_aliases_test.go)
  - [`next/server/cmd/quizctl/catalog_test.go`](file:///E:/Projects/quiz_master/next/server/cmd/quizctl/catalog_test.go)
  - [`next/server/internal/content/round_aliases_generated.go`](file:///E:/Projects/quiz_master/next/server/internal/content/round_aliases_generated.go)
  - [`docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py)
  - Together with the previously inspected backend (`next/server/internal/{attempts,sqlite,httpapi,content}`, `next/server/tools/minimum20-bindings/main.go`), study article overlay (`study/question_articles/{build.py,test_minimum20_bindings.py,bindings/minimum20.json}`), and materializer/importer scripts (`materialize_pools.py`, `import_accepted20.py`, `import_accepted18.py`).
- **Explicitly Outside This Static Source Certification**:
  - Live test execution / runtime deployment proof (pending full Go test completion with expanded 20-question difficulty fixtures, full Flutter test rerun, and Linux candidate verification of all 241 article references).
