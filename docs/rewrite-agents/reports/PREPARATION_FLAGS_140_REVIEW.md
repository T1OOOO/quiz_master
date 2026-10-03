# Independent flags-140 review — `review-flags140-oct3`

Status: ACCEPT (scoped final re-review). The following independent visual solve covers exactly the final 60 candidate records and was recorded before opening the editorial key, legacy JSON, coverage, source ledger or generator.

| ID | Blind visual identification |
|---|---|
| flag-2830f6d | Ghana |
| flag-59dc0ab | Guyana |
| flag-5f83494 | Honduras |
| flag-908bcb0 | Croatia |
| flag-0b23a99 | Haiti |
| flag-d83d151 | Hungary |
| flag-2273ba7 | Indonesia |
| flag-c8156b6 | Ireland |
| flag-b48f680 | India |
| flag-60ad414 | Iraq |
| flag-2f75af0 | Iran |
| flag-f07c93d | Jamaica |
| flag-93aa222 | Jordan |
| flag-864af9b | Kenya |
| flag-8015243 | Kyrgyzstan |
| flag-4087089 | Cambodia |
| flag-399aef5 | Kiribati |
| flag-a5e30c7 | Comoros |
| flag-b522c47 | Saint Kitts and Nevis |
| flag-5e88446 | Democratic People's Republic of Korea |
| flag-f4bc5b3 | Republic of Korea |
| flag-de82358 | Kuwait |
| flag-d596fbb | Kazakhstan |
| flag-2070771 | Lao People's Democratic Republic |
| flag-b7b264c | Lebanon |
| flag-7799254 | Saint Lucia |
| flag-d81f71a | Liechtenstein |
| flag-7ca139d | Sri Lanka |
| flag-cef180f | Liberia |
| flag-00b72e2 | Lesotho |
| flag-e238cf5 | Luxembourg |
| flag-54bef01 | Libya |
| flag-be4ed17 | Morocco |
| flag-283b7ce | Singapore |
| flag-c9151fc | Republic of Moldova |
| flag-fa33ffe | Montenegro |
| flag-6ac2ed2 | Madagascar |
| flag-8136ff6 | Marshall Islands |
| flag-864d917 | North Macedonia |
| flag-31a78d8 | Mali |
| flag-5b75a14 | Myanmar |
| flag-9423f07 | Mongolia |
| flag-3eb32d3 | Mauritania |
| flag-1851b6b | Malta |
| flag-17f079e | Mauritius |
| flag-610f5e1 | Maldives |
| flag-4ab001e | Malawi |
| flag-43e8d11 | Mexico |
| flag-2de104f | Malaysia |
| flag-669cbc5 | Mozambique |
| flag-184eefd | Namibia |
| flag-b69b6e6 | Niger |
| flag-b6d02f4 | Nigeria |
| flag-a3a9dc7 | Nicaragua |
| flag-28c434e | Netherlands |
| flag-d7a022b | Nepal |
| flag-dc6e2fb | Nauru |
| flag-7e6e828 | New Zealand |
| flag-afc0f1c | Oman |
| flag-edb8eac | Panama |

## Current frozen-140 verdict — REVISE

The 60 final additions were all visually inspected before the key was opened. Apart from the four precise option-set defects below, their intended answers match the rendered PNGs, explanation features and Flagpedia source identities. My blind `flag-2830f6d` selection was Ghana; the image/key correctly identify Guinea-Bissau, so that independent solve miss is not an author defect.

| ID | Verdict | Concrete required correction |
|---|---|---|
| flag-2273ba7 | REVISE | Indonesia is the intended answer, but Monaco is an option. The two red-over-white flags are not safely distinguishable here; replace Monaco. |
| flag-283b7ce | REVISE | Singapore itself is clear, but Indonesia and Monaco occur together as shade-only near-duplicate distractors. Remove one to comply with the packet's no-unanswerable-pair rule. |
| flag-e238cf5 | REVISE | Luxembourg is paired with the Netherlands; the claimed distinction is only the blue shade. Replace the Netherlands option. |
| flag-28c434e | REVISE | Netherlands is paired with Luxembourg; the claimed distinction is only the blue shade. Replace the Luxembourg option. |

Every other final-60 ID in the blind table is ACCEPT for current factual image/answer/explanation review. The previously accepted 80 were not re-reviewed beyond preservation/parity checks, per the scoped handoff.

## Frozen correction re-review

The author corrected the four records above without moving their correct-answer
positions, then froze the bank. I re-read their candidate blocks, corresponding key
rows and legacy records. All four now have a single visually distinguishable intended
answer:

| ID | Final intended answer | Re-review result |
|---|---|---|
| flag-2273ba7 | Indonesia (A) | ACCEPT — Monaco removed; Singapore is distinguishable by crescent/stars, Japan by its white field and Poland by reversed stripe order. |
| flag-283b7ce | Monaco (D) | ACCEPT — Indonesia removed; Singapore, Japan and Poland are independently distinguishable. |
| flag-e238cf5 | Luxembourg (A) | ACCEPT — Netherlands removed; Germany, France and Croatia do not rely on an imperceptible shade distinction. |
| flag-28c434e | Netherlands (A) | ACCEPT — Luxembourg removed; Germany, France and Croatia do not rely on an imperceptible shade distinction. |

