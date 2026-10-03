# Content20 independent review

Task `quiz_master-8k1.16`; reviewer label `fact-content20`; reviewed 2026-10-03. Target: 400 questions. None is accepted or published by this review.

## Scope and method

I solved `docs/rewrite-agents/content20/paintings-pilot10.candidate.json` before opening the key. My blind choices were 001 B, 002 A, 003 C, 004 D, 005 A, 006 D, 007 C, 008 B, 009 D and 010 C; each matches the proposed key. I then read the private key, rendered legacy pack and primary/institutional collection records. Targeted duplicate searches covered Russian and English work titles plus the artists/answer facts in `quizzes/`; the only related existing item is a different knowledge point: `quizzes/Philology/vocabulary_art_culture.json` asks about *Mona Lisa* and sfumato. No rephrased duplicate was found.

## Item verdicts

| ID | Verdict | Evidence and concrete disposition |
|---|---|---|
| 001 | REVISE | The Louvre PDF identifies Lisa Gherardini as Francesco del Giocondo's wife and the sitter. Answer/options/explanation are sound, but Russian question wording `На чьё лицо ... написана` is unidiomatic. Use `Чьё лицо, согласно идентификации Лувра, изображено на «Моне Лизе»?`; preserve B. |
| 002 | REVISE | Blind answer A is correct: the Prado collection entry says Felipe IV and Mariana of Austria are reflected in the mirror. The committed easy-read URL could not be opened (Cloudflare response); replace the private source with the current, opened Prado record: `https://www.museodelprado.es/coleccion/obra-de-arte/las-meninas/9fdc7800-9ade-48b0-ab8b-edee94ea877f`. No answer or option change. |
| 003 | REVISE | Rijksmuseum identifies Amsterdam's civic guard/militia and says Rembrandt was the first to paint a group portrait with its figures doing something; it says the captain orders the company to march and guardsmen form up. B/C/D remain unambiguous and C is correct. Replace the 19-word explanation (below the required 20) and avoid the stronger, unsupported `выступить в поход`: `Рейксмюзеум называет полотно групповым портретом городской стражи Амстердама. Рембрандт показал участников не неподвижно позирующими, а в действии: капитан велит начать марш, а стражники строятся.` |
| 004 | REVISE | D is correct. The opened Reina Sofía material states that the Republican government commissioned the work for the Spanish Pavilion at the 1937 Paris International Exposition. The committed URL redirects and ends 404 (`206_6_esp.pdf`); replace it with the accessible official record `https://www.museoreinasofia.es/sites/default/files/salas/informacion/206_06.pdf` (or the opened collection context `https://guernica.museoreinasofia.es/`). No factual rewrite is required. |
| 005 | ACCEPT | National Gallery explicitly describes the convex mirror as reflecting two men entering the room, one with a raised arm. A is uniquely best; the explanation keeps the visitors' identities appropriately unspecified. |
| 006 | ACCEPT | National Gallery says the elongated form resolves into a skull from the bottom-right viewing position; `справа` is a sufficiently broad but fair player-facing formulation. D is unique, and the memento-mori explanation is supported. |
| 007 | ACCEPT | National Gallery defines *wain* as the wooden wagon for cut and dried meadow grass; C is exact. The explanation distinguishes the wagon from the mill, mowing and ford without overclaiming. |
| 008 | ACCEPT | Uffizi explicitly says the composition, despite its title, shows Venus arriving on Cyprus, born from sea spray and driven by Zephyr/possibly Aura. B is unique and the explanatory qualifier is retained. |
| 009 | REVISE | D is correct. The opened MoMA artist listing establishes `Saint Rémy, June 1889`, but it does not support the explanation's detail about a moving predawn sky. Replace the key's source with the opened individual collection record `https://www.moma.org/collection/works/79802`, which supports the Saint-Paul-de-Mausole setting, mid-June date and observed/imagined turbulent predawn sky. Keep D and the explanation. |
| 010 | REVISE | C is correct: the Art Institute archive identifies Dr B. H. McKeeby and Nan Wood as models, posing as a farmer and his unmarried daughter. Fix Russian grammar in the explanation: `Для «Американской готики» Вуд позвал...`, not `Вуд позвали...`. The committed asset could not be opened through Cloudflare; replace private source with opened institutional archive `https://archive.artic.edu/homer_exhb/assets/Rsrc_001087.pdf`. |

Result: **0/10 accepted as a pack; revisions are required for 001, 002, 003, 004, 009 and 010.** This is an editorial fact/source verdict, not schema acceptance, import approval, publication or release. Re-review only those changed records after the writer supplies a new frozen candidate/key/legacy hash.

## Final targeted re-review — ACCEPT

