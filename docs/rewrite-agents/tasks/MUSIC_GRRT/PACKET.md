# MUSIC_GRRT / quiz_master-grrt
Root owns new music_learning.dart, music_learning.json, country_culture.json; country_learning.dart, quizipedia.dart, pubspec font registration, new music tests and this task folder. Preserve other dirty files. No extra implementer agents. Independent read-only review by official managed provider per AGENTS.

Scope: RU/EN foundational music reference (Western notation, note reading, rhythm, dynamics, performance terms, harmony and orchestral/traditional instruments), source-linked detail cards, visible notation rendered using bundled OFL Bravura font, search/category filter, finite local unranked four-option practice with explanations and mistakes review. Honest coverage note: foundational selection, not every term in every musical tradition. No audio recognition claims.

Country culture: selected primary-source musical-instrument and heritage associations; separate sourced asset, searchable, layers, detail sections and existing fair forward/reverse practice. Shared traditions explicitly related to all source-listed countries; never exclusive national ownership. Preserve manual camera on selection. Source-specific checked_on dates.

Asset music schema qm-music-learning/v1: sources [{id,title,url,checked_on}], entries [{id,category,name_ru,name_en,description_ru,description_en,example_ru,example_en,source_ids,visual?}], questions [{id,stem_ru,stem_en,option_ids,correct_id,explanation_ru,explanation_en,source_ids,visual?}]. Categories notation,notes,rhythm,dynamics,tempo,technique,harmony,instruments,world. visual optional: glyph (integer SMuFL codepoint), text (string), note (0..6 for C4..B4).
Country asset same existing association contract: sources list and countries keyed ISO2 with rows id/kind/name_ru/en/relation_ru/en/source_id/checked; kinds instrument,culture.

Verification root: test-before implementation navigation/asset, focused tests for malformed data/options, mobile flow and fair shared associations, full Flutter tests/analyze/release, real hot reload/restart, browser mobile/desktop, independent facts/code review, explicit-scope commits, clean exact-commit checks, push. Web evidence is not Android hardware evidence.

Integration test ownership: learning_navigation_test.dart brand navigation now ensures the scrolled tile is actually inside the viewport before tapping; the added card exposed its existing viewport assumption. Full first run210passed/1failed; regression repair is tested in final suite.
