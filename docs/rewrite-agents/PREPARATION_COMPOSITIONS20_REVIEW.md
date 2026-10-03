# PREPARATION_COMPOSITIONS20_REVIEW

Status / task / model: **FINAL ACCEPT** (independent content-and-gate review only; not publication) / independent review of `preparation-music/compositions20-*` / Codex GPT-5.

Behavior delivered: blind-solved `compositions20-candidate.md` before reading the editorial key, then reviewed all 20 answers, distractors, explanations, version/arrangement qualifiers, and the received-source ledger. The factual/editorial result is 20 ACCEPT. Recheck after the one requested repair confirms that `compositions20-render.py --check` is read-only, detects drift, and leaves all four generated outputs byte-identical.

Changed and new files: new `docs/rewrite-agents/PREPARATION_COMPOSITIONS20_REVIEW.md` only.

## Per-question factual verdict

`Blind/key` is the answer chosen from the candidate before viewing the private key. Source receipts refer to the given received-source ledger and to the listed institutional primary/catalogue record re-opened in this review where available.

| ID | Blind/key | Verdict | Checked factual boundary and receipt |
|---|---|---|---|
| compositions001 | Vivaldi / Vivaldi | ACCEPT | Schott score record re-opened: Antonio Vivaldi; four Op. 8 concertos, RV 269/315/293/297. |
| compositions002 | Tchaikovsky / Tchaikovsky | ACCEPT | Received Tchaikovsky Research record identifies Op. 37a as twelve monthly piano scenes; Vivaldi distinction is clear. |
| compositions003 | Beethoven / Beethoven | ACCEPT | Beethoven-Haus re-opened: C-minor Op. 67 composition span early 1804–March 1808. |
| compositions004 | Beethoven / Beethoven | ACCEPT | Beethoven-Haus re-opened: D-minor Op. 125 record names Schiller as text poet; named choral-final qualifier removes ambiguity. |
| compositions005 | Mozart / Mozart | ACCEPT | Mozarteum Köchel record re-opened: Mozart's KV 525; own catalogue entry dated 10 August 1787. |
| compositions006 | Mozart / Mozart | ACCEPT | Mozarteum/NMA received records distinguish Mozart's incomplete KV 626 from Süssmayr's traditional completion; wording correctly asks principal author. |
| compositions007 | Schubert / Schubert | ACCEPT | Berliner Philharmoniker re-opened: Franz Schubert, B-minor D 759, `Unfinished`; D number avoids numbering disagreement. |
| compositions008 | J. S. Bach / J. S. Bach | ACCEPT | Bach Choir record re-opened: Bach assembled six concertos for the Brandenburg margrave while seeking employment. |
| compositions009 | Handel / Handel | ACCEPT | Foundling Museum re-opened: Handel's will bequeaths the score/parts of `my oratorio called The Messiah`; 1741 claim is scoped to received English Heritage record. |
| compositions010 | Haydn / Haydn | ACCEPT | Haydn2032 re-opened: Joseph Haydn, No. 45, F-sharp minor, Hob. I:45, `Farewell`; final-stage gesture is properly attributed to the supporting LA Phil receipt. |
| compositions011 | Ravel / Ravel | ACCEPT | Philharmonie de Paris re-opened: Ravel, Ida Rubinstein commission, 1928; source supports the two-motive/crescendo description. |
| compositions012 | Debussy / Debussy | ACCEPT | Deutsches Museum catalogue re-opened: Claude Debussy, `Suite bergamasque` No. 3 `Clair de Lune`. |
| compositions013 | Mussorgsky / Mussorgsky | ACCEPT | Received Library of Congress record separates Mussorgsky's solo-piano original from Ravel's orchestration; distinction is explicit. |
| compositions014 | Rimsky-Korsakov / Rimsky-Korsakov | ACCEPT | Mariinsky record re-opened: Rimsky-Korsakov, symphonic suite `Scheherazade`, Op. 35 (1888). |
| compositions015 | Saint-Saëns / Saint-Saëns | ACCEPT | BnF re-opened: autograph `Carnaval des animaux` by Camille Saint-Saëns, completed February 1886. |
| compositions016 | Holst / Holst | ACCEPT | Received Boosey & Hawkes catalogue names Gustav Holst and the `Mars` score; no rival option is defensible. |
| compositions017 | Prokofiev / Prokofiev | ACCEPT | Mariinsky re-opened: Sergei Prokofiev conceived `Peter and the Wolf` for Natalia Sats's children’s theatre; received Boosey list supports the instrument-introduction qualifier. |
| compositions018 | Gershwin / Gershwin | ACCEPT | Received Library of Congress/Gershwin records distinguish composer Gershwin from premiere orchestrator Ferde Grofé and give 12 February 1924, Aeolian Hall. |
| compositions019 | Grieg / Grieg | ACCEPT | Received Philharmonie/Naxos records distinguish Grieg's incidental music from Ibsen's drama; the question explicitly asks the original music. |
| compositions020 | Dukas / Dukas | ACCEPT | LA Phil re-opened: Paul Dukas, `The Sorcerer’s Apprentice`, composed 1897. |

