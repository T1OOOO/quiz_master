# Frozen metadata and selection contract — v1

Parent issue quiz_master-qr4. Baseline e802ed21db936bdb9809bab2d137903eb0aa425e. Coverage is 126 quiz packs / 3958 questions plus six accepted Study modules / 120 questions, total 4078. Foreign Wave3 drafts are excluded. This contract supersedes inconsistent examples in the research reports.

## Vocabulary and annotations

`metadata/tags.v1.json` is the pre-defined editorial vocabulary. Stable lowercase typed IDs, Russian/English preferred labels and aliases, facet, parent IDs, and `player_safe` are mandatory. Its SHA256 is over UTF-8 JSON excluding `taxonomy_sha256`, recursively sorted keys, compact separators, non-ASCII characters preserved. Validate the hash, duplicate IDs, parent references/cycles, facets, aliases, and collection references. Version/hash changes are explicit; no worker silently adds IDs.

Collections have `all_tag_ids`, `any_tag_ids`, `excluded_tag_ids`. A record matches when it includes every all-tag, at least one any-tag if that list is nonempty, and no excluded tag. Rice means all questions actually about rice across cultures; Italian/Japanese cuisines are neither substitutes for rice nor excluded. Country/ingredient/place/cuisine/person tags default private. The safe flag is necessary, but a context tag must also describe the visible stem/media or the announced quiz context. Never publish tags derived only from a keyed answer.

Raw quiz questions keep `difficulty` as an integer 1..10 and add `editorial_tag_ids` and `context_tag_ids`. Raw quiz root adds `taxonomy_ref: {taxonomy_id, taxonomy_sha256}`. Study keys retain their existing Russian `difficulty` label and add `difficulty_level`, `editorial_tag_ids`, and `context_tag_ids`; the key root adds the same taxonomy_ref. Candidate questions and Study Flutter projection remain unchanged. No answer, option order, stem, explanation, ID, source/media, or other existing data changes.

Every annotation record includes provider (`quiz` or `study`), pack_id, question_id, integer difficulty_level, sorted unique editorial_tag_ids, sorted unique context_tag_ids, brief individual rationale, confidence (`high|medium|low`), and editorial_flags. Every question must be read with all choices. At least one domain and one specific topic/franchise tag are required; entity tags describe the actual fact, not every distractor. Rationale/flags remain private. Do not infer difficulty from question length, pack filename, or previous numeric field alone. Scores are editorial estimates for Russian adult general quiz participants, not observed answer rates. Ambiguity, factual concerns and answer hints are separate flags, never automatically difficulty 10.

## Canonical content and compatibility

Canonical `difficulty` remains the band enum: unknown|easy|medium|hard|nightmare. Optional `difficulty_level` stores the exact integer. Mapping: 1..3 easy, 4..6 medium, 7..8 hard, 9..10 nightmare. Legacy canonical objects with a known band and no number remain readable. When a number is present it must match the band exactly; unknown cannot have a number. Newly imported annotated questions always have a number. Omit absent fields so old hashes remain valid.

Draft questions retain private editorial_tag_ids and public context_tag_ids. Draft has optional taxonomy_ref. PublicQuestion exposes only optional difficulty_level/context_tag_ids. Published Bundle retains taxonomy_ref and a private per-question metadata map with editorial tags; these are never copied into PublicQuiz/catalog/snapshot DTOs. Taxonomy membership and safe-subset validation occur at import/publication using the declared dictionary. Link validators additionally reject duplicate IDs, invalid subset relationships and wrong metadata question IDs. Do not require a live current dictionary to replay old stored bundles. Existing old archives without metadata remain valid. All added fields enter canonical hashes; importer/build must recompute hashes deterministically. Old attempt bundles, manifests, snapshots, answers and revisions are immutable.

## Per-pack difficulty selection

Add optional `difficulty` (`easy|medium|hard|nightmare`) to GET /v1/catalog query and POST /v1/attempts body. Absence preserves current selection and old URLs. Reject empty/null/duplicate/case-aliased/unknown values. In filtered selection, filter the complete immutable pack BEFORE splitting into 20-question rounds and shuffling inside the chosen slice. Omitted round selects all matching questions; an explicit round is zero-based (0 selects the first 20), preserving current numbering. Selected catalog and attempt must agree while retaining the full source bundle identity. Empty selections return an explicit no-match response; UI disables empty bands/rounds. No new composite or ranked mixed-pack route in this task.

