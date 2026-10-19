# Country atlas — quiz_master-53w8

The country entry in Quizipedia now opens an atlas with search, region filtering, a topic picker, country facts and local unranked practice. Existing geographic geometry/hit-testing is reused. Country borders keep a thin screen width at every zoom. The camera supports pinch, trackpad zoom, focal double-tap, animated center zoom, reset and country focus, up to 16×.

Practice topics: location, capitals, curated official languages, currencies, flags, population bands, area bands, region, land neighbors, major water bodies, dated presidents, natural resources, deserts, wonders, landmarks, bridges, scientist birthplaces, UNESCO food traditions and sports clubs. Mixed rounds balance topic types. Users can train a selected country or all countries, check an answer, see the correction/source, and repeat actual mistakes.

## Snapshot and coverage

- 250 country/territory fact records; 177 existing map outlines. Facts-only entities remain searchable.
- 216 World Bank population values for 2024; population questions use bands and carry the year.
- Official-language practice is limited to 19 curated country records. Source languages are separately labelled; absence of a curated record does not mean that a country has no official language.
- 659 directed border associations, including reviewed overseas/Hans Island exceptions. Source ISO3 border codes are converted to the app's ISO2 IDs.
- 391 major-water relations across 213 country/territory records, with coastal/internal/shared-lake/river relationships.
- 1,105 linked facts across 192 countries/territories: 1,055 resource entries, 9 desert relations, 8 wonders, 6 landmarks, 4 bridges, 4 scientist birthplaces, 11 UNESCO food relations and 8 sports clubs.
- 12 president records checked against official sources on 2026-10-19. These are dated snapshots, not an automatically updated feed.
- 250 offline PNG flags. No new package dependency.

Lists are intentionally source-bounded; the product does not claim exhaustive knowledge of every body of water, resource, cultural association or president. Expand reviewed coverage in `quiz_master-0tae`. Each linked fact has its reference, and licenses/attribution ship in `COUNTRY_DATA_LICENSES.txt` beside the assets.

## Verification

Working checkout: `E:/Projects/quiz_master/next/apps/quiz_app`.

- `flutter test --no-pub --reporter expanded`: **142 passed** (full package suite).
- `flutter analyze --no-pub`: **No issues found**.
- `python docs/rewrite-agents/tasks/ATLAS_53W8/test_assets.py`: **5 passed**.
- Web release build: `flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run`; see build evidence.
- Widget checks cover narrow/scaled layouts, correction/retry navigation, load failures, multiple valid languages, same-kind relation distractors, actual snapshot data, thin zoomed borders, double-tap focus and pinch without accidental selection.
- Browser evidence includes mobile atlas/country details, a sports question and correction. Release preview is local; no production deployment is implied.
- Physical Android touch/device and signed Android release were not verified.

The shared checkout contained unrelated dirty changes before work. They must be preserved. In particular, the existing `DiscoveryPage` assertion change in `quizipedia_test.dart` belongs to another task and is excluded from this task's staged version. Beads export also contains other sessions' work; only the three task-owned issue records should enter this integration commit.

Independent code review: `codex-review.md`. Independent factual review: `fact-review.md`. The different-provider review remains explicitly unverified (`quiz_master-xm73`), because vendor tools could not produce a report.

## Data regeneration

`country_facts.json` records its upstream country-data and World Bank URLs. `correct_country_facts.py` applies the documented source-format, language, currency, capital and border corrections. `build_geography.py` rebuilds major geography/resources from the CIA Factbook mirror; run `add_curated_links.py` afterwards to restore the reviewed cultural/sports additions. `fetch_flags.py` caches FlagCDN PNGs. `test_assets.py` checks source references, country IDs, representative water relations, topic pools and offline flag completeness.
