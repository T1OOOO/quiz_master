# Quizipedia independent fact and source review

**Reviewer:** `fact-quizipedia-20261005`
**Reviewed draft:** `quizipedia/content.json`, SHA-256 `538be523d565be18d82efa9cf348fe083c9f66ea57ce96c15a289cdbf948127`
**Source revision observed:** `e802ed21db936bdb9809bab2d137903eb0aa425e`
**Date:** 2026-10-05
**Scope:** facts, source relevance, selected HYG memberships/line patterns, and named Commons file provenance. This is review evidence only; it neither imports assets nor publishes content.

## Method and limits

I first derived the answers from the target labels, HYG star IDs and the Commons depictions, before comparing the draft's names and explanations. I then opened the cited NCI/SEER, official-monument/UNESCO, IAU, and Commons file pages themselves. I did not use search-result text as evidence.

The draft has no target coordinates or acquired visual assets at this review point. `asset_visual_alignment: NOT_CHECKED`; hotspot/landmark visual alignment and all coordinate claims remain for review after the actual assets and coordinates exist. This is deliberately not a blanket license decision.

## Country target binding — 20 scoped items

All 20 ISO-2 values occur exactly once in the project 195-country registry (`docs/rewrite-agents/preparation-country-registry/countries.json`, dated 2026-10-03). The registry is the scoped identity source; geometry accuracy is outside this factual identity check and remains an implementation/asset gate.

| ISO-2 | Candidate-facing identity derived independently | Verdict | Source / clear fix |
|---|---|---|---|
| CA | Canada | ACCEPT | Project registry, `countries[].iso2`; bind to reviewed geometry before ship. |
| US | United States of America | ACCEPT | Same. |
| MX | Mexico | ACCEPT | Same. |
| BR | Brazil | ACCEPT | Same. |
| AR | Argentina | ACCEPT | Same. |
| CL | Chile | ACCEPT | Same. |
| AU | Australia | ACCEPT | Same. |
| CN | China | ACCEPT | Same. |
| IN | India | ACCEPT | Same. |
| JP | Japan | ACCEPT | Same. |
| EG | Egypt | ACCEPT | Same. |
| ZA | South Africa | ACCEPT | Same. |
| FR | France | ACCEPT | Same. |
| DE | Germany | ACCEPT | Same. |
| IT | Italy | ACCEPT | Same. |
| ES | Spain | ACCEPT | Same. |
| GB | United Kingdom of Great Britain and Northern Ireland | ACCEPT | Same. Keep the registry's canonical name in content; UI may use the product's approved short display name. |
| NO | Norway | ACCEPT | Same. |
| SE | Sweden | ACCEPT | Same. |
| MG | Madagascar | ACCEPT | Same. |

Check result: `map_targets=20`, `registry_matches=20`, no missing ISO code. The draft's `FRA -> FR` and `NOR -> NO` exceptions are necessary ISO-3-to-ISO-2 joins, not alternative country identities.

## Fixed J2000 learning patterns — 8 items

The selected 56 records are traceable to the pinned HYG v4.1 acquisition in `.run/quizipedia/text-acquisition.json` (commit `c7f7f883fe678cc7680169a50ccd7dcc49b060ce`, SHA-256 `d9f69fd86bbf90a4e4d52b4c5c53eacfa6dfc0bfdef85bfd94f095e0bebe4ebd`). Every draft star ID occurs in `.run/quizipedia/stars-source.json`; every segment endpoint is in its pattern's selected `star_ids` (`8` patterns, `56` source rows, `0` missing/non-target endpoints).

