# Pets next 100 annotation report

- Scope: exactly the 100 `quiz` identities in `PETS_NEXT100_IDS.json`, split across five frozen cat packs (4, 28, 28, 27 and 13 records).
- Source revision: `e802ed21db936bdb9809bab2d137903eb0aa425e`.
- Taxonomy reference: `qm-tags-v1` / `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`.
- Method: every assigned record was read with its stem, all options, keyed index and explanation. Scores are independent editorial estimates for Russian adult general-quiz players; no old difficulty field, filename rule, quota or default score was used.
- Tags: every record has `domain:nature` and a specific existing cat topic. Countries are private editorial tags only where the keyed fact actually identifies that country. Context tags are safe subsets and never disclose an answer-only entity.
- Annotation SHA256: `e502a3442b25c7786069a28955a0b9a6e737fe48da842f8510527fbc3dd58177`.
- Difficulty distribution: `1=1, 2=8, 3=17, 4=14, 5=18, 6=18, 7=14, 8=10`; no 9 or 10. Confidence: high 33, medium 43, low 24. Seventy-four records are flagged and 60 request factual review.

## Frozen source hashes

| Pack | SHA256 |
| --- | --- |
| `cats_biology_senses_part_1` | `f0ad137e80ed6f4ffdd7e5e96012bcc9a4418c46972a77f2ad65a54503df903c` |
| `cats_biology_senses_part_2` | `74c17410f4b97197f3b34369fc67956ae9af3d6f840eeb142df4f7ca5d43fb4f` |
| `cats_biology_senses_part_3` | `b4a34a7023d57a934f37c04dba97cee1066e2484fcf86cf458c7a07506630e96` |
| `cats_biology_senses_part_4` | `fe1dad688d48d8b7dc0d2727398d51212d5266d4f444a95baaa803e4f36e2b89` |
| `cats_breeds_man_made` | `4ad6a80bf33b7128bd952142a7a326e47dd2a60183a869575bad6d56737a9e84` |

## Review queue and vocabulary gaps

- Independent factual review is required for every `factual-review-needed` entry, particularly the claimed jaw movement, toxic-food uniqueness, unsupported `psi-travel`, local cat-island and museum statistics, record claims, and current popularity claim.
- The vocabulary has no precise existing topic for veterinary/toxicology, feline nutrition, internet culture, historical spaceflight, or records. Those facets are not forced into an unrelated closest tag. `topic:cat` plus the accurate available specific animal topic or culture topic is used instead.
- `q_nature_cats_anatomy_cat_208`, `q_nature_cats_history_culture_cat_262`, `q_nature_cats_breeds_cat_348`, and `q_nature_cats_history_culture_cat_340` have private ambiguity or answerability flags; their estimated difficulty does not certify factual correctness.

No source stem, options, answer indexes, explanations, or raw quiz files were modified. This is a review-ready annotation artifact, not publication or acceptance evidence.
