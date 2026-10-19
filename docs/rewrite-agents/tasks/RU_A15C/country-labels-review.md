# RU_A15C Russian country-label review

Reviewed: 2026-10-19. This review concerns presentation-language labels only; it does not alter the English canonical country facts, country IDs, capital entities, language entities, or currency codes.

## Scope and coverage

`country_facts.json` currently contains 250 rows. The static map covers every current nonempty value used by the Russian country UI:

| Field | Distinct shipped values | Treatment |
|---|---:|---|
| `capital` | 244 | Editorial Russian conventional city/capital names, including full composite administrative qualifiers. |
| `languages` | 155 | Russian language names for every source-language value, including values present where `official_languages` is absent. |
| `currencies` | 161 | Russian currency display names keyed by the unchanged ISO 4217 codes. |

The resulting `russianCountryLabels` map has 560 keys. The coverage test reads the shipped asset, requires each of those values to be a direct map key, verifies the API result differs from the English source value, and rejects Latin letters in resulting labels. Synthetic values outside the shipped asset deliberately remain unchanged.

## Naming evidence and method

- [United Nations Russian member-state list](https://www.un.org/ru/about-us/member-states) was used as an authoritative Russian-language reference for country-name style. It confirms the project’s Russian presentation convention; this change does not rename country records.
- [Unicode CLDR currency names and symbols guidance](https://cldr.unicode.org/translation/currency-names-and-symbols) describes localized display names for ISO currency codes. Currency labels were generated once with Node’s built-in ICU/CLDR-backed `Intl.DisplayNames(['ru'], {type: 'currency'})` and committed as static Dart strings, so app runtime has no locale-data or package dependency.
- ICU returned raw codes for CKD, FOK, GGP, IMP, JEP, KID, and TVD and used the Latin acronym `BEAC` in XAF. Those eight labels were replaced with Russian descriptive names in the static table, preserving the source code as the lookup key.
- Capital and language labels were individually edited as Russian conventional names rather than produced by a transliteration routine. The source asset remains the authority for which entity each English value denotes.

## Deliberate wording decisions and remaining linguistic review points

- `Pretoria (administrative); Cape Town (legislative); Bloemfontein (judicial)` remains a three-part label in Russian, with each qualifier translated. The display does not collapse this source distinction.
- `Amsterdam (capital; government in The Hague)` and `Sucre (constitutional capital)` also retain their source qualifiers in Russian.
- Established Russian exonyms are used where normal in Russian presentation, including `Киев`, `Кишинёв`, `Пекин`, and `Эль-Аюн`; this is a language-label decision and does not change the canonical English source text.
- Several low-resource language names have limited Russian reference standardization in common sources: `Chibarwe`, `Kwangali`, `Norfuk`, `Upper Guinea Creole`, and `Tonga`. Their labels are careful Russian renderings of the source entities, not a claim of a uniquely mandated Russian exonym. A specialist terminology review may refine them without changing data identity or coverage.

No clinical, political-status, or factual-country assertion is added by this work. This is ready for independent localization review, not publication or integration acceptance.
