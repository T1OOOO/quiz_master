# BELIEFS_A0IZ independent fact review

**Reviewer:** `belief-fact-review-A0IZ` (Codex / gpt-6.1-sol)
**Reviewed revision:** `5821083efdefdf33c6b8caf03641820c6418a6e5`
**Candidate SHA-256:** `CF8E09F18124AC727D8E501753C19401C8D1F75969092479DEBC9E49201124E2`
**Verdict:** **REVISE (two localized Russian wording repairs); factual keys and graph otherwise pass this review.** This is review evidence only; it is neither canonical import nor publication approval.

## Method and structural result

The candidate embeds `correct_id`, so a strictly blind solve against a separately held private key was not possible. I treated the sources and stated wording as the independent check, then assessed whether the displayed key is the sole defensible option. All 13 cited HTTPS pages were directly opened on 2026-10-19; every source reference resolves to a declared source ID.

The candidate has 30 nodes (21 Greek, 9 religions), 32 edges (27 Greek, 5 religion), and 20 questions (11 Greek, 9 religions). Every question has four unique in-section options and contains its correct ID exactly once. It meets the frozen count targets. The coverage note accurately says this is a teaching selection, does not make a universal Greek genealogy, and does not present traditions as one descent tree.

## Source evidence and graph review

- **Hesiod / Theogony:** The opened text supports Chaos first (116), Gaia's bearing of Uranus and the Titan generation (126–134), Aphrodite's sea-foam emergence after Uranus's castration (188–206), the Rhea/Cronus children (453ff.), and Zeus/Demeter/Persephone (912). The version qualifiers are appropriate.
- **Homeric Hymns:** The opened texts support Poseidon as god of the sea (Hymn 22), Artemis as Apollo's arrow-loving sister (Hymn 9), Hera as Zeus's sister and wife (Hymn 12), Demeter and daughter Persephone (Hymn 13), and Hymn 2's abduction narrative. The reciprocal Hera–Zeus and Apollo–Artemis edges are supported. The Hades–Persephone edge remains pedagogically acceptable only because its scope explicitly retains the abduction context; do not shorten that scope during integration.
- **Met Museum overview:** Directly supports Athena's owl/olive, Apollo's kithara, Hermes's winged sandals and kerykeion, and the roles for Dionysus and Hephaestus.
- **Religions:** Harvard Pluralism pages directly support the Judaism triad, Christianity's three broad contemporary branches, four Vedas, and Buddhist Middle Way/Four Noble Truths/Eightfold Path. Quran.com 2:177 supports prayer and *alms-tax*; Sikh Coalition supports the Guru Granth Sahib's ultimate authority and central placement; Jainpedia supports ahiṃsā and interconnection of life; Jinja Honcho supports its stated Shinto description; the official Bahá’í site supports its Reference Library and the expressly self-described Manifestations links.
- **Religion scope:** The five Bahá’í outward links are correctly attributed to Bahá’í self-description and explicitly deny a genealogical reading. This is a defensible, limited relationship representation. The representation is not a comparative history of the traditions and should retain the existing coverage note.

## Per-question verdicts

