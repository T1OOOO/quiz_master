# Preparation books 30 — independent fact review

Reviewer: `review-books30-oct3`. This is independent review evidence, not
publication, import, or release.

## Verdict: REVISE

All 30 candidate-facing questions have one clear author answer and four parallel
author options. The 15/15 pre-/post-1945 split, the required *Hamlet* play wording,
and the 1966–67 posthumous-publication classification of *The Master and Margarita*
are correct. `check_pilot.py` passes the structural/parity/40–65-word checks, but it
does not establish source fitness. Two new records cite pages that do not support the
classification claim written in the key and explanation.

| ID | Finding | Smallest correction |
|---|---|---|
| `prep-books-modern-08` | The supplied Paulo Coelho reading-group PDF supports Santiago's treasure journey, but contains no `1988` publication fact. It therefore cannot support the claimed original Portuguese 1988 classification. | Replace/add a received authoritative bibliographic or publisher source explicitly giving the original 1988 publication, then cite that source in the key, ledger, and explanation. The author answer/options may remain. |
| `prep-books-modern-09` | The supplied HarperCollins URL currently renders product-template placeholders and contains no usable 1960 or author bibliographic data; it is not evidence for the asserted first-publication classification. | Replace it with an accessible authoritative publisher/library/author source explicitly identifying Harper Lee and the 1960 original publication; update the key, ledger, and explanation citation. The candidate wording/options may remain. |

## Checks and reviewed evidence

- Blind solve before opening the key: all 30 answers are unambiguous and match the
  later key (A/B/C/D positions as recorded in the candidate file).
- `C:/Users/Alexey_Matvienko/tools/agent-hub/.venv/Scripts/python.exe
  docs/rewrite-agents/preparation-books/check_pilot.py`: `PASS: 30 questions;
  15/15 packs; positions 8/8/7/7 and new 5/5/5/5; JSON shape, candidate/key exact
  parity, 40–65-word explanations, max runs and distractor-set guard valid`.
- Candidate/key/legacy records are aligned by ID, ordered option text, answer index,
  and explanation; all legacy explanations are within 40–65 whitespace words.
- `prep-books-modern-06` is properly supported by Penguin's 1954–55 trilogy page;
  `prep-books-modern-12` is properly supported by Penguin's author page stating that
  *Norwegian Wood* was published in 1987. The two findings above are source-specific,
  not author-answer disputes.
- The ten accepted pilot IDs are still designated immutable in
  `authoring-checkpoint.json` and their current candidate/key/legacy parity passes.
  A per-record frozen payload snapshot is not retained here, so byte-for-byte
  historical identity cannot be independently re-derived from the old aggregate hashes.

## Source hashes at review

- `candidate.md`: `07d3a2a7458f9d78488484fb173f2e37b579537fae07f35d4e12a605361a0f1a`
- `editorial-key.md`: `97e2840745fe872c1c7d8730cfe0186d377297b198a41a864db1d4d9c0206bb8`
- `legacy-classic.json`: `a76844a804345ffad5c060d0179bbb8f3664fef35f50b64db781926c86f0f452`
- `legacy-modern.json`: `769cfe531e1d6181763ba9ed7d51b5175e3798f38519e78e7829939a2567951e`

## Correction re-review: FINAL ACCEPT

The two REVISE findings are corrected without scope expansion.

- `prep-books-modern-08`: the Fundação Paulo Coelho page explicitly identifies
  *The Alchemist* as Paulo Coelho's work, gives original title *O Alquimista*,
  Portuguese as the original language, and first-publication year 1988. Key, ledger,
  and legacy explanation now state only those supported facts.
- `prep-books-modern-09`: the Library of Congress *America Reads* exhibition explicitly
  identifies Harper Lee, *To Kill a Mockingbird* (1960), and its displayed 1960
  J. B. Lippincott edition. Key, ledger, and legacy explanation now cite that evidence.

The re-run checker again passed all 30 records: 15/15 classic/modern split, positions
8/8/7/7 overall and 5/5/5/5 in the 20 new records, candidate/key/legacy exact parity,
40–65-word explanations, bounded answer runs, and distractor-set guard. The earlier
note remains: the ten accepted pilot records have current parity and immutable IDs,
but no historical per-record payload snapshot permits an independent byte-for-byte
reconstruction of their prior accepted state.

Corrected review hashes:

- `candidate.md`: `07d3a2a7458f9d78488484fb173f2e37b579537fae07f35d4e12a605361a0f1a`
- `editorial-key.md`: `cc293882928acd4ef3f0e2acab394698b54cfb0233ccfdcb911ca5fc2a635155`
- `legacy-classic.json`: `a76844a804345ffad5c060d0179bbb8f3664fef35f50b64db781926c86f0f452`
- `legacy-modern.json`: `9563fe64182d856e7f8725d17640c675324628f6343888ea2f37a5db3ee8185f`
