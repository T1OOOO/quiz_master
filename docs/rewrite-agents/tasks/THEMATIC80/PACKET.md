# Themed questions: research → write → independent solve → import

Date 2026-10-04. Parent quiz_master-x3i. User requests additional themed questions for Terminator, Harry Potter, Game of Thrones, cartoons, series and others, following the answer-option cue audit. Deliver eight 10-question packs (80 total), Russian, four single-choice options, accessible/medium fan knowledge with some harder comparisons. Explicitly separate screen adaptations and books. Spoilers are inherent in the quiz descriptions.

## Frozen ownership and model routing

Writer A: quiz_master-1en, label thematic-franchises-20261004, qm_quiz_writer / gpt-5.6-terra / medium. Own ONLY `docs/rewrite-agents/tasks/THEMATIC80/franchises/**`:

| Pack ID | Question prefix | Topic / canon | Destination after acceptance |
|---|---|---|---|
| theme-terminator | theme-terminator-001…010 | Terminator (1984), Terminator 2 (1991), films only | quizzes/Cinema/Thematic80/terminator.json |
| theme-harry-potter | theme-hp-001…010 | Original seven Harry Potter books; common screen facts allowed only when consistent | quizzes/Cinema/Thematic80/harry_potter.json |
| theme-game-of-thrones | theme-got-001…010 | HBO Game of Thrones (2011–2019), not House of the Dragon or book-only lore | quizzes/Cinema/Thematic80/game_of_thrones.json |
| theme-star-wars | theme-sw-001…010 | Screen Star Wars, explicit film/context when needed; no Legends | quizzes/Cinema/Thematic80/star_wars.json |

Writer B: quiz_master-3fj, label thematic-screen-games-20261004, qm_quiz_writer / gpt-5.6-terra / medium. Own ONLY `docs/rewrite-agents/tasks/THEMATIC80/screen-games/**`:

| Pack ID | Question prefix | Topic / canon | Destination after acceptance |
|---|---|---|---|
| theme-pixar | theme-pixar-001…010 | Several Pixar animated films, varied characters/rules/story choices | quizzes/Cinema/Thematic80/pixar.json |
| theme-dreamworks | theme-dw-001…010 | Several DreamWorks animated films, e.g. Shrek, Kung Fu Panda, Dragons, Madagascar | quizzes/Cinema/Thematic80/dreamworks.json |
| theme-tv-series | theme-tv-001…010 | Several completed/established TV series: Friends, Breaking Bad, BBC Sherlock, Stranger Things etc.; identify series and episode/season when necessary | quizzes/Cinema/Thematic80/tv_series.json |
| theme-game-worlds | theme-games-001…010 | Recognisable game worlds, Nintendo franchises and/or other official publisher sources, specify game when mechanics differ | quizzes/Cinema/Thematic80/game_worlds.json |

Categories: films/TV/animation use `Кино`; games use `Игры`. Stable source pack/question IDs below 64 characters, ASCII kebab-case. Candidate `options` are strings; stable eventual option IDs are derived by quizctl from frozen source question ID and option index. No worker touches released quizzes, catalog, canonical bundles, schemas, codegen, Git/index, Beads, deploy files or other drafts. You are not alone; do not revert others. No recursive spawning. Lead alone imports accepted content and updates shared metadata.

## Research before drafting

Within your owned directory, save `research.md` and `sources.json` FIRST, before questions. Open official studio/publisher/creator sources, collect at least 10 distinct supported facts per pack and viable near-miss alternatives. Include exact URL, title, accessed date, actual opened evidence and a concise original paraphrase; record unavailable sources honestly. Search snippets alone are not sufficient evidence. A source supporting only the title/cast does not prove a plot detail. Avoid speculative fan theories, aggregate scraped quizzes, pirated books and unsupported dates/quotes. Fan wikis may locate an episode/fact but cannot be the sole final authority. No invented source URLs or inferred successful opens.