The Romania/Chad guard cases were also retained as feature-based questions rather
than shade-only pairs: Andorra is separated from Romania by its central arms and
Barbados from Chad by its trident/blue-yellow-blue layout. No new ambiguity was
found in those preserved records.

### Supplement: exact two additional guard replacements (hub #363)

The preceding four-record acceptance was deliberately narrow. The author then
identified the two additional changed IDs, rather than leaving them to inference:
`flag-d48e7a1` and `flag-c9151fc`. I inspected their final candidate blocks, key
rows, legacy fields and the actual SHA-named PNGs before extending the verdict.

| ID | PNG / visual result | Candidate/key/legacy result | Verdict |
|---|---|---|---|
| flag-d48e7a1 | `c5703c9d…d88ee77`: white-above-red Poland. Indonesia is the inverse order; Japan has a disc; Austria has three stripes. | Poland remains A; its options and two-feature explanation agree in all three representations. | ACCEPT |
| flag-c9151fc | `56fa6191…5a1015e`: Moldovan blue-yellow-red tricolour with central arms. Romania lacks arms; Andorra and Belgium remain distinguishable alternatives. | Moldova remains C; candidate, key and legacy options/explanation agree. | ACCEPT |

The displayed full SHA-256 values match both local PNG bytes and their opaque legacy
media URIs: `c5703c9d89f1d04249636445d6a5b7304f53138c226219f4f4e43dae6d88ee77`
and `56fa6191a71cc860faf7f1bb29d0f36b281731e5e045ce4e6d2229a1e5a1015e`.
Therefore the **ACCEPT** above now covers all six corrected records, not only the
initial four. It remains a review verdict, not a publication claim.

Scoped integrity checks on the frozen output: legacy has 140 unique IDs, every
record uses `type: "choice"`, a four-item options array, `media` as an array with
`kind: "image"` and an opaque HTTPS media URI; coverage retains the intended
positions and legacy has A/B/C/D = 35/35/35/35. Candidate, key and legacy agree for
the four revised IDs; their image SHA-256 and source URLs were not changed. This
acceptance covers the corrected four plus the already-reviewed final 60 and
preservation of the earlier accepted 80; it does not assert publication.

Frozen inputs:

- `candidate.md` `b7894ecd243a8112d8216869aff4e6f2a9c10e0a342950b7caca3880b5aeda6e`
- `editorial-key.md` `69d3c46de48cba5628e86d165b1e7a4bd60c8028f9c61e6096f2e2ab348a68f8`
- `legacy.json` `b4f6717d49f8cd0357b8e99b5d9d61b1d3820319cdcaa11d9254a7876b4320ec`
- `coverage.md` `a71246cd6e5d8e717ba3389477db16f5f4ca2b4b13b4908c41345c5b8e92e278`

### Current evidence

- Read-only structural/media check: 140 unique legacy IDs, 140 candidate blocks, key rows and coverage mappings; A/B/C/D = 35/35/35/35; 0 schema, local PNG-SHA, media-shape, candidate, coverage or answer-position mismatches. New-60 explanations are 21–35 Russian words and the source/feature claim is carried into its key row.
- Read-only reconstruction from `expand80.py` of all final 60 gave 0 ID, option order, answer index, explanation or opaque media-URI mismatches. It appends only from 80 and is a no-op at 140; it was inspected/imported but not run to write files.
- All 140 legacy SHA URIs match the frozen Flagpedia ledger by ISO2, except the deliberate one AF Commons override. I viewed the AF override directly: white field with black inscription; its current stem/key say de-facto authorities and do not make a diplomatic-recognition claim.
- I also viewed the current local Syria provider PNG separately: green/white/black with three red stars, matching the ledger's 2025 UN-representation note. Syria is not among the 140 records, so this is source-readiness evidence, not an answer-key claim.
- Flagpedia is the recorded visual provider; its local ledger binds exact download URL/SHA and the documented provider attribution. It should not be read as a universal diplomatic-representation assertion. The four option-set defects above remain a pedagogical ambiguity independent of source integrity.

| Current frozen input | SHA-256 |
|---|---|
| candidate.md | `c533ca9ce716226963e87d8794348bbc0ce71bd79b3447c6663bd4c6655c56c0` |
| editorial-key.md | `c55ab890840c674b0d91009a6bf491cc216b3bd44692cc82313c18a94b49777a` |
| legacy.json | `a49453de8eae4b4f76aadf1b2d826fb71721941662cfc45cb8f062f5addc837e` |
| coverage.md | `a71246cd6e5d8e717ba3389477db16f5f4ca2b4b13b4908c41345c5b8e92e278` |
| expand80.py | `85258f9126bf570ba888dd45c10e4e954a7e4c6b0942c39ba93b31f885124053` |

No source, draft, generator or production file was modified. This REVISE report is not acceptance, import, publication or release evidence.
