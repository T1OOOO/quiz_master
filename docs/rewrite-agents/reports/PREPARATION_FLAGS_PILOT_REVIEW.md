# Flags pilot — independent review

Status: **ACCEPT** — final frozen pilot re-review completed; this is review evidence, not publication or import.

## Blind solve record

The candidate file and all 20 linked local PNGs were read/viewed before the editorial key or legacy record.

| Stable ID | Blind answer |
|---|---|
| flag-9a42e01 | A — Япония |
| flag-2f7c8b3 | B — Швеция |
| flag-c51d4e8 | C — Норвегия |
| flag-61b0a29 | D — Финляндия |
| flag-e83a6f0 | A — Дания |
| flag-04d9b72 | B — Исландия |
| flag-7de30c4 | C — Швейцария |
| flag-b1e5f96 | D — Франция |
| flag-36c91a5 | A — Италия |
| flag-a70d2c6 | B — Германия |
| flag-d48e7a1 | C — Польша |
| flag-8c63d40 | D — Эстония |
| flag-15fa8c2 | A — Латвия |
| flag-f2a64b9 | B — Литва |
| flag-93e1d57 | C — Украина |
| flag-4bd07e3 | D — Греция |
| flag-6a29f0d | A — Турция |
| flag-c84e15b | B — Израиль |
| flag-0e76c4a | C — Канада |
| flag-5d18ba4 | D — Бразилия |

Initial visual observation (superseded): the first candidate revision formed the exact repeating sequence A, B, C, D five times. The frozen re-review below verifies that this was corrected.

## Final item verdicts

| Stable ID | Verdict | Independent finding |
|---|---|---|
| flag-9a42e01 | REVISE | Japan image/answer/explanation are correct; revise its position as part of the A-B-C-D answer cycle. |
| flag-2f7c8b3 | REVISE | Sweden is unambiguous from the blue field and yellow Nordic cross; revise cyclic position. |
| flag-c51d4e8 | REVISE | Norway is unambiguous from the blue cross inside white on red; revise cyclic position. |
| flag-61b0a29 | REVISE | Finland is unambiguous from blue cross on white; revise cyclic position. |
| flag-e83a6f0 | REVISE | Denmark is unambiguous from plain white cross on red; revise cyclic position. |
| flag-04d9b72 | REVISE | Iceland is unambiguous from the red inner cross on blue; revise cyclic position. |
| flag-7de30c4 | REVISE | Switzerland is unambiguous from the square red field and white cross; revise cyclic position. |
| flag-b1e5f96 | REVISE | France is unambiguous from blue-white-red vertical tricolour; revise cyclic position. |
| flag-36c91a5 | REVISE | Italy is unambiguous from green-white-red vertical tricolour; revise cyclic position. |
| flag-a70d2c6 | REVISE | Germany is unambiguous from black-red-gold horizontal tricolour; revise cyclic position. |
| flag-d48e7a1 | ACCEPT | Poland is unambiguous: its white band is above red, whereas Indonesia and Monaco are red above white. The prior aspect-ratio concern was incorrect and is withdrawn. |
| flag-8c63d40 | REVISE | Estonia is unambiguous from blue-black-white bands; revise cyclic position. |
| flag-15fa8c2 | REVISE | Latvia is unambiguous from dark-red/white/dark-red bands; revise cyclic position. |
| flag-f2a64b9 | REVISE | Lithuania is unambiguous from yellow-green-red bands; revise cyclic position. |
| flag-93e1d57 | REVISE | Ukraine is unambiguous from blue over yellow; revise cyclic position. |
| flag-4bd07e3 | REVISE | Greece is unambiguous from stripes and canton cross; revise cyclic position. |
| flag-6a29f0d | REVISE | Turkey is unambiguous from crescent and star without Tunisia's white disk; revise cyclic position. |
| flag-c84e15b | REVISE | Israel is unambiguous from two blue bands and central six-pointed star; revise cyclic position. |
| flag-0e76c4a | REVISE | Canada is unambiguous from maple leaf and red side bands; revise cyclic position. |
| flag-5d18ba4 | REVISE | Brazil is unambiguous from yellow diamond, blue globe, band and stars; revise cyclic position. |

## Cross-check evidence

- I solved `candidate.md` and viewed every one of its 20 local PNGs before opening `editorial-key.md` or `legacy.json`; the blind answers matched all intended answers.
- Candidate, editorial key, legacy and coverage agree on 20 unique stable IDs, the displayed options and intended country/answer. Legacy counts are A/B/C/D = 5/5/5/5; coverage prints the same mapping.
- Final re-review: option orders were synchronized across candidate/key/legacy/coverage; answer indices are `0,2,1,3,2,0,3,1,1,3,0,2,3,1,2,0,2,0,3,1`, so the former `A,B,C,D` ×5 player cue is absent while counts remain 5/5/5/5.
- Every candidate local filename is its actual SHA-256: 20/20 PNGs exist and all 20 `Get-FileHash` values equal the corresponding 64-hex filename. The private key maps the same SHA values to JP, SE, NO, FI, DK, IS, CH, FR, IT, DE, PL, EE, LV, LT, UA, GR, TR, IL, CA and BR, respectively.
- All 20 Flagpedia direct PNG URLs declared by the key returned HTTP 200 with `image/png` on 2026-10-03. This supports media availability, while the local SHA checks bind the reviewed pixels to the candidate. It does not make Flagpedia a primary legal or country-identity authority.
- Final legacy schema check: each record has `type: "choice"`, a non-empty `text`, and exactly one `media` object with `kind: "image"`, neutral `alt: "Флаг страны"`, and opaque `https://quiz.kotopedia.org/flags/<sha256>.png` URI. It contains no former top-level `kind`, `stem`, or `alt` fields. All visual explanations correctly describe the reviewed features.