Discovery asset entries add optional `difficulty_counts` (four band counts plus unknown if needed), and `context_search_terms` (RU/EN labels and aliases from approved context tags only). Global/per-pack selection uses labels Easy, Medium, Hard, Nightmare and preserves selected band in routes, reload, back navigation and request/catalog checks. Search uses those safe terms. Keep mobile layout usable with long prompts/choices.

## Editorial search and gates

Generate a deterministic private question index under metadata/ from quiz and Study sources, with taxonomy identity/hash, provider, pack/question IDs, title/category, numeric difficulty and all editorial/context tags. Provide a local CLI query supporting text, all/any/excluded tag predicates, numeric min/max, band, and exporting question IDs. It must use the dictionary labels/aliases, reject unknown filters, and include all 4078 records. Keep the editorial index out of Flutter assets and HTTP public responses. This supports future cross-theme collections without pretending Study is a ranked API provider.

Pilot annotation across food, country, nature, history and franchises gets independent review before bulk application. Full coverage/unique IDs, taxonomy references, score boundaries, answer-preservation, determinism and private/public boundaries are acceptance gates. Review all low-confidence/flagged entries and a stratified sample of the rest, explicitly record remaining subjectivity. Do not claim statistical calibration or independent review of all 4078 unless performed.

Meaningful tests: ten score boundaries and invalid types; legacy hash compatibility; dictionary unknown/duplicate/hash/subset failures; metadata privacy; filtered round partition/no-repeat/tail and catalog agreement; old partially answered attempt after source republish; strict Flutter DTOs and route selection/empty bands; CLI tag semantics and Study exclusion from ranked API. Existing stale count tests must be reconciled with the frozen inventory.

Root owns vocabulary, raw quiz/Study annotation application, source inventory, private index/pipeline, discovery asset generation, final integration/release/git. Backend/content worker owns Go server, executable contract schemas and their fixtures/tests only. Flutter worker owns Flutter lib/test/arb/codegen only, excluding assets. Reviewers own no production code. No worker commits, pushes, changes shared index, deploys, or spawns children. Resource-heavy work requires an actual granted lease and a renewal guard; text/JSON work uses the existing user exception.

## Vocabulary revision425 checkpoint

The independently accepted two-entry VOCABULARY_EXTENSION_425_PROPOSAL adds `domain:sports` and `topic:figure-skating`. All previous423 definitions remain unchanged. Current semantic SHA256 is `07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151`. ACCEPTED_REFERENCE_REBIND_425 records reference-only migration of2590 accepted decisions; ACCEPTED_WAVE_425_1 adds the reviewed NewYear75, for2665/4078. Nine disjoint frozen425 packets cover those remaining1413 identities. Empty candidate envelopes are not classifications. Source baseline and all preservation rules above remain unchanged. NewYear source key/explanation conflicts are tracked separately by quiz_master-jsu.

ACCEPTED_WAVE_425_2 subsequently accepts Cats112 after independent full-source metadata review and final62-row delta recheck, bringing acceptance to2777/4078. Eight frozen packets cover the remaining1301 identities: Dogs358, Preparation265, NewYear678. Dogs358 and Preparation265 are now author-complete, structurally validated but unaccepted. Dogs A180 full independent raw review has12 findings over15 identities; author correction/delta recheck remains. Dogs B178 independent review is pending. Preparation independent raw review has covered20 of its selected122 records; remaining102 and root's three-record B135 correction need recheck. NewYear678 is unannotated. This is metadata acceptance only; original facts and answer keys have not been certified or repaired.


ACCEPTED_WAVE_425_3 subsequently accepts Dogs A180 after independent full180 initial
source reading and root final15-row delta review, for2957/4078 accepted. Remaining
1121 = Dogs178/Preparation265/NewYear678. The prior checkpoint describes then-current
623 unaccepted drafts;180 of those are now accepted. All source preservation and
metadata-only acceptance limits above still apply.
