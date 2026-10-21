Historical implementation audit before later mobile fixes. Hash/test references below belong to that earlier snapshot; use README and final closure for the release candidate. None of these rows closes a server feedback item.

# Feedback coverage audit — 2026-10-21

Scope: read-only audit of the frozen `next/apps/quiz_app` source against every item in `docs/rewrite-agents/tasks/FEEDBACK_PLAN_20261021/intake.json`. This is implementation/test evidence, not a publication decision or proof of subjective UX acceptance.

## Snapshot and evidence

- Frozen-file hashes match `.run/feedback_execute_20261021/code-review-closure-final.json`: `quizipedia.dart` `9f4b2dc…fac22`, `country_learning.dart` `41791b…2e05a`, `organ_atlas.dart` `5c3eb1…de8b`, `music_learning.dart` `c0414e…e647e6`, `knowledge_atlas.dart` `d68568…87bcd`, `constellation_atlas.dart` `749967…ffd342`, `animal_atlas.dart` `784cf3…4f62`, and `fact_practice.dart` `329975…4a2ba`.
- Existing final evidence: `.run/feedback_execute_20261021/final-changes-test.log` records **365 passed**; `.run/feedback_execute_20261021/analyze-pass5.log` records `Analyzing quiz_app... No issues found!`.
- Relevant focused coverage includes `feedback_country_test`, `atlas_map_test`, `selected_border_test`, `country_culture_test`, `country_religions_ui_test`, `waterways_ui_test`, `lazy_flag_test`, `organ_atlas_test`, `music_learning_test`, `knowledge_atlas_test`, `constellation_atlas_test`, `animal_atlas_test`, and `fact_practice_models_test`.

Status legend: **covered** has a concrete implementation and test/checked artifact; **partial** has a bounded implementation but an unbounded or subjective part remains; **superseded** means a later feedback item explicitly changed the requested behavior.

