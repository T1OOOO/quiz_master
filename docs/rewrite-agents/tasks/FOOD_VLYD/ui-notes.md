# FOOD_VLYD UI notes

`FoodAtlasPage` uses the frozen `qm-food-atlas/v1` contract through
`FoodAtlas.fromJson`. The list searches dish names, named ingredients, regions,
and variants; a selected detail remains visible when the list is filtered away.

Practice is local and unranked. It creates a ten-dish frozen round with four
unique regional answers for origin prompts and four unique dish answers for
composition prompts. Answer labels follow the active RU/EN locale. The source
links, feedback and an explicit original-score display remain available through
the finite missed-question review.

The Train control is disabled when fewer than ten dishes are available. Loading,
empty and retryable parse/load failures are represented without adding a data
dependency.
