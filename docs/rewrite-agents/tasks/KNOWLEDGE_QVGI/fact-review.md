# KNOWLEDGE_QVGI — independent fact check

Reviewed independently on 2026-10-19 against the shipped draft
`next/apps/quiz_app/assets/quizipedia/knowledge_atlas.json` (44 events, 30
works and 39 people). This is editorial review, not publication approval.

## Verdict

**REVISE before using the records as quiz answer keys.** The core
chronology, author/director links, and the named actor-role pairs sampled are
largely correct. The material needs date precision, one taxonomy correction,
and replacement of dead source links. A single integer `year` currently
asserts false precision for several process and ancient-history records; it
should not be used to ask an exact-year question when the record is marked
approximate or a range.

## Blocking corrections

| Record | Status | Required correction | Evidence |
|---|---|---|---|
| `messiah` | reject | It is an **oratorio**, not an opera. Change `type` to `oratorio` and add a UI/quiz label, or use the existing broader `music` type. The current record says both `type: opera` and “not an opera”. | Handel work page is cited by draft; the draft’s own `fact_ru/en` identifies the contradiction. |
| `hammurabi` | revise | Replace `year: -1754` with an explicit approximate display value, e.g. `year: -1750`, `year_label: "около 1750 г. до н. э."`, `date_precision: "approximate"`. Reword the explanation to “собрание судебных решений/юриспруденции”, not a modern uniform code. Replace dead URL with `https://www.louvre.fr/en/the-code-of-hammurabi`. | Louvre’s current page dates the stele “around 1750 BC”, says it is not a modern legal code, and describes a collection of 282 judgements. The draft URL `/en/explore/the-palace/...` returns 404. |
| `swan_lake` | revise | Replace its date-specific 2026 programme URL with stable `https://www.mariinsky.ru/about/exhibitions/petipa200/swan_lake/`. Retain 1877 as first production and make the 1895 assertion explicitly the Petipa–Ivanov version rather than “the version known today”. | Mariinsky’s stable page documents the 1877 Bolshoi staging and the 1895 Mariinsky production; it is directly relevant. |
| `agriculture`, `writing`, `pyramids`, `buddha`, `industrial` | revise | Treat these as periods/approximate dates. Add `date_precision` and a user-facing label: “около 10 000 г. до н. э.”, “около 3200 г. до н. э.”, “около 2600 г. до н. э.”, “V–IV вв. до н. э.” (or “около 500 г. до н. э.”), and “конец XVIII — XIX век” respectively. Do not generate a single-year question for them. | Agriculture and industrialisation are multi-region/multi-decade processes. Dating the historical Buddha and the early Buddhist tradition is not precise to one year. |
| `abolition` | revise | Rename to “Slavery Abolition Act / Закон об отмене рабства” and state that Parliament passed it in 1833; its main provisions took effect in 1834 and the apprenticeship transition matters. Do not ask “when slavery was abolished in the British Empire?” with 1833 as an unqualified unique answer. | The event date and legal effect differ, so the current title overstates a one-year outcome. |

## Other chronology and wording revisions

| Record | Status | Correction |
|---|---|---|
| `athens` | revise | Display `508/507 BCE` or “508/7 г. до н. э.”, because this is a conventional dating of Cleisthenes’ reforms, rather than presenting a bare exact single year. |
| `divine_comedy` | revise | `1321` is defensible as completion/Dante’s death, but label the work’s composition as `c. 1308–1321` if the timeline means creation rather than a single release. |
| `odyssey` | revise | `-700` is a conventional approximation, not a publication year. Label “VIII век до н. э.; традиционно приписывается Гомеру” and exclude it from exact-year prompts. The oral-tradition statement should say “сложилась в устной традиции” rather than imply a known date of textual recording. |
| `don_quixote` | revise | If `1605` is the timeline date, title it “Дон Кихот, часть I” or add a date note. The complete novel spans part I (1605) and part II (1615); the current fact states this correctly. |
| `hamlet`, `macbeth` | revise | Composition/first-performance dates are not exact. Keep a convenient order point, but label them `около 1600` and `около 1606`, or attach a precision note. |
| `ww2` | revise | “Second World War” with `1939` needs the qualifier “war in Europe begins”; the wider Asian conflict had begun earlier. This avoids a misleading global exact-start quiz answer. |

## Works and people — sampled answer integrity

