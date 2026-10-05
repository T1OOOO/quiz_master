# LOTR semantic reread and correction — 2026-10-05

Reviewable private annotation draft. No independent acceptance, publication, observed player calibration, or complete 4078-record gate is claimed.

## Provenance and scope

Agent `/root/lotr_semantic_61` reread all 253 actual source records: every stem, every option, correct index/key, and explanation. Scope is `lotr:3`, `lotr_fellowship_100:50`, `lotr_return_king_bts_100:100`, `lotr_two_towers_lore_100:100`. Identity coverage is 253/253 with no missing, extra, or duplicate provider/pack/question tuples.

An existing 253-row `lotr-reworked.json` was already present when ownership transferred. Its SHA256 before replacement was `82a5254c5e7b5c6b2934534b93ed61fb88ddf0a17ba13bb53d5db783f6a94d43`; original local mtime was `2026-10-05T14:35:26.820988+03:00`. Its authorship and completion provenance are uncertain: the recorded legacy Sol turns ended with capacity errors, so a file on disk does not establish successful completion or acceptance. This agent reviewed and corrected that candidate; it did not author all retained rationales from scratch. All 253 score decisions were individually reconsidered; 136 scores changed, 117 retained. In total 151 rows changed in score/rationale/tags/confidence/flags; 102 rows were retained after reread. Original rejected `annotations/lotr.json` remains byte-identical with SHA256 `836940f12fd8486dc9bb44d5d4436be1618e8955e6a2ac79ec8e79f12948b64b`.

Actual read batches in this turn: base 3; Fellowship 50; Return King 1–50 and 51–100; Two Towers 1–50 and 51–100. No stems/options were truncated in those outputs. Existing annotation rows were separately inspected in three complete batches. No filename, question length, old numeric field, keyword classifier, default score, or target band quota assigned a judgment. The transcription script used an explicit 253-ID score table and explicit correction-ID lists. Sound per-question rationales were retained after comparing them with actual wording and choices.

## Taxonomy and public context

Envelope is `qm-question-annotations/v1`; `taxonomy_ref` is `qm-tags-v1` / `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`. The dictionary semantic hash was recomputed. All tags are frozen members; all rows have a domain and a specific topic/franchise. Tags are sorted unique. All public context tags are a safe subset of editorial tags. Named Gandalf/Tolkien entities remain private; no distractor entity is tagged.

The actual visible descriptions of Fellowship and Return King mention BOTH books and films. Two Towers announces Rohan, ents and ancient history; base LOTR announces the legendarium. Neither the folder `Cinema` nor the `bts` filename establishes a film-only question. Shared lore therefore uses `domain:arts` + `franchise:middle-earth` with its visible topic. Actor/music/VFX questions establish screen context themselves in the announced trilogy. Book/film medium tags require the actual wording or an unambiguous activity such as screen acting; explanation-only evidence is insufficient.

Removed `medium:book` from `lotr_f_35` (English original alone does not specify medium) and `lotr_rk_85` (the prologue is mentioned only in its explanation). Added book context to `lotr_rk_61`, which explicitly says “в конце книги”. `lotr_rk_100` is score 8, character/franchise context, with no film/book tag. Film-specific `lotr_f_11`, `lotr_f_46`, `lotr_rk_5`, and `lotr_tt_56` explicitly identify their version. No taxonomy gap is required for this scope: the frozen lore, characters, fictional artefacts, literary works, word meanings, writers, actors, film production/plots/awards topics together with Middle-earth represent the actual questions. Fictional foods, animals and places were not forced into real-world food/nature/country facets.

Medium book context (23 rows): lotr_f_34, lotr_f_44, lotr_f_47, lotr_rk_12, lotr_rk_19, lotr_rk_20, lotr_rk_27, lotr_rk_30, lotr_rk_34, lotr_rk_35, lotr_rk_61, lotr_rk_67, lotr_rk_78, lotr_rk_96, lotr_rk_99, lotr_tt_19, lotr_tt_42, lotr_tt_52, lotr_tt_59, lotr_tt_73, lotr_tt_74, lotr_tt_95, lotr_tt_99.

Medium film context (28 rows): lotr_f_11, lotr_f_4, lotr_f_46, lotr_rk_20, lotr_rk_23, lotr_rk_25, lotr_rk_28, lotr_rk_36, lotr_rk_42, lotr_rk_46, lotr_rk_47, lotr_rk_49, lotr_rk_5, lotr_rk_50, lotr_rk_86, lotr_rk_87, lotr_rk_88, lotr_rk_89, lotr_rk_90, lotr_rk_91, lotr_rk_96, lotr_tt_18, lotr_tt_22, lotr_tt_24, lotr_tt_51, lotr_tt_55, lotr_tt_56, lotr_tt_63.

## Concrete editorial decisions

