# Vocabulary extension to 423 review

## Verdict

**Requirements: ACCEPT. Vocabulary quality: ACCEPT.** The proposal is a
controlled, compatible extension of the current 403-tag vocabulary. It is not
an applied dictionary, annotation revision, factual certification, or
publication decision.

## Scope and checks

- Reviewed `taxonomy-extension-proposal.json` (SHA-256
  `03c898234255ee7cbba6dfc737192542b3d9b3b8d384a5ef316a07b0e19fbe31`),
  `FOOD_VOCABULARY_AMENDMENT.md`, and the exact 66-gap register in
  `annotations/food-reworked-report.md`.
- Read every one of the 66 mapped food raw records with stem, all options,
  keyed index, and explanation in three batches of 23, 23, and 20 records.
- Read the complete raw records for Transformers
  `12a78c51-e30f-4f99-b2ec-14cf310afb90` and Home Alone
  `q_ha1_p1_13`, plus their reworked metadata/report context.
- Current dictionary is `qm-tags-v1` at 403 entries, SHA-256
  `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`.
  The proposal correctly declares 403 base and 423 proposed entries.
- Mechanical proposal check: 20 unique additions; valid ID/facet prefixes;
  all parents resolve in the 403 base plus proposed set; no duplicate IDs;
  no empty labels; and no exact case-insensitive proposed label/alias collision
  with an existing dictionary label, alias, or ID. Ingredient additions are
  private; all other proposed concepts are player-safe.

## Semantic assessment

The 12 food topics map to visible subjects rather than keyed-only material:
products/dishes, edible fungi, restaurant operations, taste, chef roles,
space food, food history, pasta/grain foods, food regulation, logos, general
law, and food safety. The 66 examples support those concepts. Per-question
context still needs only safe visible domain/topic terms; countries, cuisines,
and ingredients remain private metadata.

`domain:society` with `topic:law-regulations` correctly covers the cactus,
camouflage, currency, monument, and driving-rule questions. `topic:food-law`
is narrower and correctly fits food-specific regulation such as the Japanese
metabo rule, sandwich restriction, ice-cream rule, and gum restrictions.
`topic:brand-logos` is a safe design/arts concept for the visible Starbucks
logo question.

The ingredient additions are semantically sound and private by concept:
maize is a grain/starch for the tamale prompt; quinoa belongs under the broad
grain/starch food family without asserting it is a true cereal; peanut fits
the culinary nut/seed family; and saffron fits herb/spice. They are not made
public context merely because they appear in a keyed dish.

`medium:comics` fills the Transformers lore-medium gap without recasting
comics as film or books. `topic:animation-production` exactly describes the
palette-error Transformers prompt, whose visible subject is an animation
production error. `topic:film-music` exactly describes the Home Alone montage
song prompt; it is more specific than the prior closest `film-production`
topic. The `medium:comics` alias `graphic novel` is a usable synonym, and the
remaining proposed aliases do not create an exact dictionary collision.

The proposed parent graph and player-safe settings are compatible with the
existing v1 metadata model. When root applies it, the normal dictionary hash,
all annotation taxonomy references, and validators must be regenerated; those
future application checks are outside this proposal-only review.

The reviewed source statements, keys, explanations, rankings, health claims,
and legal claims are not independently fact-certified here. Existing private
source-risk flags remain necessary.
