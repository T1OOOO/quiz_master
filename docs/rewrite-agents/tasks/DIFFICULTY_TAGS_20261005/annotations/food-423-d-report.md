# Food 423-D annotation report

Scope is exactly `food-reworked.json` records `[225:299]`, in source order: first `q_gastronomy_техника_приготовления_52_food_696`, last `q_gastronomy_фрукты_и_овощи_9_food_52`; 74 unique quiz records. The candidate references frozen `qm-tags-v1` SHA-256 `09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e` (423 tags).

Evidence: all 74 raw questions were reread in three ordered batches of 25, 25 and 24. Each batch included full stem, all alternatives, stored keyed index, resolved key, and explanation. Frozen inventory revision is `e802ed21db936bdb9809bab2d137903eb0aa425e`; all 11 Gastronomy source hashes were verified against it. This slice uses `gastronomy_cooking_techniques.json` `248940c245118dd7ca44e530455fb715708450e0ea3c3527e2b515df970783f1`, `gastronomy_traditions_and_etiquette.json` `f597dddba6e299dd5b7a993b12938691dabd3170dc7b9fb449152ee6ee1ea84b`, and `gastronomy_fruits_and_vegetables.json` `6fcd6d520ee7ac9b8a064772c842ce7edf3afae35cf2699e0851967c831a47e9`.

Each record has an independent 1–10 editorial estimate and unique option-aware rationale. Private country, cuisine, ingredient and place tags identify the actual subject; safe contexts only describe visible food, science, geography, language, psychology or society topics. Medical, law, ranking, cultural-generalization, quantitative and answer-format concerns remain flags, not factual certification. The misdescribed `tourné` item is flagged in both duplicate occurrences. No tag equates oyster with fish, generic oil with olive oil, carnauba wax with sugar, or Turkish manti with pasta.

There are 345 editorial tags, 123 of them private; 148 context tags are public-safe. Editorial facets: country 41, cuisine 18, domain 81, era 5, ingredient 62, knowledge skill 74, place 2 and topic 74. Score counts are 2:4, 3:13, 4:19, 5:21, 6:12 and 7:5; no score was assigned from prior numeric data.

JSON SHA-256: `d67b0207e60c4aa816918a0566ba005b5f4abe37047283c2c25fe4fe82cade66`.
