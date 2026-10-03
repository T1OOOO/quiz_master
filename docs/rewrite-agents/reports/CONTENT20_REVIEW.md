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

## Paintings20 frozen expansion — REVISE

Reviewed 2026-10-03. I read `paintings20.candidate.json` before its key. Blind choices were 001 B, 002 A, 003 C, 004 D, 005 A, 006 D, 007 C, 008 B, 009 D, 010 C, 011 A, 012 A, 013 A, 014 B, 015 B, 016 B, 017 C, 018 C, 019 D, 020 D. They match the current key. The current source records support the basic keyed facts: 1656 (*Meninas*), 1642 (*Night Watch*), tempera on canvas, 1434 (*Arnolfini*), June 1889, Flatford/River Stour, 1937, Florence as where Leonardo **began** the portrait, memento mori, and 1930.

**Full-bank verdict: REVISE. Do not import or publish this 20-item expansion.** The already accepted pilot facts in 001–010 are not re-opened here; they need no rewrite. The ten new records are not accepted as a group because:

- 015 asks for `июнь 1889`, which the stem of 009 already gives; 017 asks for 1937, which the stem and explanation of 004 already give; 019 asks for the memento-mori meaning already supplied by 006's explanation. Replace these, not merely reword them.
- 016 incorrectly calls Flatford a `город`; the cited record identifies a millpond at Flatford on the River Stour, not a city. 018 overstates its evidence: the Louvre says Leonardo **began** the portrait in Florence; it does not establish an unqualified `место создания`.
- 011 has 18 whitespace-token words and 014 has 19; both miss the required 20–45-word explanation range.
- 011–020 have boilerplate, identical private rationales for all three distractors (`Другой правдоподобный...`, etc.), rather than a rationale for each actual distractor as required by the packet.
- Correct positions in the current order are `1,0,2,3,0,3,2,1,3,2,0,0,0,1,1,1,2,2,3,3`: five of each position but runs of three at 011–013 and 014–016, exceeding the maximum run of two. The builder's `targets = [0,0,0,1,1,1,2,2,3,3]` is the direct cause in the added block.
- The additional questions rely too narrowly on the same ten works and mostly test bare dates/metadata. Replace all ten new records with distinct painting knowledge that does not leak from any other stem or explanation in this pack; preserve the accepted pilot semantics.

### Builder safety observation

`build_paintings20.py --check` has no argument parser or read-only check branch: importing/running it unconditionally regenerates `paintings20.candidate.json`, `paintings20.key.json` and `paintings20.legacy.json`. I invoked that command expecting a verification path before discovering the absence of `--check`; it may have deterministically rewritten those three frozen outputs. No pre-invocation SHA was captured, so byte non-mutation cannot be asserted. No further author-file operation was performed. Replace this with a separate read-only checker before another review.

The broker had queued an interactive lease as `OLDER_REQUEST_WAITING`; under the lead-confirmed user exception, this was a bounded sequential non-lease review. The queued lease was released and no foreign lock/process was touched.

Current post-observation SHA-256:

- `paintings20.candidate.json`: `7721C577116F476D4D8591C53363D221E39DE379289D89CF7A60E07C7B54D0F3`
- `paintings20.key.json`: `371AB4A3CE3CE876C0516AEB698F6BE7A60A25232163E73C5EF7827933178115`
- `paintings20.legacy.json`: `7C858CFFD8FF6D6771C723AC25A03C004FFACEC386EBBD40971D84758591ED67`
- `build_paintings20.py`: `F2BC16FAB5C93D54946FF435C081F3A5E2110734E2C6157C0144716ADD689279`

## Paintings20 replacement extras — targeted re-review REVISE

I blind-solved revised 011–020 before opening the key: A, B, C, D, A, B, D, C, A, B. Those choices match the key. Opened institutional records support the base facts for Dalí (MoMA: oil on canvas), Vermeer (Mauritshuis: a *tronie*), Hokusai (Met: woodblock print), Delacroix (Louvre: July 1830), Klimt (Belvedere: gold/silver/platinum), Magritte (MoMA: eye), and the basic Monet context. The 20-question bank is nevertheless **REVISE**, not accepted, for these exact remaining fixes:

