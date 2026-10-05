# Difficulty and shared taxonomy proposal

Status: research recommendation, not an annotation or publication.  Frozen source: `e802ed21db936bdb9809bab2d137903eb0aa425e`; `INVENTORY.json` SHA-256 `6A4D8192F97C5469FA72F594EFCF4299602A4DFFA0415DBDDD0769A6C0C8E92E`.

## Scope and inventory evidence

I read the 126-pack inventory (3,958 questions), every question stem (3,765 unique; 193 repeats), and representative complete cards across all 22 listed categories.  It records 883 missing difficulties; existing values are 1:11, 2:121, 3:276, 4:855, 5:758, 6:502, 7:305, 8:207, 9:39, 10:1.  No missing score is being inferred here.

The packs group into the following reusable subject families: food (11); cats, dogs, and raccoons/nature (40); New Year (9); cinema/screen including Home Alone, Tolkien, themed worlds and Transformers (27); philias (10); philology (6); preparation/general knowledge (22); psychology/phobias (5).  The 22 inventory category labels are covered by the broad `domain:*` concepts and the topic/franchise/medium facets in `taxonomy-proposal.json`; the complete pack list remains the frozen inventory, rather than a second, drift-prone list.

Representative evidence that drives the distinctions: the cheese pack asks both the direct association of Parmigiano-Reggiano with Italy and an obscure Púle cheese milk source; the capitals pack distinguishes federal capital from largest or former city; the Tolkien pack mixes screen casting, named lore, and Appendix-level chronology.  Therefore neither pack title, stem length, option count, nor the mere presence of a proper noun is a valid difficulty proxy.

## Recommendation

Adopt `qm-taxonomy-v1` from `taxonomy-proposal.json` before annotation.  It is a small controlled vocabulary with stable typed IDs, Russian and English preferred labels, aliases, cardinality, explicit external authority for countries/places/persons, and curated cross-theme collections.  It covers the current bank without creating a tag per pack or per answer.

The frozen candidate dictionary contains 318 unique concepts: 195 countries, 48 ingredients (eight family/group concepts plus 40 reusable food concepts), 28 topics, 12 domains, 11 franchises, nine knowledge-skill concepts, five media, three eras, three places, two cuisines, and two persons.  A JSON parse/uniqueness check passes, and its 195 `country:*` IDs exactly equal the existing registry's 195 ISO2 IDs.  The 11 franchises cover Home Alone, Tolkien/Middle-earth, Transformers, Star Wars, Harry Potter, DreamWorks, Game of Thrones, Pixar, Terminator, Pokémon, and Nintendo; the screen-TV category is retained as a topic rather than pretending an umbrella category is a franchise.

The baseline assignment shape is:

```json
{
  "difficulty": 4,
  "difficulty_band": "medium",
  "editorial_relevance": ["domain:food", "topic:cheese-dairy", "country:IT", "cuisine:italian"],
  "player_safe_context": ["domain:food", "topic:cheese-dairy"],
  "knowledge_skill": ["skill:association", "skill:spatial"]
}
```

For the Parmigiano-Reggiano question this is defensible: `country:IT` is editorially relevant because it is the correct answer, but it must not be rendered before answering.  `domain:food` and `topic:cheese-dairy` are safe because they are already promised by the pack/stem.  Conversely, a question whose stem says only “Which country?” must not receive a player-visible cuisine/country context extracted only from the answer/explanation.

Countries are complete rather than illustrative: the proposal now embeds all 195 entries from the existing country registry and independently records its frozen source/hash.  Every ID is `country:<ISO2>` with that resource's actual RU/EN labels.  It is the source for all 195 capital and 195 flag questions, including multi-capital exceptions; annotations must use it rather than mint country spellings.  Place IDs carry their country where needed; fictional geography stays `place:*`; a franchise and a medium remain separate.  The proposal includes Italy and rice collections to demonstrate cross-theme retrieval without making those collections hints.

The ingredient vocabulary is likewise pre-built, with family IDs (grain/starch, dairy, meat/seafood, fruit/vegetable, herb/spice, nut/seed, sweetener and beverage) and common reusable members evidenced across the bank: rice (167 stem/explanation occurrences), cheese (23), milk (19), meat (24), fish (21), butter (17), sugar (14), coffee (15), tea (45), wine (27), water (219) and more.  These counts are discovery cues, not ratings and include non-food uses where a word is ambiguous.  The food pack subcategories map to `topic:cheese-dairy`, `topic:cooking-technique`, `topic:beverages`, plus the ingredient families; fruit/vegetable, meat/fish, spices/sauces, sweets/desserts, traditions/etiquette and general food facts remain controlled `topic:*` additions before annotation if their exact visible task needs a finer grouping.

## Difficulty rubric for the Russian general-quiz audience

These are editorial priors, not performance statistics.  Difficulty means expected accessibility to a general Russian quiz player with clear wording and plausible distractors, after accounting for the exact source/medium the stem promises.