### Input fingerprints

- `candidate.md`: `32049ecd3d810934a791805641112e2a84a829ca2c0afea6a410363497467052`
- `editorial-key.md`: `3eae29f8f6eb729d633d843401ee4e27f8c1e120c8afb2e2b5fabc62b44698de`
- `legacy.json`: `56d57dc4d17710072883e245f7428be8f9d07803885b6e3f2c63ab41c5813739`
- `coverage.md`: `4d1514fb5584a86c6a848a105acd011f2348a6b55fc4fbf0467ea7c11a93e814`

## Final frozen re-review — supersedes the original per-item position findings

| Stable IDs | Final verdict | Recheck result |
|---|---|---|
| flag-9a42e01, flag-2f7c8b3, flag-c51d4e8, flag-61b0a29, flag-e83a6f0 | ACCEPT | Candidate/key/legacy/coverage answer and option parity verified; no positional-cycle cue. |
| flag-04d9b72, flag-7de30c4, flag-b1e5f96, flag-36c91a5, flag-a70d2c6 | ACCEPT | Candidate/key/legacy/coverage answer and option parity verified; no positional-cycle cue. |
| flag-d48e7a1, flag-8c63d40, flag-15fa8c2, flag-f2a64b9, flag-93e1d57 | ACCEPT | Poland correction applied; all image-country distinctions and explanations remain factual. |
| flag-4bd07e3, flag-6a29f0d, flag-c84e15b, flag-0e76c4a, flag-5d18ba4 | ACCEPT | Candidate/key/legacy/coverage answer and option parity verified; media remains neutral and opaque. |

Final structural counts: 20 legacy records, 20 unique IDs, 20 coverage rows, 20 `type:choice`/`text` records, and 20 one-element image-media arrays; zero old-shape or media-schema errors.

### Exact local-media SHA-256 binding

| ID | SHA-256 |
|---|---|
| flag-9a42e01 | `d70de87c9b178bf7a4ce09478eb8375df20bafa16d50e34b837f471f2daff8e6` |
| flag-2f7c8b3 | `475c1e628d62b218b10b7581fec823056789c1d9daf6c01d6e54796fc9256887` |
| flag-c51d4e8 | `22a09e44d8121d2ab152b714d1ecef35da50d5c878f9e3f501699e691cb22aca` |
| flag-61b0a29 | `e109f87f56b559b3d4497be214e902a702b4a656852029fa89820d9c249021dc` |
| flag-e83a6f0 | `c2d1f782feb85e9f3a91d02e2518284e523e8d66fe711161ae0eae32051bd17e` |
| flag-04d9b72 | `49e20da9b264d9719bfb766876fe4322837ecc35bb2e737742055a380d9dc697` |
| flag-7de30c4 | `5af6c932b78ce18b0253f516f8f3c74a0e333287e6848e7afc055104065d0693` |
| flag-b1e5f96 | `d1bdc5f08a3d7290376cfc0dcd33c9604e1b5e5cbea3143cdc02da85fddf22f5` |
| flag-36c91a5 | `d50c6434f7f34424dd524d3535cea21725ed72ea66c706d964f0643e91c17227` |
| flag-a70d2c6 | `7fc1961f8730109eebd4569961349dbd39081e3b256007bceda3e5074198b988` |
| flag-d48e7a1 | `c5703c9d89f1d04249636445d6a5b7304f53138c226219f4f4e43dae6d88ee77` |
| flag-8c63d40 | `2253b34cdf1ae595320f2a1c7347a3cf3ad5ff4fdcff7fcdd6febc9e845a6bbe` |
| flag-15fa8c2 | `0cc124f49c3d28fb02ae46cece1cb2643d51dc406f7f37c5f4911447d87317b0` |
| flag-f2a64b9 | `1146487ae5c3467f355d9f6199ab155a6dba17dc228dfd4fb2e84128616ee415` |
| flag-93e1d57 | `b7f4d28611b207b8e713540c104a7f127c1936eb03c1b9cb38de70938ace274b` |
| flag-4bd07e3 | `76e348051d4252b06feebb816ba386169600a77fbeff1724645efcd2fa364b46` |
| flag-6a29f0d | `e50ad4feb4f7d0f03348415bec20ccf61049d3d08968ae175d1c7cb5d98f3a3a` |
| flag-c84e15b | `7eceedb3e274ed48f38686c24ed5b95e5c42f9b5f99800324a2b9be962c6cbf9` |
| flag-0e76c4a | `85490776a6998e472e5928719f44ab6e352f5ead15508b6995c931b17053b95a` |
| flag-5d18ba4 | `76f921bcec127a82ac23e7d46eabbe4780c32cbd5447574f984b7e2115ef9750` |

No source draft was edited. This report is a review finding, not publication or acceptance.