| ID | Required revision |
|---|---|
| 011 | Explanation is 19 whitespace-token words; expand to 20–45 with a source-backed detail. The answer and MoMA record `https://www.moma.org/collection/works/79018` are sound. |
| 015 | `Какой предмет стал сюжетом` is grammatically/semantically weak: the keyed answer is a figure, not a предмет, and the three alternatives are not parallel or plausible. Replace with a precise visual prompt, e.g. `Какой образ находится в центре композиции «Крика» Мунка?` and four parallel image descriptions. MUNCH’s opened page identifies a motif with several versions; do not overstate an unspecific collection page as a single-object record. |
| 018 | **Replace the question, not only its explanation.** `Гранд-Жатт` is supplied verbatim in the title, so the answer is a tautology. A source-backed replacement can ask `Какую технику применил Сёра в «Воскресенье на Гранд-Жатт»?` with `пуантилизм` as the keyed answer; the Art Institute’s official material explains adjacent pure-color points mixing in the viewer’s eye. Its explanation is also 19 words and must become 20–45. |
| 019 | Explanation is 18 words; the prompt `Какое впечатление стремился передать` is vague and inferential, while the cited collection overview is not a work record. Replace it with the concrete, source-backed question `Из окна какого города Моне написал «Впечатление. Восход солнца»?` → `Гавра` (Le Havre). Use the opened Musée Marmottan individual record `https://www.marmottan.fr/en/notice/4014/`, which identifies the hotel window, Le Havre outer harbour, early morning and the reason for the title. |
| 020 | The current source is a factual mislink: `https://www.moma.org/collection/works/78987` opens John Covert’s *Ex Act*, not Mondrian. Change it to the opened MoMA Mondrian record `https://www.moma.org/collection/works/80160`; it names *Composition in Red, Blue, and Yellow* and describes gridded lines distributing primary-colour blocks. Align the Russian title with that work and retain rectangles only if the explanation cites those rectilinear/gridded forms. |

011/012/013/014/016/017 have no new factual objection in this targeted pass, subject to the final corrected full-bank validation. The accepted pilot 001–010 remains unchanged. This is not structural validation, import approval, publication or release.

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

## Paintings20 final targeted re-review — ACCEPT

Reviewed 2026-10-03 after the five required corrections. I blind-solved the candidate before opening its key: 011 A (oil on canvas), 015 A (figure with hands at head), 018 C (pointillism), 019 A (Le Havre), and 020 B (rectangles). All match the current key.

- 011 now has a 22-word explanation; MoMA record `https://www.moma.org/collection/works/79018` supports Dalí's oil-on-canvas medium.
- 015 now asks about the central image, with four parallel visual descriptions. The MUNCH material supports the hands-at-head motif and its multiple versions.
- 018 replaces the title-derived tautology with a question on technique. Art Institute material describes separated colour marks and optical mixture; `пуантилизм` accurately names that documented procedure. The explanation is 24 words.
- 019 now asks the concrete, source-backed Le Havre location. Musée Marmottan's individual record `https://www.marmottan.fr/en/notice/4014/` identifies the hotel window, the outer harbour and the early-morning view. The explanation is 24 words.
- 020 now cites the correct MoMA Mondrian record, `https://www.moma.org/collection/works/80160`, whose description supports the gridded rectilinear colour fields. The explanation is 21 words.

**FINAL ACCEPT — editorial fact/source review only.** Current 001–010 remain the previously accepted pilot content; unchanged 012–014 and 016–017 retain their preceding source checks. With the five corrections above, all 20 current records pass this editorial review for factual support, a uniquely keyed answer, explanation length, phrasing and distinct knowledge. This is not structural validation, import approval, publication or release.

Fresh read-only check: `python docs/rewrite-agents/content20/build_paintings20.py --check` returned `OK: readonly candidate/key/legacy parity`. This is integrity evidence only, not editorial or schema approval.

Current SHA-256:

- `paintings20.candidate.json`: `BDD02F0DEBDADA048864E1CCC326B6A4E4F1FD7D2A041D4842BE4765DBB9CFE7`
- `paintings20.key.json`: `EBF93125D0500F7526C972BCCF0EC9819AE730F29C78F9E1EF3A3E6CC37286EC`
- `paintings20.legacy.json`: `AF028DF9839D6A99652FDCA1F35C96FBA1F83F2D5216843775839D871A80897C`
- `build_paintings20.py`: `4822EEE4ED1A80728CB9CC6ABFDDB761F858F93729BC780B6DFDBA83EB4D5126`