| Question | Independent source result and answer uniqueness | Verdict |
|---|---|---|
| `greek_q_01_sea` | Hymn 22 calls Poseidon god of the deep/sea; only Poseidon fits. | ACCEPT |
| `greek_q_02_kithara` | Met associates the kithara with Apollo; options are fair. | ACCEPT |
| `greek_q_03_owl` | Met names owl and olive as sacred to Athena; only Athena fits. | ACCEPT |
| `greek_q_04_messenger` | Met gives Hermes winged sandals, kerykeion and messenger role. | ACCEPT |
| `greek_q_05_artemis` | Hymn 9 supports Artemis. Repair RU grammar: replace `названа кто?` with `кто назван?` (or recast as `Кто назван сестрой Аполлона…?`). | REVISE |
| `greek_q_06_chaos` | *Theogony* 116 starts this account with Chaos; source/version is explicit. | ACCEPT |
| `greek_q_07_aphrodite_hesiod` | *Theogony* 188–206 supports Aphrodite; Hesiod qualifier resolves genealogy ambiguity. | ACCEPT |
| `greek_q_08_hera_hymn` | Hymn 12 explicitly says Hera is sister and wife of Zeus. | ACCEPT |
| `greek_q_09_persephone` | Hymn 13 names Demeter and daughter Persephone; only Persephone fits. | ACCEPT |
| `greek_q_10_metalworking` | Met calls Hephaestus god of metalworking. | ACCEPT |
| `greek_q_11_dionysus` | Met calls Dionysus god of wine and theater. | ACCEPT |
| `religion_q_01_torah` | Harvard's interdependent God/Torah/people Israel triad is explicitly Judaism. | ACCEPT |
| `religion_q_02_christian_branches` | Harvard identifies Catholic, Orthodox and Protestant as broad contemporary Christianity branches; wording does not claim exhaustiveness. | ACCEPT |
| `religion_q_03_quran` | Qur'an 2:177 supports Islam and prayer/alms-tax. To preserve the source's precision, change RU `милостыня` to `закят` or `милостыня-закят` in stem and explanation. | REVISE |
| `religion_q_04_vedas` | Harvard lists Rig, Sama, Yajur and Atharva Vedas in Hindu traditions. | ACCEPT |
| `religion_q_05_dharma` | Harvard links all three teaching terms to Buddhism's Dharma; distractors do not jointly fit. | ACCEPT |
| `religion_q_06_granth` | Sikh Coalition states both ultimate authority and worship-space centerpiece. | ACCEPT |
| `religion_q_07_ahimsa` | Jainpedia links interconnected life with ahiṃsā in Jain beliefs/practices. | ACCEPT |
| `religion_q_08_shinto` | Jinja Honcho directly supports no founder/dogma/doctrine and kami veneration at jinja. | ACCEPT |
| `religion_q_09_bahai_library` | The worldwide Bahá’í community's official site calls its Reference Library authoritative. | ACCEPT |

## Supplemental country-religion data audit (root-owned; no edits made)

I inspected, but did not run, `import_pew.py` because running it writes the root-owned production asset. Static reproducibility checks passed: the local Pew archive SHA-256 is `39d1cf1b1dec28e22bc5e2a0e9ab958a8afdcdc971a79c175ff49d03e6ce8af6`, matching `country_religions.json`; the asset has 200 matched countries, one deliberately excluded Channel Islands aggregate, seven shares per country, and no share sum outside 100 ± 0.001.

The directly opened [Pew country table](https://www.pewresearch.org/religion/feature/religious-composition-by-country-2010-2020/) states it covers 201 countries/territories, uses estimates based on more than 2,700 censuses and surveys, and was published June 9, 2025. Its [methodology](https://www.pewresearch.org/religion/2025/06/09/global-religious-change-methodology/) confirms that the seven broad categories include Baha'is, Jains, Shintoists and Sikhs under `Other_religions`, and that unaffiliated includes atheist/agnostic and other no-religion identities. The asset's year, publication year, `Other_religions`, and non-official-status cautions are therefore accurate. This is a static audit, not a rerun/reproducibility acceptance of root-owned import code.

## Required repair and residual risk

Make the two identified Russian wording repairs, then recheck only `greek_q_05_artemis` and `religion_q_03_quran`. Residual content limitations are intentional: source aggregation is concise; the Quran card is one-verse-specific; and the religion graph carries a Bahá’í self-description rather than an independent comparative genealogy. Do not treat this report as final acceptance until the repairs are reviewed in the candidate revision.

## Repair recheck — 2026-10-19

**Current candidate SHA-256:** `94859807508313190BC035A2B5C3E01F60A7C80D3435FCA89ECB586CD8216969`

Both requested repairs are present and correct. `greek_q_05_artemis` now asks grammatically which goddess Hymn 9 calls Apollo's arrow-loving sister, retaining Artemis as the uniquely supported answer. `religion_q_03_quran` now uses `закят`, accurately reflecting Qur'an 2:177's alms-tax wording; Islam remains the uniquely supported answer. Question/node/edge counts remain 20/30/32.

**Final fact-review verdict: ACCEPT for the current candidate revision.** This accepts the reviewed factual content and repaired wording only. Canonical import, UI integration, publication, and any release decision remain outside this review.