- `lotr_rk_100` — 8: Paladin Took as Pippin's father is obscure family detail; “Тан Тук” is a plausible distractor, not ordinary score 4 knowledge.
- `lotr_rk_18` — 2, not previous candidate 8: “названного в честь Фродо” supplies the namesake; “Фродо Гэмджи” is directly recoverable.
- `lotr_rk_43` — 5: actual stem does NOT contain Itilien. The prior candidate's rationale invented a clue; the player must recognise Faramir's ranger unit.
- `lotr_rk_59` — 2: only the keyed option lists two sons. `lotr_rk_64` — 2: only the keyed option is an occupation. Both clue effects are private flags.
- `lotr_f_44` — 5: most offered heights are plainly too large or tiny for hobbits; the stem does not ask players to convert feet, despite the previous rationale.
- `lotr_rk_76` — 3: the familiar battle name can help recall five, but “Битва Пяти Воинств” is absent from the stem; it is not a ready-made in-stem answer.
- `lotr_rk_42` and `lotr_rk_67` — 9: black fluid in a screenplay and the exact materials of new gates in Appendix A are genuinely rare details. No score 10 was manufactured.
- `lotr_tt_56` — 8: precise 43/42 order before the next shot in the extended cut is detailed fan recall with near-identical alternatives.
- `lotr_tt_48` — 6: specialist protective lore is eased by only one option carrying Melian's name. `lotr_tt_84` — 2: Numenoreans can be mapped to people of Numenor by the visible wording.
- `lotr_tt_54` and `lotr_rk_97` — both 6: the same Galadriel/Celeborn marriage is assessed consistently in opposite directions.

## Separate concerns for independent review

Flags preserve existing answer keys; these concerns were noticed during semantic review, not independently re-fact-checked. Prior release fact verification remains a separate provenance claim. Every flagged/low-confidence row needs the frozen subsequent review.

- `lotr_rk_34` (low): white jewel on a chain and “Ожерелье с кулоном” overlap semantically; the latter could describe the same gift. Score 7 estimates the detail, not a penalty for ambiguity.
- `lotr_rk_95` (low): unspecified “Белые Корабли” lacks an epoch/scene; Alqualonde competes with keyed Mithlond. No invented city context resolves the source wording.
- `lotr_tt_75` (low): Elendil/Gil-galad is the textual account, while the film prologue encourages Isildur; version is missing from the question. Public book/film tags are omitted.
- `lotr_rk_62` (low): “У него не было имени” means no name supplied by the book according to its explanation; lack of a mentioned name is not proof the horse had no name, and the stem does not specify book/film.
- `lotr_rk_58` and `lotr_tt_65`: exact Russian quoted descriptions depend on translation/dub and unannounced version. `lotr_rk_74`, `lotr_rk_16`, `lotr_tt_62`, `lotr_tt_66`: particular book episodes lack explicit version. These do not create public medium tags.
- Existing resolved book/film-boundary and translation-boundary flags remain where appropriate, including explicit film rescue in `lotr_f_11`; a flag alone does not declare an answer wrong.

Flagged record IDs (29): lotr_f_11, lotr_f_35, lotr_f_44, lotr_rk_16, lotr_rk_18, lotr_rk_34, lotr_rk_45, lotr_rk_47, lotr_rk_5, lotr_rk_52, lotr_rk_58, lotr_rk_59, lotr_rk_62, lotr_rk_64, lotr_rk_74, lotr_rk_84, lotr_rk_85, lotr_rk_95, lotr_rk_96, lotr_rk_99, lotr_tt_17, lotr_tt_48, lotr_tt_6, lotr_tt_62, lotr_tt_65, lotr_tt_66, lotr_tt_75, lotr_tt_84, lotr_tt_87.

Scores: `{"2": 17, "3": 28, "4": 41, "5": 37, "6": 54, "7": 53, "8": 21, "9": 2}`. Confidence: `{"high": 150, "medium": 99, "low": 4}`. These are editorial estimates for Russian-speaking adult general-knowledge players; confidence concerns the individual editorial assessment and source interpretation, not measured success rates.

## Preservation and bounded verification

The four raw quiz source byte hashes were captured before editing and rechecked after writing. No raw source, stem, option/order, correct key, explanation, media, code, asset, unrelated draft, or Atlas file was edited. No child agents, commits, pushes or resource-heavy checks were run by this worker. Root retains integration/release/git ownership.

| Raw source | SHA256 before and after |
|---|---|
| `quizzes/Cinema/LOTR/lotr.json` | `ea5c763bd578805d9200fef2edf86883916ead4588f3693e024ae1bac8b7d79a` |
| `quizzes/Cinema/LOTR/lotr_fellowship_100.json` | `eb20f18f0736c1467d825b5385b610cb582d02d82bd28c321850b8f829e5e184` |
| `quizzes/Cinema/LOTR/lotr_return_king_bts_100.json` | `da496ad3af3dcf3e33276639bd63b64a84de421229fb77f97d8c295e13571f5c` |
| `quizzes/Cinema/LOTR/lotr_two_towers_lore_100.json` | `73265066f54e43d6d124f63036ab1382f88ad1ef955fe7a69ba76eee0bbe5ea4` |

Output annotation SHA256: `8da54a8916c23cbfba6a627ee9ee49f020737b4eed5beeebd485e1103eab8b69`.

Lightweight complete-scope checks: JSON reload; 253 exact identity matches; integer 1–10 boundaries; nonempty rationales; confidence enum; sorted unique valid editorial/context tags; domain + topic/franchise membership; context subset and `player_safe`; no public person entities; frozen taxonomy semantic hash; all four source byte hashes; rejected original byte hash. These mechanical checks establish structural/preservation evidence only, not independent editorial acceptance.
