# BELIEFS_A0IZ frozen packet

User: interactive Greek deity relationship map, comparative religious traditions,
and religion labels on existing country map. Existing manual zoom remains controlled
by user, never changed by choosing a node/country.

Belief asset assets/quizipedia/belief_atlas.json, schema qm-belief-atlas/v1.
Top fields schema_version, coverage_note_ru/en, sources[], nodes[], edges[], questions[].
Source: id,title,url HTTPS,checked_on YYYY-MM-DD.
Node: id,section (greek|religions),name_ru/en,group_ru/en,summary_ru/en,
domains_ru/en (string lists, canempty),symbols_ru/en (string lists,canempty),
facts:[{text_ru/en,source_ids}],variant_note_ru/en (strings,canempty),source_ids.
Edge: id,from_id,to_id,label_ru/en,scope_ru/en,source_ids. Named direction explicit:
parent→child (label Father/Mother), spouse symmetric stated, related tradition
connections never imply unsupported biological descent. Both nodes same section.
Scope contains myth/source version for any contested genealogy. No invented dates.
Question: id,section,stem_ru/en,option_ids (four node IDs, same section, unique),
correct_id (exactly once),explanation_ru/en,source_ids. Self-contained fair single
answer, qualify source/version when needed. Never quiz disputed unqualified lineage.

Content target:20–24 Greek figures spanning primordial/Titan/Olympian generations,
Hades and Persephone;9+ representative religious traditions, with honest coverage
note and no implication that all religions are one simple family tree. Branch nodes
are optional if precisely sourced. At least10 Greek and6 religion source-backed
questions. No unsupported canonical12Olympians, Aphrodite/Hephaestus parent claims.
Ancient stories described as traditions, faith claims attributed neutrally. Real opened
museum/academic/primary-text/community sources; no guessed URLs. Sources support
all node domains/symbols/facts, graph edges and question keys. Keep concise original
prose, per-source word limits across RU+EN. Do not let artificial minimums induce
unsupported content: report needed scope adjustments before inventing fillers.

UI API BeliefAtlasPage({super.key,AssetBundle? bundle,String initialSection='greek'}).
Own model/parser/questions in belief_atlas_models.dart and UI belief_atlas.dart.
Two sections Greek gods / Religions, searchable accessible node list AND actual
interactive graph: labeled edges/direction, selected node + linked neighbor chips,
pan/pinch/manual +/-/fit/reset controls with selection preserving transform. Use
real semantic/tappable nodes and existing Flutter stack, no dependencies. Mobile
labels/detail scrollable at large text. No auto zoom when clicked. Faith traditions
must not be collapsed into a false exclusive descent tree; label actual relation.
Detail: roles/domains, symbols, facts, version notes, links/source-specific evidence.
Unranked local10-question frozen rounds, explicit Check→feedback+source→Next,
score, restart, finite mistakes review preserving original result; shuffle per round,
4 stable ID choices localized. Loading/errorretry/back/empty states. RU/EN follows
existing atlas conventions; no l10n/pubspec changes (other ownership).

Ownership: belief_data owns ONLY candidate JSON + source-audit.md in this taskfolder,
never canonical import. belief_ui owns new two Dart files + belief_atlas_test.dart +
ui-notes.md. Root owns country_religions.dart/data/import, country_learning.dart,
quizipedia.dart menu, navigation/data tests, final asset import, tests/build/git.
Root uses Pew2020 country affiliation estimates, sourceyear2020 (published2025),
not inferred official religion. No livelegal status claims from demographicshares.
Independent fact/code review before canonical import. Test-first for behavior; own
focused tests only. Root alone broadtests/build/browser. Shared checkout with peer
edits: never revert/stash/stage others. No worker commits/children. Project overrides
resourcequeue waiting for finite work. No production deploy/mainmerge authorization.
