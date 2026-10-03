# Movie actors40 pilot — independent fact review

**Scope:** `quiz_master-8k1.15`; draft pilot only, not an import or publication decision. Reviewed 2026-10-03. I read only `film`, `year`, `role`, and `options` for the blind pass; I did not read `answer`/`correct_answer` until after recording the ten choices below.

## Verdict: ACCEPT (10/10)

| ID | Blind answer | Result | Independent evidence / check |
|---|---|---|---|
| prep-film-actors2-001 | Judy Garland | ACCEPT | AFI *The Wizard of Oz* catalog identifies Garland as Dorothy Gale; it also documents Temple as a considered alternative. |
| 002 | Humphrey Bogart | ACCEPT | AFI *Casablanca* catalog credits Bogart/Rick Blaine and distinguishes Rains/Renault and Henreid/Laszlo. |
| 003 | Roy Scheider | ACCEPT | AFI *Jaws* catalog credits Scheider/Brody, Shaw/Quint, and Dreyfuss/Hooper. |
| 004 | Sylvester Stallone | ACCEPT | AFI *Rocky* catalog credits Stallone/Rocky; Weathers, Young, and Shire are parallel in-film cast distractors. |
| 005 | Arnold Schwarzenegger | ACCEPT | AFI credits Schwarzenegger as the Terminator and separates Biehn and Henriksen. Paramount's official *Terminator 2* page additionally confirms Edward Furlong as John Connor, so the sequel contrast is accurate. |
| 006 | Michael J. Fox | ACCEPT | AFI *Back to the Future* catalog credits Fox/Marty and the three other actors; its production history confirms Stoltz was replaced after filming began. |
| 007 | Tom Hanks | ACCEPT | AFI *Forrest Gump* catalog credits Hanks/Forrest, Wright/Jenny, Sinise/Lt. Dan, and Williamson/Bubba. |
| 008 | Jack Nicholson | ACCEPT | AFI *The Shining* catalog credits Nicholson/Jack Torrance and the two in-film alternatives; its notes identify Weber as Jack in the 1997 miniseries. Stephen King's official work page independently gives the same Weber/Jack distinction. |
| 009 | Henry Thomas | ACCEPT | AFI *E.T.* catalog credits Thomas/Elliott, Barrymore/Gertie, Coyote/Keys, and MacNaughton/Michael. |
| 010 | Chadwick Boseman | ACCEPT | Official Marvel material identifies Boseman as T'Challa in *Black Panther*; the other three are actors in that film's ensemble, not the title character. |

All blind answers matched the disclosed `answer` and `correct_answer` values. The questions ask for physical live-action performances; none relies on a voice-only credit. The stated years identify the intended originals rather than a remake or later television version. Distractors are named performers, parallel in form, and each is either an actual cast member/role distinction or a specifically explained cross-version alternative; no answer-name or option-order leak was found.

## Evidence received

