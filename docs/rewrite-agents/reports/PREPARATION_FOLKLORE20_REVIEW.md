# Folklore final 20 — independent fact review

**Current verdict: FINAL ACCEPT.** This is a review verdict only; it does not publish, import, or deploy the pack.

## Method and frozen-pilot preservation

I blind-solved `folklore-candidate20.md` before reading the key. The resulting answers were: 001 C, 002 A, 003 D, 004 B, 005 C, 006 B, 007 A, 008 D, 009 C, 010 A, 011 B, 012 D, 013 B, 014 C, 015 D, 016 A, 017 D, 018 B, 019 A, 020 C. They match the key after the explicitly authorized answer-position reordering.

The original pilot-10 artifact remains preserved. The lead explicitly authorized editorial rewrites in final-20's first ten records, so this re-review assesses the current stems, options, explanations, and source qualifiers directly rather than carrying the old pilot verdict forward.

## New facts 011–020

| ID | Blind answer / verdict | Official received-source evidence |
| --- | --- | --- |
| 011 | B — gun; ACCEPT | The Met, *Young Women Playing Kitsune-ken*, says the gun beats the fox because it can kill it. |
| 012 | D — fox; ACCEPT | The same Met description gives the three-way rule: the fox can bewitch the village chief. |
| 013 | B — ring on Aladdin's finger; ACCEPT | LOC digitized *Arabian Nights* text distinguishes the first genie as the ring's slave. |
| 014 | C — lamp; ACCEPT | The same LOC text says the genie seen by Aladdin's mother is the lamp's slave, explicitly distinguishing the two genies. |
| 015 | D — roc birds; ACCEPT | LOC's *Seven Voyages of Sindbad* account states that roc birds sink Sindbad's boat on the fifth voyage. |
| 016 | A — Sindbad the Porter; ACCEPT | The same LOC account identifies the poor porter and the wealthy house-owner/storyteller as the two different Sindbads. |
| 017 | D — Ghana; ACCEPT | LOC's *World Treasures* exhibition calls Anansi the spider a popular figure in Ghanaian folk literature. |
| 018 | B — African and African-diaspora animal trickster; ACCEPT | LOC American Folklife Center's guide lists Anansi as an African and African-diaspora animal trickster. |
| 019 | A — presence of a maiden; REVISE stem | The Met's unicorn exhibition says the unicorn could only be tamed by a maiden; the fact is supported, but the present Russian stem wrongly calls that a “gesture.” |
| 020 | C — dragon; ACCEPT | The Met's *Medieval Bestiary* receipt identifies the dragon as the panther's only enemy. |

The deliberate same-source pairs test different facts: kitsune-ken's two directional rules; the ring versus lamp genies; Sindbad's fifth-voyage danger versus the two protagonists; Anansi's Ghana association versus his trickster role; and the unicorn-taming versus panther-enemy facts. All questions retain source/version or institutional qualifiers where folklore traditions can vary. Four options are present for every record and the distractors are plausible but not co-correct under the stated source.

## Editorial and structural checks

- All 20 explanations are 20–45 words: `27,25,24,27,26,27,28,25,28,27,22,23,25,25,23,26,22,26,23,21`. They state source-scoped rationale for a tempting wrong alternative without adding unsupported universal claims.
- The final answer positions have exact counts `5,5,5,5` for indexes 0–3; maximum equal-answer run is 1.
- `folklore-final20-build.py` was inspected before execution. Its `--check` branch generates expected text in memory and compares it with files; it writes only in the branch without `--check`.
- `python docs/rewrite-agents/preparation-mythology/folklore-final20-build.py --check` returned `PASS folklore final20 readonly check`.
- `folklore-legacy20.json` SHA-256 was identical before and after the readonly check: `F98D19265F02D283C1A986F2A2908DCBF18189E86F00620B2A93E0ECBFB9A9BA`.

## Delta re-review: 005, 006, and 019

The current candidate was blind-solved before opening the revised key: 005 C, 006 B, and 019 A. All three match the revised key. The new learner-facing stems remove the prior Firebird/ballet duplication. Exact cross-bank comparison found zero identical stems, and final-20 contains no Firebird/ballet item.

- **005: ACCEPT.** The source supports Baba Yaga's hut on chicken legs, and the revised stem no longer includes that answer inside its wording.
- **019: ACCEPT.** The question now asks who can tame the unicorn, and the Met source says a maiden can do so. `Дева` is a clear, grammatical answer; the knight, hunter, and dragon are plausible but non-co-correct alternatives.
- **006: corrected in the final delta.** The answer `Суседки`, source context, and explanation now correctly identify local traditions of the **Кадьякский архипелаг** alongside water rusalkas. This matches the received LOC context, which specifies the archipelago and includes Afognak and northern villages.

`folklore-final20-build.py --check` passed without changing the final legacy file. The closed JSON/word-count/index checks pass, as do balanced positions (5 each, maximum run 1). The canonical compact receipt for the other 17 current records is `1A61B66484E335E9D3CE5F699E8AC6B57C9752F9CAD01A4EEFBC1E91C4B96186`; reviewed delta IDs are 005, 006, and 019.

### Final one-word re-review

Blind solving of the corrected 006 still selects B — `Суседки`; the key and four options agree, and the revised qualifier is now exact. The final delta is limited to that 006 stem/explanation qualifier: 005 and 019 retain their approved text, while the canonical compact hash of the other 17 records remains `1A61B66484E335E9D3CE5F699E8AC6B57C9752F9CAD01A4EEFBC1E91C4B96186`.

`folklore-final20-build.py --check` again passed without writing. Closed JSON fields, valid answers, 20–45-word explanations, and balanced positions (5 each; maximum run 1) all pass. Current `folklore-legacy20.json` SHA-256: `A9F5E30B919A74B17F7EB5152026503F533C6A763C4759D7A2D05E5040677EE9`.

All previously identified factual and pedagogical blockers are now resolved. **FINAL ACCEPT** is limited to this independent review; importer execution and any publication remain outside this assignment.
