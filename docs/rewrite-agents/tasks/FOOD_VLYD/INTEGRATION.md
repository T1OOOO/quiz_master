# FOOD_VLYD integration and verification

User request: famous dishes, classic ingredients, recipes, facts, origins and regional branches.
Initial release: 11 source-linked classic references from eight countries, 12 source records.
Quizipedia menu: Food and regional cuisines / Блюда и кухни мира.

The accepted final candidate was copied byte-for-byte to assets/quizipedia/food_atlas.json.
Final candidate, canonical asset and release asset SHA-256:
D029C30A5D3EB9E65D8EEB821A3C61ACCE14FC7D42C8ED9E29128314567592C7.
Moussaka's summary was harmonized with its selected lamb recipe after the full suite;
five final registry/navigation tests passed afterward. No behavior code changed then.

Features: search dishes/ingredients/countries/regions/variants, category filters, name
ordering, classic reference/yield/quantities/numbered method, qualified origin, facts,
verified variations/related dishes, source links, RU/EN. Local practice offers mixed,
origin and composition topics, four distinct localized choices, frozen ten-question
rounds, explicit check/feedback, source links and finite missed-question review.

Verification:
- Full Flutter suite: 175 passed (flutter-tests.log).
- Focused food UI/model: eight passed (ui-tests.log), including completed rounds,
  original score preservation, data errors/retry and narrow large-text selection.
- Final registry/navigation: five passed (final-registry-tests.log).
- Flutter analyzer: no issues (flutter-analyze.log).
- Release web build passed (web-build.log); existing CupertinoIcons font warning only.
- Actual debug hot reloads succeeded; runtime-errors query returned none.
- Independent code review approves client/model/menu (code-review.md).
- Independent source/recipe review ACCEPT 11/11 (fact-review.md), with prior rejected
  draft and correction history retained. finalize_food.py reproduces final corrections.

Provider-independent gate remains OPEN: managed Claude Sonnet review failed to authenticate
with “OAuth session expired and could not be refreshed”, exit1, task54b1a31,
run-d11b2423b7df40dda1139e3551b58dd9. It produced no actual review. Do not describe
the separate Codex reviews as different-provider approval. quiz_master-ho2r tracks
this gate before main merge/production release; no production deployment performed.

quiz_master-d6zm tracks recipe-level research for further cuisines. The 24-card
candidate is a rejected research draft, never a shipped asset. No logo/dish photos,
physical Android verification or kitchen preparation test is claimed. Source recipes
remain reference versions: family/local traditions differ. A source that omits yield
(e.g. ceviche) is labelled by batch quantity rather than inventing serving counts.

Existing unrelated checkout changes are excluded from these commits.

Release browser verification on port8788, viewport390×844: menu loads11cards,
Moussaka summary shows lamb, origin training accepts Greece and displays source
buttons and feedback. Debug ingredient search гуанчале opens Carbonara detail;
release-mobile.png and practice-release-mobile.png capture final layout.

After the final accepted origin metadata, Russian proofreading corrected only
свежое to свежее in the ceviche ingredient label. Recipe meaning is unchanged.
Final registry/navigation tests and the release build were rerun on this asset.
