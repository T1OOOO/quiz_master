# Folklore pilot 10 — independent fact review

**Verdict: FINAL ACCEPT.** This is an independent review only; it does not publish, import, or otherwise accept the material into the quiz corpus.

## Scope and method

Reviewed, blind-first, in this order: `folklore-candidate-pilot10.md`, then the editorial key, source ledger, and legacy JSON. The candidate answers were selected before viewing the key. Every item has one clear best answer, four plausible options, and a source-scoped claim rather than a universal claim about a folklore tradition.

Input SHA-256 receipts:

| Input | SHA-256 |
| --- | --- |
| `folklore-candidate-pilot10.md` | `88C524036C7AA0B1261FF82EBD19180C49215A2C7BB601A32849B74009061E75` |
| `folklore-editorial-key-pilot10.md` | `D1BA0E942E4C684E9F1D37B5660FCEA0AA121156A1C5DE01D630FA9AE7F86D92` |
| `folklore-legacy-pilot10.json` | `29CFA638F1B7C33F82F4674C3D4A75D5EB53FFFC4EF5170D1C7E99D740426899` |
| `folklore-source-ledger-pilot10.md` | `548C56EA541AFEC1F365250122F1DAA51BCF9C427ED1906A9DF2499FB8935A5A` |

## Blind solve and factual evidence

| ID | Blind answer / verdict | Received source evidence |
| --- | --- | --- |
| 001 | A — Koschei; ACCEPT | Nashville Public Library, *The Death of Koschei the Deathless*, lines 83–85: the third bucket restores his strength and he breaks the chains. |
| 002 | B — Baba Yaga's mares; ACCEPT | Nashville Public Library, lines 174–176: Prince Ivan is told to tend Baba Yaga's mares for three days. |
| 003 | B — karasu tengu; ACCEPT | The Met, *Mask (Somen) Representing a Tengu*, states that the karasu tengu has a birdlike head and sharp beak. |
| 004 | B — enormous long nose on a human face; ACCEPT | The same Met object description distinguishes the ko no ha tengu by its human face and enormous long nose. |
| 005 | A — Pluracan; ACCEPT | UCD National Folklore Collection, *The Leprechaun* (Co. Cork), calls the being “Pluracan.” |
| 006 | B — shoemaking; ACCEPT | The same UCD record identifies shoe-making as the Pluracan's occupation. |
| 007 | A — return a bow; ACCEPT | The Met's received *Netsuke: Small Sculptures of Japan* receipt describes the kappa losing its fluid and strength when it returns a bow. |
| 008 | A — tortoise body, frog legs, monkeylike head; ACCEPT | The same Met receipt gives this composite physical description of the kappa. |
| 009 | A — banshee; ACCEPT | UCD National Folklore Collection archive record is titled *The Banshee and Leprechaun* (Dunshaughlin, Co. Meath). |
| 010 | A — a handkerchief; ACCEPT | Nashville Public Library, lines 148–152 and 201, has Marya give Prince Ivan the handkerchief used to make the bridge. |

The repeated-source pairs test different, non-overlapping facts (identity, task, object, appearance, name, occupation, action, or title). No distractor supplies a competing correct answer under the stated source/version qualifier.

## Re-review of corrected release gates

The author corrected the two actual blockers without changing the ten approved answers. Current legacy SHA-256: `31A20696A26F1A6975993C2A8D44CF8A906D2A0A99F5DB76089DC67DF13608FA`.

1. **Explanation quality and length: ACCEPT.** The ten source-scoped explanations are now 26, 28, 28, 29, 29, 28, 30, 28, 29, and 30 words respectively (IDs 001–010). Each explains why a plausible distractor is wrong without generalizing beyond the named source/version.
2. **Required pack metadata: ACCEPT.** A non-empty top-level `description` is now present. `difficulty` is intentionally absent and is **not** a blocker: the applicable importer treats an omitted difficulty as unknown, rather than requiring the reviewer to invent calibration data.

`editorial` is not present as a public top-level array, which is correct. The closed-field legacy shape is exactly `id`, `category`, `title`, `description`, and `questions`; each question has only `id`, `type`, `text`, `options`, `correct_answer`, and `explanation`. The JSON has ten ordered, unique IDs, four options per record, and valid answer indexes.

## Fresh check evidence

- Inspected `folklore-check-pilot10.py` before relying on it: it only reads `folklore-legacy-pilot10.json` and asserts the closed fields, IDs, option count, answer index, and 20–45-word explanation range.
- `python docs/rewrite-agents/preparation-mythology/folklore-check-pilot10.py` — `PASS folklore pilot10 closed-fields/options/answers/explanations=20-45`.
- Independent PowerShell parse confirmed the ten explanation counts above, a non-empty description, four options each, and valid answer indexes.

All ten fact/key checks remain ACCEPT and the corrected metadata, explanations, and distractor rationales now pass review. **FINAL ACCEPT** is limited to this review; publication, importer execution, and deployment remain outside scope.