The IAU recognises constellation *areas* bounded in RA/Dec, rather than prescribing one stick figure: [IAU constellation explanation](https://www.iau.org/IAU/IAU/Astronomy-FAQs/Constellations.aspx?hkey=bb9dc841-0618-41b5-ac70-149741062141). Thus these verdicts approve the explicit editorial learning patterns only, with the required fixed-J2000/non-live-sky disclosure.

| ID | Independently resolved pattern | Verdict | Evidence / clear fix |
|---|---|---|---|
| `uma` | Big Dipper: Dubhe–Merak–Phecda–Megrez bowl and Megrez–Alioth–Mizar–Alkaid handle; all `UMa` in HYG. | ACCEPT | Correctly calls it part of Ursa Major, not the full IAU area. |
| `cas` | Caph–Schedar–Cih–Ruchbah–Segin W-like chain; all `Cas`. | ACCEPT | Educational zigzag wording is accurate. |
| `ori` | Orion outline with Meissa, Betelgeuse, Bellatrix, Rigel and Saiph; Mintaka–Alnilam–Alnitak are the belt; all `Ori`. | ACCEPT | Correctly identifies the belt and does not call it a boundary. |
| `lyr` | Vega with the Sheliak–Sulafat–Delta–Zeta Lyrae small quadrilateral; all `Lyr`. | ACCEPT | The stated brightest selected star is Vega (mag 0.03). |
| `cyg` | Northern Cross: Deneb–Sadr–Albireo long axis and Aljanah–Sadr–Fawaris crossbar; all `Cyg`. | ACCEPT | Sadr is the selected crossing star. |
| `cru` | Acrux–Gacrux long axis and Mimosa–Imai crossbar; all `Cru`. | ACCEPT | The two segments cross geometrically without a selected centre star, as explained. |
| `sco` | Acrab through Antares and curved tail to Shaula/Lesath; all `Sco`. | ACCEPT | The segment order follows the expected hooked teaching pattern. |
| `leo` | Regulus Sickle sequence plus Algieba–Chertan–Denebola body/tail sequence; all `Leo`. | ACCEPT | Regulus/Denebola explanation is accurate; preserve the explicit IAU-area caveat. |

## Anatomy facts — 6 items

| ID | Verdict | Primary evidence / clear fix |
|---|---|---|
| `thyroid` | ACCEPT | [NCI SEER thyroid](https://training.seer.cancer.gov/anatomy/endocrine/glands/thyroid.html) places two lobes on the sides of the trachea below the larynx and identifies thyroid hormones. The concise metabolism wording is appropriate. |
| `thymus` | ACCEPT | [NCI SEER thymus](https://training.seer.cancer.gov/anatomy/lymphatic/components/thymus.html) places it posterior to the sternum and describes T-lymphocyte processing/maturation. |
| `adrenals` | ACCEPT | [NCI SEER adrenal](https://training.seer.cancer.gov/anatomy/endocrine/glands/adrenal.html) gives one gland near each kidney, outer cortex/inner medulla, distinct hormone secretion and cortisol. It also supports the epinephrine statement in its medulla discussion. |
| `pancreas` | ACCEPT | [NCI SEER pancreas](https://training.seer.cancer.gov/anatomy/endocrine/glands/pancreas.html) places it on the posterior abdominal wall and says pancreatic islets secrete insulin and glucagon in response to blood glucose. “Upper abdomen” is a non-misleading learner-level location. |
| `ovaries` | ACCEPT | [NCI SEER ovaries](https://training.seer.cancer.gov/anatomy/reproductive/female/ovaries.html) places the two ovaries one on each side of the uterus in the pelvic cavity; [NCI SEER gonads](https://training.seer.cancer.gov/anatomy/endocrine/glands/gonads.html) supports estrogen/progesterone endocrine function. Consider replacing the one draft `source_url` with the ovaries page, which covers both location and egg development more directly. |
| `testes` | ACCEPT | [NCI SEER testes](https://training.seer.cancer.gov/anatomy/reproductive/male/testes.html) places them in the scrotum; [NCI SEER gonads](https://training.seer.cancer.gov/anatomy/endocrine/glands/gonads.html) identifies testosterone secretion. Consider the testes URL as the item source because it covers the location directly. |

### Anatomy image provenance, separately verified

The selected no-label source is [Human endocrine male & female svg no labels.svg](https://commons.wikimedia.org/wiki/File:Human_endocrine_male_%26_female_svg_no_labels.svg), not current OpenStax textbook content. Its Commons record says it is a modified/extended OpenStax work, dates it **13 September 2020**, identifies **OpenStax, Tomáš Kebert and umimeto.org**, and grants **CC BY-SA 4.0**. The file history has a single current upload at that date. This original artifact grant supports its provenance record; the factual explanations above are original paraphrases and do not redistribute the current textbook edition. Record that exact file URL, author string, date, CC BY-SA 4.0 URL and any modification in the final asset manifest.

## Landmark facts and individual Commons files — 6 items

| ID | Verdict | Fact evidence | Commons depiction, creator, license, and clear fix |
|---|---|---|---|
| `colosseum` | ACCEPT | [Parco archeologico del Colosseo](https://colosseo.it/en/area/the-colosseum/) calls it the Flavian Amphitheatre/Colosseum in Rome. | [File page](https://commons.wikimedia.org/wiki/File:Colosseum_2010_Rome.jpg) describes a Colosseum view in Rome, credits **Jacob Truedson Demitz for Ristesson**, and records public-domain dedication/VRT permission. Keep the full attribution currently drafted. |
| `taj-mahal` | ACCEPT | [UNESCO](https://whc.unesco.org/en/list/252/) locates it in Agra and says Shah Jahan built it in memory of Mumtaz Mahal. | [File page](https://commons.wikimedia.org/wiki/File:Taj_Mahal_frontal.jpg) says frontal Taj Mahal, own work by **Marsmux**, **CC BY-SA 4.0**. Draft attribution is correct. |
| `giza-pyramid` | ACCEPT | [UNESCO](https://whc.unesco.org/en/list/86/) identifies the Giza-to-Dahshur pyramid-field property in Egypt; its description includes Cheops/Khufu's pyramid. | [File page](https://commons.wikimedia.org/wiki/File:Great_Pyramid_of_Giza.jpg) identifies the Great Pyramid, own work by **kallerna**, **CC BY-SA 3.0 Unported** (also GFDL). Draft attribution/license are correct. |
| `petra-treasury` | REVISE | [UNESCO](https://whc.unesco.org/en/list/326/) identifies Petra as the Nabataean rock-cut capital in Jordan and explicitly lists the Khasneh among its rock-cut facades. | [File page](https://commons.wikimedia.org/wiki/File:Sight_of_Al_Khazneh_(The_Treasury)_in_Petra.jpg) depicts the Treasury in Petra, Jordan, but credits **Boris Debic**, not `Bravodeltamedia`; it is **CC BY-SA 4.0**. Change only `creator` to `Boris Debic` before import. |
| `sydney-opera` | ACCEPT | [UNESCO](https://whc.unesco.org/en/list/166/) places it on Sydney Harbour, records 1973 opening, shell groups and Jørn Utzon's 1957 design award. | [File page](https://commons.wikimedia.org/wiki/File:Sydney_Opera_House.jpg) depicts the Sydney Opera House, own work by **Michael elwazer**. It offers CC BY-SA 4.0 (plus earlier CC BY-SA choices and GFDL); the draft's selected **CC BY-SA 4.0** is valid. |
| `eiffel` | ACCEPT | [Société d’Exploitation de la Tour Eiffel](https://www.toureiffel.paris/en/the-monument/history) says the 1889 World's Fair motivated the tower and records completion on 31 March 1889. | [File page](https://commons.wikimedia.org/wiki/File:Eiffel_Tower_from_the_Tuileries_Garden.jpg) describes the Eiffel Tower in Paris from the Tuileries, own work by **DiscoA340**, **CC BY-SA 4.0**. Draft attribution/license are correct. |

## Outcome and remaining gate

**Content verdict: DONE_WITH_CONCERNS.** The factual claims and eight editorial sky patterns are acceptable. One required content metadata revision exists: `petra-treasury.creator = "Boris Debic"`. The two suggested anatomy source URL tightenings are source-quality improvements, not factual blockers.

Before publication, the integrator still needs to acquire the named artifacts, write their manifest entries (original URL, acquisition date, exact checksum, creator, license/version and attribution), apply the Petra credit correction, and request a targeted review of actual image/hotspot alignment. Nothing here approves a missing asset, coordinate, app behavior, manifest, import, or publication.

## Addendum — actual acquired asset and alignment review (2026-10-05)

**Verdict: ACCEPT for the reviewed actual assets.** This supersedes the earlier
`asset_visual_alignment: NOT_CHECKED` limitation only for the files and
coordinates listed here. It does not evaluate the frozen renderer or any
runtime interaction.

### Reviewed inputs and integrity

| Input | SHA-256 |
|---|---|
| `quizipedia/hotspots.json` | `30ef29714be8aeb2ba47e33b7cdd786250d90ae54671480717804a0f7b6e3fc0` |
| `quizipedia/images-manifest.json` | `39e2f7987bb6b7fb005ca58d553b33748b184e54aa4cf0bd83705d8553c2b38d` |
| `assets/quizipedia/catalog.json` | `3799945addf40643c4a8fed9aebe09d142e3df4bb2656b1cfffe1a92d6814460` |
| `assets/quizipedia/endocrine.png` (960 × 922) | `34f7a2f8c0fdb3ddd836974ca5aaffe4b2df07dcd5d2b11e11e95c333c0a71f8` |

The local `endocrine.png` was viewed at original size. It is the unlabelled
two-body endocrine diagram with contextual enlarged head/thyroid insets. The
reviewed selectable centres are on the body drawings, never the insets. Each
of the 14 catalog hotspots equals the recorded pixel centre divided by 960 ×
922; its radius equals the recorded pixel radius divided by 922. Automated
comparison found `0` mapping mismatches.

| Target | Reviewed body pixel centres `(x, y; r)` | Visual verdict |
|---|---|---|
| Thyroid | `(225,359;18)`, `(745,316;18)` | ACCEPT — each centre is on the neck thyroid, below the larynx. |
| Thymus | `(225,417;19)`, `(744,379;19)` | ACCEPT — each centre is on the upper-chest thymus. |
| Adrenals | `(177,580;13)`, `(250,575;13)`, `(685,573;13)`, `(778,568;13)` | ACCEPT — all four centres are on the paired yellow suprarenal structures. |
| Pancreas | `(235,611;25)`, `(751,609;25)` | ACCEPT — each centre lies on the pancreas, not a kidney. |
| Ovaries | `(178,745;12)`, `(251,745;12)` | ACCEPT — both centres lie on the left/right ovaries beside the uterus. |
| Testes | `(725,828;13)`, `(747,828;13)` | ACCEPT — both centres lie on the depicted testes. |

No coordinate correction is required. The catalog now points ovaries to the
specific primary [NCI SEER ovaries page](https://training.seer.cancer.gov/anatomy/reproductive/female/ovaries.html), which supports its location and function. The retained gonads page for testes supports its endocrine/testosterone statement; the companion [NCI SEER testes page](https://training.seer.cancer.gov/anatomy/reproductive/male/testes.html) supports the scrotal location.

### Landmark depiction and provenance

I visually inspected all six bundled photographs. Each depicts its named
landmark and matches the catalog's country/city binding: Colosseum/Rome,
Taj Mahal/Agra, Great Pyramid/Giza, Al-Khazneh/Petra, Sydney Opera House/Sydney,
and Eiffel Tower/Paris. **All six: ACCEPT.**

For all six JPEGs and the endocrine PNG, a fresh SHA-256 recomputation exactly
matches `images-manifest.json`; the local
`quizipedia/sources/endocrine.svg` also exactly matches the manifest's
`original_sha256` (`443bba4172e0f912156d5cf27681198ffdc402c6b0b9f17771f6dbfebebd9bde`).
The manifest/catalog credits now agree with the earlier per-file Commons review:

* Petra credits **Boris Debic**, CC BY-SA 4.0, with the original Commons file URL.
* Colosseum credits Jacob Truedson Demitz for Ristesson (public domain); Taj Mahal Marsmux (CC BY-SA 4.0); Great Pyramid kallerna (CC BY-SA 3.0); Sydney Opera House Michael elwazer (CC BY-SA 4.0); and Eiffel Tower DiscoA340 (CC BY-SA 4.0).
* The endocrine entry retains the 2020 no-label Commons artifact attribution to OpenStax, Tomáš Kebert and umimeto.org under CC BY-SA 4.0, with the exact original SVG and raster source URLs.

No source, creator, license, or coordinate rework remains from this review.