These answer relationships were independently checked and are acceptable with
the source repairs below: Handel–*Messiah* (taxonomy excepted), Bizet–*Carmen*;
Tchaikovsky–*Swan Lake*; Fleming–Garland–Dorothy; Welles–Charles Foster Kane;
Curtiz–Bogart/Rick–Bergman/Ilsa; Kurosawa–Mifune/Kikuchiyo; Hitchcock–
Perkins/Norman Bates; Coppola–Brando/Vito–Pacino/Michael; Lucas–Hamill/Luke–
Fisher/Leia; Jackson–Wood/Frodo; Bong–Song/Kim Ki-taek; Miranda–Hamilton.

The Oscar claims sampled are supported by Academy records: *Spirited Away*
won Animated Feature at the 2003 ceremony; *The Return of the King* won all
11 awards for which it was nominated; *Parasite* won Best Picture in 2020 and
the Academy describes it as the first non-English-language winner. The Library
of Congress material supports Welles’s director/actor connection to *Citizen
Kane* and its celebrated depth-of-field photography.

The source model nevertheless needs improvement: one `source_url` cannot
support both a person’s birth year and a work/role/award claim. In particular,
the 2003/2004/2020 Academy ceremony URLs are suitable for awards but not by
themselves for `miyazaki`, `jackson`, `bong`, or `song` biographies and roles.
Likewise a Library of Congress authority record can be a biographical source
without proving an actor’s fictional role. Store claim-level references (or at
least separate `person_source_url`, `work_source_url`, and `credit_source_url`)
before surfacing all source buttons as evidence for generated answers.

## Link health

An HTTP HEAD check of the 103 unique source URLs was run with redirects and
timeouts. 403 responses from British Museum, Library of Congress, Oscars and
Parliament endpoints appear to be bot protection, so they are **not** reported
as broken. Confirmed 404 responses require replacement before publication:

- Events: `internet`, `plague`, `magna`, `russian_rev`, `french_rev`,
  `industrial`.
- People: `doyle`, `orwell`, `shelley`, `shakespeare`, `austen`, `beethoven`,
  `bizet`, `tchaikovsky`.
- Works: `wizard`, `citizen_kane`, `psycho`, `star_wars`, `seven_samurai`.
- Also `hammurabi` and `swan_lake`, handled above.

Some fetches returned 429 (Met collection essays) or 500 (AFI Pacino), which
are availability issues rather than a factual verdict. Recheck them serially
or replace them with stable collection/authority pages. The `gfhandel.org`
links errored in this check and also need a manual browser confirmation.

## Checks and evidence

- Parsed the draft: 44 event records, 30 works, 39 people; all referenced IDs
  were inspected for author, director and cast consistency.
- Followed the replacement Louvre and Mariinsky primary institutional pages.
- Queried current Academy and Library of Congress records for the sampled film
  awards/credits.
- `Invoke-WebRequest -Method Head` over all unique source URLs (PowerShell,
  `E:\Projects\quiz_master`): completed; results are summarized above.

Remaining risk: descriptions are concise and generally pedagogically sound,
but several event sources are broad gallery homepages rather than sources that
prove the precise statement. Do not treat this report as verification of every
word of those essays until claim-level references and date precision are added.

## Final re-review — 2026-10-19

**ACCEPT WITH ONE MINOR EDITORIAL FIX.** I re-read the current JSON after the
writer applied the review findings.

- `messiah` is now correctly typed as `oratorio`.
- `hammurabi` uses the current Louvre page and a visibly approximate date.
- `swan_lake` now uses the stable Mariinsky historical page.
- The five unavailable sources now point to working, directly relevant
  institutional pages: Cambridge (`plague`), U.S. State Department historical
  documents (`russian_rev`), UK National Archives (`industrial`), University
  of Edinburgh (`doyle`) and Tchaikovsky Research chronology (`tchaikovsky`).
- Approximation and range metadata now covers the former false-precision work
  dates: *Odyssey* (c. 800–700 BCE), *Divine Comedy* (c. 1308–1321), *Hamlet*
  (c. 1600–1601), and *Macbeth* (c. 1606). The implementation parses and
  displays this metadata. Its date-question generator operates on events, not
  these work records, so the ranges cannot become misleading exact-year work
  answers.
- `don_quixote` explicitly distinguishes part I (1605) and part II (1615),
  which resolves the former chronology ambiguity.

Minor edit required: `don_quixote.fact_ru` and `fact_en` currently repeat the
part-I/part-II sentence twice. Remove the duplicate sentence; the remaining
sentence is factually correct. This is presentation-only and does not block
the factual acceptance above.

Sampling limitation: source URLs remain record-level rather than
claim-level. They adequately support the reviewed identity, work, date and
award claims, but a future larger corpus should attach distinct references to
biographical facts, work metadata and each role/credit.