Editorial edge cases pass: KV 626 names Mozart while crediting Süssmayr's completion; D 759 avoids competing symphony numbering; `Pictures` asks the piano original rather than Ravel’s orchestration; `Peer Gynt` distinguishes Grieg’s incidental music from Ibsen’s play; Schiller attribution is confined to Beethoven Nine’s text use. No distractor becomes equally correct under the supplied wording.

## Required check evidence

| Command / inspection | CWD | Exit | Result |
|---|---|---:|---|
| `python docs\\rewrite-agents\\preparation-music\\compositions20-check.py` | `C:\\ap\\quiz_master` | 0 | `PASS compositions20 checkpoints=20 positions=ABCDACBDBDACDACBDBCA`; validates 4 options, matching answer position, 40–65-word explanations, source URL, sequential IDs, and non-adjacent positions. |
| `python docs\\rewrite-agents\\preparation-music\\compositions20-render.py --check` | `C:\\ap\\quiz_master` | 0 | `PASS checked compositions20 candidate/key/ledger/legacy=20`; repaired explicit `--check` branch compares only and does not call `write_text`. |
| `python docs\\rewrite-agents\\preparation-music\\compositions20-render-test.py` | `C:\\ap\\quiz_master` | 0 | `PASS --check detects drift without writes`; temporary-directory negative test deliberately drifts one output, requires nonzero check result, and compares pre/post SHA-256 for all four outputs. |
| before/after SHA-256 around the real `--check` | `C:\\ap\\quiz_master` | 0 | Candidate `83BB84…E926`, key `110D425…24E9`, ledger `1CB5EC…188A`, legacy `D6BCC3…A6B0` unchanged. |

The required revision is complete: `--check` compares rendered strings to the four existing files and fails on drift; writes remain limited to normal render mode. The dedicated negative test proves that a failed check does not mutate its inputs. Draft/checkpoint SHA-256 values reviewed in the recheck remain unchanged.

Reviewed SHA-256: candidate `83BB84C31A0E8D0A76AB92476BDEA2FD3AD9D847CD63BF88FCAC4BC176D4E926`; editorial key `110D425845DEDFEB7E29EE729AA38C22D473BDC10FABAC311E9BB1233A8E24E9`; legacy `D6BCC37A4327A6103D29CA9D872F62C8E8B463983405B03AD2E95EFD7987A6B0`; source ledger `1CB5EC6EFAEFD55A6BB103C3C87746FEC4D63BA3CF3DF77BC1D763C44A29188A`; repaired renderer `18135DF69456630BDF9602E573AB7E578160A0CA2E88EEA7A11B40685125A222`; negative test `DE4001B84D5CC510518DA41319035453C2B7E6C8711291B45EF78A1CA29B86BA`; checker `7B1ECD54A94BD587E6E68563A1EC411215CE336C995F844017C393F88EB9BAE2`; checkpoint-04 (draft 4) unchanged `D2600ED2E1B6BA61E823CD48A7D424E02C670706F6B9757B5453C5CA3D860DB3`.

Missing or skipped checks: no import, publication, deployment, or MUSIC60/canonical check was authorized.

Concerns/blockers: none for this scoped batch. Live re-open failures for several cited institutional pages were not treated as contrary evidence; their prior received content is recorded in the author’s source ledger and the results above rely only on that stated receipt plus successfully re-opened institutional records.

Usage if exposed: unavailable. Fix rounds: 1 repaired verification gate, independently rechecked. Next action: content owner may perform its separate structural/import review. This FINAL ACCEPT is not a publication or release decision.