* AFI catalog pages supplied in the pilot were opened and received for 001–009. In particular, AFI’s *The Shining* entry both credits Nicholson as Jack Torrance and records Steven Weber as the 1997 miniseries Jack.
* Official supporting pages opened for the two cross-version claims: [Paramount, *Terminator 2: Judgment Day*](https://www.paramountpictures.com/movies/terminator-2-judgment-day) (Furlong/John Connor) and [Stephen King, *The Shining* television work](https://stephenking.com/works/television/shining.html) (Weber/Jack Torrance). 
* The supplied official Marvel URL for 010 was received through the official Marvel result body as identifying Boseman as T'Challa; a direct-page fetch returned a retrieval error, so this is evidence of the received official content, not a claim that the direct fetch succeeded.

## Structural checks

* JSON: 10 records, 10 unique IDs, 10 unique film/role pairs.
* Explanation lengths: 22–27 Russian-token words, within the requested 20–45 range.
* Correct-option sequence (zero-based): `0,0,2,3,0,1,1,2,1,1`; counts A/B/C/D = 3/4/2/1, non-cyclic, maximum adjacent run 2.
* Compared with 20 published questions in `prep_film_actors_1.json`: zero duplicate film-and-role pairs.

## Immutable input hashes

* `movie-actors40-pilot.json`: `bd6c46bfb74e061d1f65ac53afc9725cff4a7776b9b9c9da1d22bc0888d572bb`
* `movie-actors40-pilot-freeze.md`: `c4e0489f9bf92d9d92b6cb279cf8985abdf3c9a56893a768d5b05e4f25e53ed2`
* `quizzes/Preparation/prep_film_actors_1.json`: `be7107b971b4ffa7e2a35a0d3f553efa38b23ab58b8c9313a28a6c4ba02410ad`

No source, draft, or published quiz file was changed.

---

## Checkpoint 011–040 and frozen 40-record pack (2026-10-03)

**Final pack verdict: REVISE (2 scoped records); 38/40 factual/parity checks pass.** This section retains the pilot 001–010 acceptance above and reviews the 30 new records independently. It is not a publication decision.

### Blind pass, completed before opening the editorial key

`011 C, 012 D, 013 A, 014 C, 015 D, 016 B, 017 A, 018 D, 019 C, 020 A, 021 B, 022 C, 023 A, 024 B, 025 C, 026 D, 027 D, 028 A, 029 C, 030 D, 031 B, 032 A, 033 D, 034 C, 035 B, 036 D, 037 A, 038 C, 039 B, 040 D`.

All 30 choices matched the disclosed key. AFI pages were actually received for every 011–040 claim except the supplied 014 URL; the correct AFI record was received through the canonical search result. The pages support the film years, actor/role pairings, and the explanation contrasts. This included the unusually easy-to-confuse distinctions: Wood is the on-screen Maria while Nixon supplied her singing voice (019); Pacino was attached to the early *Born on the Fourth of July* project but Cruise played Kovic in the released film (038); and Streep was only a contender for *Thelma & Louise* (039).

| IDs | Verdict | Notes |
|---|---|---|
| 011–013 | ACCEPT | AFI credits and all stated contrast facts match. |
| 014 | REVISE | Supplied/ledger URL is `.../TO-KILLAMOCKBIRD` (missing `ING`) and did not resolve in independent fetch. Replace it with the received AFI record, e.g. `https://catalog.afi.com/Film/22363-TO-KILL-A-MOCKINGBIRD?cxt=filmography`, then re-render ledger and pack. The question, answer, and explanation are otherwise correct. |
| 015–016 | ACCEPT | AFI verifies roles and considered/in-film distractor distinctions. |
| 017 | REVISE | Factually correct, but it re-tests the already published `prep_film_actors_1` knowledge point: *The Godfather* (1972), Michael Corleone, Al Pacino. Changing the year/film to *Part II* does not make the actor-and-character answer a meaningfully new question under the requested published/pilot duplicate exclusion. Replace this record with a different actor/role target, then re-render and recheck balance. |
| 018–040, except 017 | ACCEPT | AFI receipts support each intended performance and stated cast, voice-performance, remake/year, or early-casting contrast. |

### Deterministic/parity checks

I inspected `movie-actors40-render.py` before running its `--check` branch: that branch only builds in memory and compares bytes; it does not write. `C:\\Python314\\python.exe movie-actors40-render.py --check` returned `{"status":"PASS","errors":[],"pack_sha256":"2923dd...ce1cb"}`. SHA-256 values of legacy pack, blind candidate, editorial key, and source ledger were identical before and after the check.

* 40 unique IDs; candidate text/type/options and key answer/index exactly match legacy for all 40; ledger answer/source records are present for all 40.
* Explanations: 20–30 words (within 20–45); four options each; no three-answer run.
* Final answer counts A/B/C/D: **10/10/10/10**, maximum run 2. The sequence is non-cyclic.
* Current frozen legacy pack SHA-256: `2923dd545bb6a0531670f7618d81fa4d8cce1d15202858e5182897da3dcce1cb` (matches the supplied pack hash).
* Candidate/key/ledger SHA-256 respectively: `dc8e1c3a6f563288b589da3f6ad39cf5cafb597dc0f98eed984a59654d6e07d7`, `73e5f8ece43c1860b50548e2baaf165d47b7440b859588912da436f20e41d21b`, `467bf0d494c4b76843c87464b919f0181cbba84fec14446ba320b8521c5b33a7`.

The re-render will necessarily change those hashes after the two corrections; no final acceptance is implied until the corrected frozen outputs are rechecked.

---

## Final delta re-review (014 and 017)

**FINAL ACCEPT — 40-record frozen pack.**

* **014:** The source and ledger now use the received canonical AFI *To Kill a Mockingbird* URL. It opens and credits Gregory Peck as Atticus Finch; Duvall/Boo Radley and Peters/Tom Robinson also match the explanation.
* **017:** The replacement is *All About Eve* (1950): Bette Davis/Margo Channing. The received AFI record credits Davis as Margo and Anne Baxter as Eve Harrington. Its answer, role, and film are not duplicated elsewhere in the final 40 bank or in the previously reviewed published/pilot targets.
* Candidate, key, legacy, and ledger agree on both changed IDs. `movie-actors40-render.py --check` returned PASS, with byte-identical generated outputs before/after; it reports pack SHA-256 `c2102b3866e8d41c7f7ddc9f8aa0688b3ad537d484c31c6a4c2916c25079ae9a`.

Final artifact SHA-256: legacy pack `c2102b3866e8d41c7f7ddc9f8aa0688b3ad537d484c31c6a4c2916c25079ae9a`; candidate `1c3dd552ad75d7d90d2e55f8fa2af2eefbc5ab37306c2daeba0998c04b0077aa`; key `170bf24941de7da9da2eede78b57a9a490741e82f03d017c6b39faafbf6961f6`; ledger `280a2d3e3f8afb44ef52cff1a08a73aaf0da55770ae34d0e025ed803854ef281`.