Primary starting points: harrypotter.com/fact-file and writing-by-jk-rowling, paramountpictures.com/movies/terminator-2-judgment-day, MGM/STUDIOCANAL/official film materials, hbo.com/game-of-thrones or official HBO/WBD material, starwars.com/databank, pixar.com feature film pages, dreamworks.com/movies, official Netflix Tudum/AMC/BBC/WBD series guides, Nintendo/other publisher game pages. Root located official Harry Potter Polyjuice and Hogwarts entries, Pixar Coco character guide, Paramount T2 synopsis and cast. You must verify the precise facts you actually use, not cite these as a blanket source.

Send a research checkpoint to root before writing. A 10-question pack is the pilot unit; no expansion beyond the four assigned packs. At most three production/actor/year facts per pack: prioritize in-universe relationships, locations, artefacts, rules and meaningful plot observations. For mixed packs include at least four works/franchises, not ten questions about one film.

## Output contract

For each pack `PACK.candidate.json`:

```
{"id":"PACK","title":"Russian title","description":"scope/canon, spoiler context","category":"Кино or Игры","questions":[{"id":"PREFIX-001","type":"choice","text":"Russian original stem","options":["A","B","C","D"]}]}
```

The candidate contains NO key, explanation, source annotation or correctness hint. `PACK.key.json` is private editorial evidence:

```
{"pack_id":"PACK","accessed":"2026-10-04","records":[{"id":"PREFIX-001","correct_answer":2,"explanation":"Original concise Russian explanation, reveal only after answer","difficulty":"средний","source":"exact opened URL","sources":["URL"],"evidence":"precise paraphrase supporting answer and limits","distractors":["why option0 plausible but wrong","why option1 plausible but wrong","why option3 plausible but wrong"]}]}
```

Distractor notes must correspond to incorrect options in their displayed order, with exactly three notes. Numeric difficulty is not measured; labels are estimates and will not be invented as calibration. Correct indices should use all four positions reasonably; do not make a visible repeating sequence. Do not shorten a necessary qualifier merely to meet a length target.

## Wording gate from the latest audit

Exactly one defensible answer. All choices must be the same semantic category and parallel grammar, plausible within the named world. Avoid cross-franchise joke answers unless the task explicitly tests comparison. No parenthetical proof, list of confirming names, alias/translation/model only on the correct choice, authoritative explanatory clause, or single unusually detailed option. No systematically hedged correct choice against absurd always/never distractors. Put explanation after the answer. If a version/date is necessary, put it in the stem or symmetrically qualify alternatives. Long proper names and natural terms are allowed when genuinely required. Explain plausibility and error of every distractor in private records.

Do not duplicate existing questions or paraphrase popular online quizzes. Root exported relevant existing stems at `existing-stems.json` without keys. Read that compact file. Independent checker will solve each candidate blind before opening the key, verify primary sources and all alternatives, then require concrete revisions. No auto-publication from schema or regex checks.

## Coordination and acceptance

Use the actual Beads ID as project hub task ID. CLI fallback: `C:/Users/Alexey_Matvienko/tools/agent-hub/.venv/Scripts/python.exe C:/Users/Alexey_Matvienko/tools/agent-hub/agent_hub.py`; task take/START/READY only, no done until root supplies real commit. Join host hub declaring actual gpt-5.6-terra/provider codex. Request fresh interactive lease: agent_turns1, RAM/commit256MiB, disk8MiB, shared read exact packet and existing-stems file, exclusive path your existing output directory. Renew before less than120 seconds remain; inspect each renewal result. Stop new work on renewal failure. QUEUED grants no permission; checkpoint and tell root. Release after operations finish, before waiting/end. Root releases preparation locks before dispatch. Host cap3 active turns includes lead; two workers use the two currently free slots. Leave unrelated reservations/processes alone.

Acceptance: research saved before writing; four10-question candidate/key pairs; exactly40 unique questions per writer; all URLs genuinely inspected; every option checked for ambiguity/plausibility; no source edits. READY report lists hashes, source limitations, counts, checks and unresolved factual issues. Independent factual approval, structural import and user-facing availability are later distinct gates.