Re-review ran after the author/root supplied a new frozen candidate, key and legacy file. The shared host broker queued the requested interactive lease as `OLDER_REQUEST_WAITING`; it was released without use. Root then confirmed path quiescence and the user explicitly authorized this bounded sequential, non-lease re-review. No resource grant is claimed, and no foreign request or process was changed.

| ID | Final verdict | Re-review evidence |
|---|---|---|
| 001 | ACCEPT | Candidate now uses the clear Russian wording `Чьё лицо ... изображено`; B remains Lisa Gherardini, supported by the already-opened Louvre PDF. |
| 002 | ACCEPT | A remains correct; the private record now points to the opened stable Prado collection record for the reflected Felipe IV and Mariana of Austria. |
| 003 | ACCEPT | C remains uniquely correct. The 24-word explanation now says the captain starts a march and guardsmen form up, matching Rijksmuseum rather than claiming a campaign. |
| 004 | ACCEPT | D remains correct; private source now uses the opened current Reina Sofía PDF (`206_06.pdf`). |
| 005 | ACCEPT | Unchanged; National Gallery evidence supports the two entering men in the mirror. |
| 006 | ACCEPT | Unchanged; National Gallery evidence supports skull/anamorphosis from the right-side viewing position. |
| 007 | ACCEPT | Unchanged; National Gallery defines *wain* as the hay wagon. |
| 008 | ACCEPT | Unchanged; Uffizi identifies the arrival on Cyprus, not the birth itself. |
| 009 | ACCEPT | D remains correct; the private source now points to MoMA's opened individual collection record, which supports the Saint-Rémy, June 1889 and moving predawn-sky explanation. |
| 010 | ACCEPT | C remains correct; `Вуд позвал` fixes the Russian agreement and the private source now points to the opened Art Institute institutional archive. |

**FINAL ACCEPT — editorial fact/source review only.** All ten current records are accepted for the next lead-owned structural-validation/import gate. This is not a schema pass, integration acceptance, publication or release.

Current frozen-input SHA-256:

- `paintings-pilot10.candidate.json`: `B3661E20E5E7FBEDB88A92939EA0905CCF6A1E760D06369066E04477AF28FB9F`
- `paintings-pilot10.key.json`: `867117CD97697ECA884894A8FAE205FF0F342E83A265A0768E8A8ABC731A32D3`
- `paintings-pilot10.legacy.json`: `9BFCEED765208923DDD8EFFF54C82FE04C0E8471C39C4F3842E7176C32186DD2`
- `render_paintings_pilot10.py`: `0089BEB3F4A59D95260E3FFE327CF831DB1582C78FDE732F9E57832D7E422E3A`

Fresh check: `python docs/rewrite-agents/content20/render_paintings_pilot10.py --check` returned `OK: 10 unique choice questions, distinct options, explanation lengths, saved legacy parity`. The rechecked explanation counts are 24–28 words (003 is now 24).

## Source-check notes

- 001: Louvre exhibition PDF, pp. 83–84: Lisa Gherardini / Francesco del Giocondo.
- 002: Museo del Prado *Las meninas* collection record: mirror reflects Felipe IV and Mariana of Austria.
- 003: Rijksmuseum *The Night Watch* object record: Amsterdam civic guard, captain starts march, company forms up.
- 004: Museo Reina Sofía current Guernica material: government commission for Spanish Pavilion, Paris 1937.
- 005–007: National Gallery object records for *Arnolfini Portrait*, *The Ambassadors* and *The Hay Wain*.
- 008: Uffizi *Birth of Venus* record: arrival on Cyprus, not the birth scene itself.
- 009: MoMA individual collection record for *The Starry Night*.
- 010: Art Institute of Chicago institutional archive, *Grant Wood: American Gothic*.

## Local integrity checks

- `python docs/rewrite-agents/content20/render_paintings_pilot10.py --check` — `OK: 10 unique choice questions, 4 options each, legacy fields present`.
- Read-only comparison of `render()` with the committed `paintings-pilot10.legacy.json` — `LEGACY_RENDER_MATCH=True`; 10 questions and ten four-option arrays. This checks actual object parity, which `--check` alone does not.
- Explanation whitespace-token audit found 003 at 19 words; all other records were 24–28 words.

Frozen-input SHA-256:

- `paintings-pilot10.candidate.json`: `013C0FD28471A655F666242D5EECA764D912042A29C1669EB68D174659793A03`
- `paintings-pilot10.key.json`: `23F42F99321128B1496F6EFB6905B74315DA50F28F9E2492A70D84E113CFAD5F`
- `paintings-pilot10.legacy.json`: `87C4DDA28C1FC135355A390F6FDBFD5C5E00A733D85EB081BF811F4ACF692129`
- `render_paintings_pilot10.py`: `4DD339B5F9990FD7E47E1072ACEB1CC2850573402062DF6D9FE72E3B8F663BE3`
