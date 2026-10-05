# Food 423-C annotation report

Scope is exactly `food-reworked.json` records `[150:225]`, in source order: first `q_gastronomy_сладости_и_десерты_9_food_154`, last `q_gastronomy_техника_приготовления_51_food_692`; 75 unique quiz records. The output references `qm-tags-v1` semantic SHA-256 `09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e` (423 tags), including the approved food-topic extensions where applicable.

Evidence: all 75 raw questions were reread in three ordered batches of 25. Each read included full stem, all six alternatives, stored keyed index, resolved keyed option, and explanation. The frozen inventory revision is `e802ed21db936bdb9809bab2d137903eb0aa425e`; all 11 Gastronomy source pack byte hashes match its inventory. This slice is represented by `gastronomy_sweets_and_desserts.json` `bbf1a35d66380c56b08d1ddae762274bf72e10a0f01f094bcab0f5c265562e59`, `gastronomy_spices_and_ingredients.json` `476d1e68c7066eba4f0a77c06a857b87ddd282e4dd756369e4a30a62f31406e1`, `gastronomy_cheeses_and_dairy.json` `5ce0d64767cae15b96834f598bcc760de56a2cbae404cd0d7e5a524b6bdbfbbe`, and `gastronomy_cooking_techniques.json` `248940c245118dd7ca44e530455fb715708450e0ea3c3527e2b515df970783f1`.

The annotation has 75 private editorial rationales and 75 public-safe context tag sets. It contains 350 editorial tags, of which 120 are non-public tags, and 150 context tags. Editorial facet counts are country 23, cuisine 39, domain 76, era 4, ingredient 58, knowledge skill 75 and topic 75; contexts contain 75 domains and 75 topics. Scores are independent rubric estimates, not calibrated performance statistics. Keyed-answer entities are private; contexts describe the visible domain/topic only.

Flags retained or added for factual, medical, legal, cultural, ranking, quantitative and answer-format concerns. In particular, the German Chocolate Cake stem contradicts its explanation, the mirepoix answer choices are malformed, the `tourné` stem calls a French cutting technique a Japanese knife, and the dietary/medical and record claims remain unverified. Ingredient semantics deliberately avoid treating tiger milk as dairy, Nutella paste as wheat pasta, quinoa as a true cereal, or duxelles as pasta.

JSON SHA-256: `51432d6ee8570faa6445bed1c26bf47d09d169deb2c2855184bd3b2275ad211e`.

## Root independent-review delta

Reviewer FOOD_423_DELTAS_B_C requested exact tag-only changes for q_gastronomy_специи_и_ингредиенты_20_food_p5_85, q_gastronomy_сыры_и_молочные_продукты_9_food_193. Root reread four full raw questions and confirmed wax distractor/seafood/generic oil/dumpling subject. BeforeSHA `51432d6ee8570faa6445bed1c26bf47d09d169deb2c2855184bd3b2275ad211e`, currentSHA `16546a5cba8865b7f6cc4b2806a6c4c1bdef14c07850861205d672a07175d04d`; all other fields and rows unchanged. Metadata validation passed in helper. Delta acceptance pending.
