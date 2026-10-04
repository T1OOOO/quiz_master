# Franchise review — current draft

Reviewer label: `thematic-review-franchises-20261004`
Task: `quiz_master-4gu`
Reviewed revision: current shared checkout, 2026-10-04

## Result

**REVISE — 40/40 records. No pack is approved or ready for import.** `review.json`
has one concrete `revise` result for every question ID.

`blind.json` was saved after reading candidates and before this reviewer opened keys,
research or sources. It must **not** be used as a final independent blind-solve
artifact: after it was saved, the lead disclosed the key-position distribution.
The next accepted version needs a new blind solve by a reviewer who has not seen
the keys or that disclosure.

## Check evidence

- Parsed four candidate packs: 40 questions, 40 unique IDs, and four options per
  question. Parsed 40 key records and 40 review records.
- Exact string comparison against `existing-stems.json` found no duplicate stem.
  This does not establish that a replacement will be non-duplicative; rerun after
  the writer changes a stem.
- No current candidate stem or option contains parentheses. Each key currently has
  exactly three distractor notes. These format successes do not cure the editorial
  findings below.
- Correct-index distributions are invalid for the required non-patterned use of all
  positions: Terminator `0:9, 1:1`; Harry Potter `0:9, 3:1`; GoT `0:6, 1:2, 2:2`;
  Star Wars `0:10`. Every candidate/key pair must be rewritten with a fresh,
  non-cycling distribution covering 0, 1, 2 and 3.
- Input SHA-256 is recorded in `input-sha256.json` for the exact bytes of all eight
  candidate/key files. If the writer changes an input, re-hash it and recheck all
  affected IDs.

## Primary-source inspection

Opened successfully and used for the stated facts:

- Paramount `terminator-2-judgment-day`: synopsis confirms John as the target,
  future Resistance leader and protected by a warrior; cast confirms Hamilton,
  Patrick, Morton and Boen.
- HarryPotter.com fact files for the Marauder's Map, Polyjuice Potion and Room of
  Requirement; the Horcrux feature confirms the diadem/Fiendfyre and Neville's
  strike at Nagini.
- StarWars.com Databank pages for Luke Skywalker and Kylo Ren. The Luke page also
  confirms Dagobah training, R2-D2 and the Death Star plans, Red Five, the Han
  rescue and the Sarlacc sentence.

Limitations found while opening the exact URLs:

- `https://www.starwars.com/databank/Yoda` timed out twice. The fact in SW-005 is
  corroborated by the opened Luke page, but the key must cite a URL that is actually
  opened or be rechecked when the Yoda page responds.
- The exact WB Shop URL in every current GoT key,
  `https://wbshop.com/products/game-of-thrones-houses-adjustable-ring-set`, now
  returns 404. The currently opened renamed product page
  `https://wbshop.com/products/game-of-thrones-house-sigil-adjustable-8-ring-set`
  lists eight houses only; it does not state their individual sigils or mottos.
  Search-result text was not treated as evidence. Therefore none of the ten GoT
  house-symbol/motto claims is supported by a currently opened exact source.

## Required writer changes

- Replace or diversify the GoT pack with facts about the stated HBO series backed
  by actually opened primary HBO/WBD material. It is currently ten inverse
  house-symbol/motto flashcards, including two questions framed as a merchandise
  product rather than the series.
- Terminator has four actor/cast questions (004–006, 010), exceeding the packet
  limit of three. Questions 002/009 duplicate the same mission fact; 003/007
  overlap around John as future Resistance leader. Add verified coverage that uses
  the declared first-film-plus-T2 scope.
- Repair HP-002's “предмет” category error, HP-005's insufficient distractor
  rationales, and HP-008's conspicuously long correct option.
- Repair SW-010 by identifying the Lor San Tekka → Poe map fragment held in BB-8;
  the current broad wording also permits R2-D2. Apply the balanced key-order fix
  across all ten Star Wars questions.

After revisions, refresh the input hashes and request a new independent blind
solve before factual re-review. This report is an implementation-review artifact,
not publication, import, acceptance or release evidence.