| # | Implementation found | What was checked | Residual / honest status |
|---:|---|---|---|
| 68 | Anatomy was separated into scope cards and searchable/filterable catalogues. | `organ_atlas.dart`; organ widget/model tests in final pass. | **Partial**: the original general usability complaint requires user review. |
| 72 | Topic/card entry points and direct controls replace several opaque flows. | Home/route and domain widget tests. | **Partial**: broad subjective complaint cannot be closed by code alone. |
| 73 | Dark graphite/blue Material presentation and image-led cards are present. | Theme/home phone artifacts exist. | **Partial**: visual appeal is subjective; no independent sign-off. |
| 74 | Selected-country outline is painted above shared boundaries. | `selected_border_test`: adjacent-country border stays visible; `atlas_map_test` high-zoom border. | **Covered**. |
| 75 | Same renderer path applies selected outline to every feature. | Same renderer tests, including adjacent border case. | **Covered** for rendering behavior; no exhaustive visual review of every border. |
| 76 | Compact 2:1 map plus explicit expand control, retaining manual transform. | `feedback_country_test`: world aspect ratio and expand preserves phone camera. | **Partial**: useful size is tested, subjective screen-space adequacy still needs phone acceptance. |
| 77 | Selected-country title is localized and the map avoids redundant selection label where inappropriate. | Country map/card tests exercise selection. | **Partial**: no dedicated test proves every duplicate heading is absent. |
| 79 | Later item 103 changed the flag requirement. | Intake plan records 103 as superseding 79–80. | **Superseded**. |
| 80 | Later item 103 changed the flag requirement. | Intake plan records 103 as superseding 79–80. | **Superseded**. |
| 83 | Shared visual treatment was refreshed with dark surface/blue accents and media cards. | Existing home/phone artifacts. | **Partial**: “ugly UI” is subjective and has no acceptance evidence. |
| 84 | Same dark graphite/blue treatment. | Existing theme/widget checks. | **Partial**: palette preference needs user review. |
| 86 | Country controls are direct chips and country access is a labelled entry/search sheet rather than an extra nested menu. | `feedback_country_test` country-picker and direct-layer tests. | **Partial**: complaint names a top scrolling menu generally; no universal navigation usability proof. |
| 87 | Country intro chooses reviewed association kinds ahead of water/resource/neighbor, with capital/region fallback. | Country detail/map feedback tests; current association ordering in `country_learning.dart`. | **Partial**: some records necessarily use fallback facts; quality needs editorial review. |
| 88 | Async data/photo paths expose loading/error/retry UI rather than a blank screen. | Quizipedia image/catalog and water retry tests. | **Partial**: no measured end-user loading latency on release target. |
| 89 | Fact-practice and native/photo generation use checked explanations and six distinct choices when pool permits. | `fact_practice_models_test`, `quizipedia_test` native/photo six-choice and explanation cases. | **Partial**: legacy/small pools retain bounded fallback; no invented distractors. |
| 93 | Capital points and labels use reviewed coordinates, collision handling, and selected priority. | Map/capital feedback tests and capital asset contract. | **Partial**: dense labels intentionally declutter until zoom; “all marks” cannot coexist readably at world scale. |
| 94 | Lazy image/data paths and bounded caches avoid broad eager work. | Lazy flag test, thumbnail behavior tests, image cache limits. | **Partial**: no cold-device production timing measurement. |
| 99 | Capital dots use `capital_points.json` coordinates, not country centroids; selected capital remains visible. | Country feedback/map renderer tests and coordinate asset parser. | **Covered** for shipped matched capitals; 28 unmatched records remain honestly absent. |
| 100 | Selected country and land neighbours have separate outline styles. | `neighborIds` painter path; selected-border tests. | **Covered**. |
| 101 | Country card opens with an association-first memorable fact; capital/region fallback remains non-empty. | Country fact/card tests and data-validation path. | **Partial**: not every country has a unique cultural association. |
| 102 | Layers are direct, one-tap controls. | `country-direct-layer-*` widget checks in country/water tests. | **Covered**. |
| 103 | Flags are enlarged discrete markers with names, never polygon fill. | `lazy_flag_test`, `feedback_country_test` raised-marker pixel/assertion. | **Covered**; world view intentionally caps assets/markers at 8 for readability and lazy loading. |
| 104 | Waterways layer has water geometry, labels, search/focus and checked practice. | `waterways_ui_test` on-demand/retry/manual-camera and phone grading. | **Covered** for shipped waterways. |
| 105 | Country-name overlay is enabled by default and collision-aware. | `atlas_map_test` readable labels; map feedback tests. | **Partial**: “always” conflicts with overlap avoidance; small/dense countries appear on zoom or selection. |
| 106 | Active layer set permits names, capitals, flags and several fact layers together. | `feedback_country_test`: names/capitals/flags together; culture/religion layer tests. | **Covered**. |
| 107 | Labelled Countries entry opens searchable country sheet/list. | `feedback_country_test` phone picker/search. | **Covered**. |
| 108 | Anatomy data/model exposes full scoped inventory and organs/glands route. | Organ parser/inventory/fair-round tests. | **Covered** within documented shipped inventory. |
| 109 | Separate scopes/routes exist for organs, bones, brain, systems, plus vascular atlas. | Home cards; organ scope and vascular tests. | **Covered** for those routes; “etc.” remains unbounded. |
| 110 | Domains use separate catalogues/topics/scopes instead of a single undifferentiated page. | Anatomy, music, chronology and photo widgets. | **Covered** structurally; final visual density still needs phone review. |
| 111 | History uses interactive chronology timeline with events/cards. | `knowledge_atlas_test` chronology/date/relation tests. | **Covered**. |
| 112 | Country names render at first map view with collision-aware labels. | `atlas_map_test` and feedback country label tests. | **Covered** with the same zoom/declutter limitation noted for 105. |
| 113 | Direct layer row is immediately available; no nested layer popup required. | Country/culture/religion/water widget tests. | **Covered**. |
| 114 | Country picker/search is labelled and opens a country list; map training no longer starts on an unexplained “find fact” prompt. | Phone picker/search and Quizipedia explore tests. | **Covered**. |
| 115 | Country selection shows fact/detail immediately; practice feedback is shown on first checked answer. | `feedback_country_test` selected fact and first-tap feedback. | **Covered**. |
| 116 | Association-priority opening fact added before neighbour facts. | Country implementation/order and feedback tests. | **Partial**: countries without a reviewed association use explicit fallback. |
| 117 | Photo module starts as filterable/searchable catalogue, shows thumbnails before full photo. | Quizipedia photo-catalog/filter tests and thumbnail cache logic. | **Covered** for catalog-first behavior; cold-network latency remains unmeasured. |
| 118 | Constellation catalogue has previews, group filters, search and plotted-star category. | `constellation_atlas_test` filter/search/phone cases. | **Covered**. |
| 119 | Correct-answer and other-option explanations are rendered. | `quizipedia_test` photo explanations; fact/knowledge models validate explanations. | **Covered** where source text exists; no claim that every historical legacy record has an explanation. |
| 120 | Loading/error/retry states added for assets/catalogues and lazy loading bounded. | Quizipedia and water retry tests. | **Partial**: duration complaint requires real release/device measurement. |
| 121 | Home has separate Russian cards for organs/glands, bones/skeleton, brain and systems; bones scope says 206. | Home scope construction; `organ_atlas_test`; phone bones artifact. | **Covered** for the stated separation and shipped 206-bone catalogue. |
| 122 | Music starts at topic overview and can return to all topics. | `music_learning_test`; `music-topics`/back controls. | **Covered**. |
| 123 | History has a zoomable/interactive time representation. | Chronology timeline implementation and knowledge tests. | **Covered**. |
| 124 | Culture/history timeline and topic separation exist. | Knowledge timeline/topic code and tests. | **Covered**. |
| 125 | People/culture cards now have shipped media previews/photos. | Home media mapping and final media checks. | **Partial**: breadth/curation of “need photos” is subjective and finite. |
| 126 | Brand domain has logo/media support. | Brand atlas media/hash listed in final review manifest. | **Partial**: audit did not independently inspect every logo attribution/display. |
| 127 | Food cards have image/media support. | Food atlas media/hash listed in final review manifest. | **Partial**: audit did not independently inspect every image/attribution. |
| 128 | Greek mythology media/portrait assets are wired into topic cards. | Home mythology preview/media manifest. | **Partial**: “more portraits” is an unbounded quantity request. |
| 129 | Religion domain expanded and has source-validated catalog/parser. | Belief/religion source/parser tests in final pass. | **Partial**: “more religions” has no finite requested target. |
| 130 | Animals catalogue distinguishes species and breeds, has filters, source links and image fallback. | `animal_atlas_test` data/filter/detail cases; home Animals route. | **Partial**: “all possible living beings” is unbounded; runtime animal import/content gate remains a release/content decision. |

## Remaining cross-cutting risks

1. No independent post-freeze phone/browser acceptance was performed in this audit. Existing screenshots and widget tests are evidence, not a replacement for user visual approval on 361×738 and 393×851.
2. The plan itself says 28 territory/capital mappings are intentionally unmatched; the capital layer must continue to omit them rather than invent coordinates.
3. Label/flag/capital decluttering deliberately trades global completeness for readable overlap-free rendering. Zoom/selected priority restores information; this should be checked against the user’s expectation for items 93 and 105.
4. Requests phrased as visual preference, performance duration, “more”, or “all” are not objectively closed by the present code. They need a bounded acceptance threshold or user review.
5. This report makes no publication, deployment, server-space, or feedback-status claim.
