# Russian sky labels review note

`catalog.json` now supplies `name_ru` for every shipped constellation star.
Common proper names use established Russian forms where mapped (for example,
Сириус and Альферац). Bayer and Flamsteed designations retain their numeric
parts, spell the Greek letter in Russian, and use a Russian genitive
constellation name (for example, `Альфа Насоса` and `52 Тау Кита`). `HIP`
identifiers remain standard catalogue identifiers when no proper name is
available; no new astrophysical fact is attached to one.

`82 G. Eri` is rendered as `82 по каталогу Гулда Эридана`: `G.` identifies
the Gould/Uranometria Argentina designation rather than a Flamsteed number.
The [CDS catalogue listing](https://cdsarc.cds.unistra.fr/cats/V.htx) identifies
V/135A as Gould's *Uranometria Argentina* catalogue.

Rare unmapped proper names are transliterated display labels, not assertions of
an IAU-endorsed Russian proper name. Russian constellation explanations contain
only Russian prose, use the generated Russian selected-star label, and preserve
the existing caveat that Stellarium lines do not indicate official boundaries or
physical links.

The display-only work keeps the existing IAU-abbreviation URLs and catalogue
data intact. It uses conventional Russian educational spellings for the mapped
proper names; unmapped names remain explicitly transliteration labels.
The rare mechanically transliterated proper names still need independent
Russian astronomical-naming review before being treated as conventional names.

Integration API for the root and legacy views: `starLabel(star, russian)` in
`constellation_atlas.dart` chooses non-empty `name_ru` for Russian UI and
preserves `name` in English UI. The data field is therefore ready for the root's
separate legacy Quizipedia star views.