| Score | Band | Editorial anchor |
|---|---|---|
| 1 | Easy | Near-universal recognition with an obvious correct option, e.g. a very prominent national symbol or capital. |
| 2 | Easy | Common school/cultural fact or famous association; one familiar distinction may be required. |
| 3 | Easy | Broadly familiar fact with plausible alternatives, e.g. Tokyo rather than Kyoto as Japan's current capital. |
| 4 | Medium | Common-domain knowledge or a clear comparison; a non-specialist can reason from an explicit clue. |
| 5 | Medium | Specific but culturally available fact; several distractors are genuinely plausible. |
| 6 | Medium | Less common named fact, terminology, date, or cross-association; fair only with unambiguous framing. |
| 7 | Hard | Specialist or niche cultural knowledge; expected mainly from committed readers/enthusiasts or study. |
| 8 | Hard | Deep lore, rare terminology, precise production/history detail, or several confusable alternatives. |
| 9 | Nightmare | Obscure, precisely scoped fact requiring exceptional recall; audit source and wording first. |
| 10 | Nightmare | Exceptionally narrow fact with little reasonable route for a general player; retain only when the pack explicitly promises expert challenge and evidence is strong. |

Band mapping is fixed: Easy 1–3, Medium 4–6, Hard 7–8, Nightmare 9–10.  The same fact can change by audience contract: a famous film character is generally easy, while a secondary character's name, a book-versus-film difference, or an appendix year is hard/nightmare even inside a themed pack.  The themed pack may signal scope; it does not lower the score by itself.

Suggested calibration anchors, to be debated by two editors comparatively rather than copied as ratings: (a) Tokyo as Japan’s capital: 2–3; (b) Abuja rather than Lagos as Nigeria’s capital: 4–5 because of the former-capital distractor; (c) Parmigiano-Reggiano’s country: 2; (d) Púle cheese's animal milk: 7–8; (e) `The Hobbit` first-publication year: 6–7; (f) Bilbo finding the Ring in Third Age 2941: 8–9 for the general audience.  These are anchors only, not changed quiz metadata.

## Annotation and calibration safeguards

1. Annotate the shared dictionary first, then blind-rate a stratified sample by domain and existing/missing difficulty.  Compare items in small sets, reconcile disagreements, then apply the rubric to the remainder.  ETS research reports that comparative judgments can estimate difficulty more accurately than independent ratings; editorial scores should later be checked against observed correctness, distractor selection, and item discrimination.
2. Make `editorial_relevance` private to filtering/editorial tooling.  `player_safe_context` needs affirmative evidence in the visible question, its explicitly announced pack, or displayed media.  Collections are retrieval aids, not UI chips by default.
3. Flag rather than force a score when source version, factual premise, correct answer, or two options are ambiguous.  Do not hide a weak item behind a high difficulty number.  In particular, pack-level “hardcore”, legacy option count (four vs six), translation/transliteration, and a long stem are not independent evidence of difficulty.
4. Preserve the distinction between recognition, direct recall, association, temporal, spatial, terminology, classification, comparison, and quantitative tasks.  This makes later balancing and player choice possible without suggesting the keyed answer.

## Sources visited on 2026-10-05

* [W3C SKOS Reference](https://www.w3.org/TR/skos-reference/) says a concept scheme can identify concepts, attach preferred/alternative labels in natural languages, assign notations, document them, relate them, and group them into collections.  That supports typed stable IDs, RU/EN labels, aliases, and separate cross-theme collections.
* [NCME, *Standards for Educational and Psychological Testing*](https://ncme.org/resources/books/testing-standards/) identifies the jointly produced Standards as guidance for testing.  The score bands here must remain an intended-use editorial interpretation until data supports stronger claims.
* [ETS, *Estimating Item Difficulty With Comparative Judgments*](https://www.ets.org/research/policy_research_reports/publications/report/2014/jtmq.html) reports that comparative judgments of item difficulty can improve estimates over independent ratings; it motivates the calibration procedure, not a claim that these items have measured difficulty.
* [ETS Fair Tests and Communications Guidelines](https://www.ets.org/pdfs/about/fair-tests-and-communications.pdf) says the action needed should be clear, required context should be common knowledge or supplied, and specialized vocabulary should not create irrelevant difficulty.  This supports separate ambiguity review and the prohibition on answer-derived player hints.

## Alternatives and tradeoff

An alternative is only broad category tags plus a scalar difficulty; it is cheaper initially but cannot support cross-pack discovery such as Italy/rice, nor distinguish book from screen or direct recall from comparison.  A full knowledge graph of every character, work and place is premature and expensive.  This bounded SKOS-inspired vocabulary plus governed external registries is the smallest reusable middle ground.

Unknowns to resolve before a full attachment pass: the task packet does not define source ownership for a complete global place/person/work authority; use a controlled additions queue instead of local IDs for those.  Food stems contain named dishes/products and ingredients beyond the reusable base vocabulary, which should be attached as editorial relevance only until a second question justifies a stable shared concept.  The player UI's exact filter vocabulary also needs a later contract.  The proposal intentionally does not manufacture 883 ratings, empirical success rates, factual verification, or player-facing disclosure rules.
