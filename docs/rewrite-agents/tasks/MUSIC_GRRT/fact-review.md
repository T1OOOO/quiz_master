# Independent factual review — MUSIC_GRRT

**Packet label:** `music-facts-grrt`
**Reviewed asset SHA-256:**

- `music_learning.json` — `07F59C7B2DE26C5E6F107C85678D544D163044B716C4DBFA3A95956318E63105`
- `country_culture.json` — `43D4680FC08E75B3106C96C88C57CBDF999DFD7354AE6833FF9351704AA3E7EB`

**Verdict:** **REVISE — do not import yet.** The music facts, country
relations, glyph mapping, and all 28 intended keys are correct, but source
provenance and answer-position fairness need the concrete repairs below.

## Method and source evidence

I read and answered every question from its English stem, options, and visual
metadata before using `correct_id`, then compared my answers to the stored key.
All 28 match. I opened the cited Open Music Theory notation/rhythm/meter,
scales, intervals, and triads pages; the Met essay; the Ministry of Foreign
Affairs of Japan's Web Japan page; Bath Spa University's Mbira Hut; UNESCO's
Duduk, Gamelan, Angklung, and Flamenco material; and current Philharmonia
instrument pages where available. The reviewed claims are supported as follows:

- Open Music Theory establishes clef-dependent pitch placement, accidentals,
  proportional durations, dots/ties, compound `6/8`, scale patterns, interval
  terminology, and triads. The cited `meter` page specifically describes
  compound duple metre as two beats divided into three and explains why `6/8`
  has dotted-quarter beats rather than six main beats.
- The seven visual note coordinates correctly encode C4 through B4 in treble
  clef: C4 is on the ledger line below; D4 below the staff; E4 on the bottom
  line; F4 in the first space; G4 on the second line; A4 in the second space;
  B4 on the middle line. There is no octave or line-count error.
- The cards correctly limit duration examples to `4/4` where needed, identify
  a quarter note as the beat unit only in that meter, call `6/8` *usually*
  compound duple, state that dynamics are relative, state that Italian tempo
  words do not set a universal BPM, and leave fermata duration to performance.
- The UNESCO and institutional pages support the non-exclusive country wording:
  duduk is Armenian and also related to regional aerophones; angklung is
  Indonesian and requires cooperating players for melodies; mbira is presented
  in a Shona Zimbabwean tradition; tango is Argentine and Uruguayan; and
  Aitysh/Aitys is shared by Kazakhstan and Kyrgyzstan. The asset does not claim
  that any of these traditions belongs only to one country.

The recorded `performance` URL returned HTTP 403. I did not retry or attempt to
bypass it. An accessible same-host Open Music Theory edition,
`https://viva.pressbooks.pub/openmusictheorycopy/chapter/other-aspects-of-notation/`,
does support the dynamics, tempo, articulation, repeat/segno/coda, and
performance facts (including the intended relative/performance caveats).

## Required repairs

1. **Balance the answer positions.** The 28 correct options occur at positions
   `0:5`, `1:6`, `2:12`, and `3:5`. Seven visual-note questions all place the
   answer at index 2, creating an obvious pattern. Keep each `correct_id`, but
   reorder, for example, `q-note-0` and `q-note-1` to index 0, `q-note-2` to
   index 1, and `q-note-3` to index 3. That produces exactly seven correct
   options at each index 0–3 while preserving four distinct options per
   question. Record the final four-way distribution in the recheck evidence.

2. **Repair the unavailable `performance` source record.** Its current URL is
   the 403 page used by 26 cards and six questions (`q-crescendo`,
   `q-ritardando`, `q-p`, `q-staccato`, `q-fermata`, `q-pizzicato`). Replace it
   with the accessible Open Music Theory edition above (and update its title if
   the registry title would otherwise name a different edition). This is a
   provenance repair; the factual descriptions and keys do not need changing.

3. **Make the culture sources claim-specific.** A sorted generic UNESCO list
   cannot substantiate three unrelated entries, and the current generic dombra
   list cannot substantiate the instrument/kuy description. Apply these exact
   source changes in both assets wherever the source IDs are referenced:

   | Affected ID(s) | Required source repair |
   |---|---|
   | `dombra`, country `KZ/dombra`, `dombra-source` | Point `dombra-source` to `https://ich.unesco.org/en/RL/traditional-art-of-dombra-kuy-in-kazakhstan-00996`. UNESCO's record identifies it as a solo composition on a traditional long-necked two-stringed plucked dombra in Kazakhstan. |
   | `tango`, countries `AR/tango` and `UY/tango` | Add `tango-source` at `https://ich.unesco.org/en/RL/tango-00258`, assign it to the entry and both country relations, and remove their use of `heritage-source`. |
   | `aitysh`, countries `KZ/aitysh` and `KG/aitysh` | Add `aitysh-source` at `https://ich.unesco.org/en/RL/aitysaitys-art-of-improvisation-00997`, assign it to the entry and both country relations, and remove their use of `heritage-source`. It explicitly describes improvised oral poetry with dombra/komuz accompaniment in Kazakhstan and Kyrgyzstan. |
   | `bagpipe-culture`, country `SK/bagpipe-culture` | Add `bagpipe-source` at `https://ich.unesco.org/en/RL/bagpipe-culture-01075`, assign it to the entry and country relation, and remove its use of `heritage-source`. It expressly names repertoire, songs, dances, instrument-making, and Slovakia. |

   Remove `heritage-source` once it has no consumers. The current generic list
   URL is not a direct record for any of these claims. These are source-identity
   repairs, not changes to the non-exclusive relation language.

## Glyph and structural checks

- All 24 numeric glyphs map exactly to the supplied
  `smufl-glyphnames.json`: `gClef` E050, `fClef` E062, `cClef` E05C;
  accidentals E260–E264; noteheads E1D2/E1D3/E1D5/E1D7/E1D9; rests
  E4E3–E4E7; `articStaccatoAbove` E4A2, `articAccentAbove` E4A0,
  `fermataAbove` E4C0; and `repeatRight` E041, `segno` E047, `coda` E048.
  The visual text and `note: 0..6` fields also conform to the packet.
- `music_learning.json` has 31 source records, 95 entries, and 28 questions.
  Each question has four distinct option IDs, contains its `correct_id`, and
  every referenced source ID resolves in the registry. `country_culture.json`
  has 16 associations across 11 ISO country keys. The shared tango and Aitysh
  links appear in every appropriate country and no relation says “exclusive.”

## Question-by-question verdict

Every blind answer agrees with the current stored key. `source repair` means
the answer is factually sound but its cited registry record must be repaired as
specified above. `Position repair` refers to the explicit balancing plan above.

| Question | Blind answer / stored key | Verdict |
|---|---|---|
| `q-note-0` | C4 / `note-0` | Position repair. |
| `q-note-1` | D4 / `note-1` | Position repair. |
| `q-note-2` | E4 / `note-2` | Position repair. |
| `q-note-3` | F4 / `note-3` | Position repair. |
| `q-note-4` | G4 / `note-4` | Correct; retain after the global distribution repair. |
| `q-note-5` | A4 / `note-5` | Correct; retain after the global distribution repair. |
| `q-note-6` | B4 / `note-6` | Correct; retain after the global distribution repair. |
| `q-sharp` | sharp / `sharp` | Accept. |
| `q-flat` | flat / `flat` | Accept. |
| `q-natural` | natural / `natural` | Accept. |
| `q-whole` | whole note / `whole` | Accept; duration wording is context-safe. |
| `q-eighth` | eighth note / `eighth` | Accept. |
| `q-dot` | augmentation dot / `dot` | Accept. |
| `q-tie` | tie / `tie` | Accept. |
| `q-meter68` | 6/8 meter / `meter68` | Accept; “usually” avoids an overgeneralization. |
| `q-crescendo` | crescendo / `crescendo` | Source repair. |
| `q-ritardando` | ritardando / `ritardando` | Source repair. |
| `q-p` | piano dynamic / `p` | Source repair. |
| `q-staccato` | staccato / `staccato` | Source repair. |
| `q-fermata` | fermata / `fermata` | Source repair; performance discretion is correctly qualified. |
| `q-pizzicato` | pizzicato / `pizzicato` | Source repair. |
| `q-oboe` | oboe / `oboe` | Accept. |
| `q-trombone` | trombone / `trombone` | Accept; “usually” correctly permits valve trombones. |
| `q-piano` | piano / `piano` | Accept. |
| `q-duduk` | duduk / `duduk` | Accept. |
| `q-angklung` | angklung / `angklung` | Accept. |
| `q-koto` | koto / `koto` | Accept. |
| `q-triad` | triad / `triad` | Accept. |

## Recheck condition

Provide both new asset SHA-256 values after the three repairs. I will recheck
only the changed source assignments, the four reordered option lists, source-ID
resolution across both assets, and the resulting answer-position distribution.
This report does not approve canonical import, UI behavior, builds, source
rights, or publication.

---

## Final recheck — repaired assets

**Music asset SHA-256:**
`4EB3639F9965CD1168F03EE4308FBA0EF9CBA4010255EDC383B23F8886B8E0B2`
**Country asset SHA-256:**
`6F43C0279AB17FA3D7001C567E75BD1FC706EB28CC1A7FBBB8205056FDFB1617`
**Final factual verdict:** **ACCEPT for the reviewed assets.**

I rechecked the changed scope against these exact bytes rather than relying on
the implementation report:

- `performance` now uses the accessible Open Music Theory copy edition that I
  opened during the original review. Its title and URL match the dynamics,
  tempo, articulation, fermata, and structural-notation claims it carries.
- `dombra-source` now points to the direct UNESCO Dombra Kuy record. Dedicated
  `tango-source`, `aitysh-source`, and `bagpipe-source` records now point to
  their respective direct UNESCO records; `heritage-source` is absent. Both
  `music_learning.json` entries and all six corresponding country relations use
  the new exact IDs.
- Correct options are exactly seven at each index 0, 1, 2, and 3. The five
  changed note questions retain the verified facts and keys: `q-note-0`/C4 and
  `q-note-1`/D4 at index 0, `q-note-2`/E4 at index 1, and `q-note-3`/F4 plus
  `q-note-4`/G4 at index 3. Each question still has four distinct options and
  contains its `correct_id`.
- All entry, question, and country relation source IDs resolve in the revised
  music source registry. The original 95-entry/28-question content, the 16
  country associations across 11 country keys, the verified C4–B4 visual
  positions, and the SMuFL mapping remain intact.

This is factual and provenance acceptance only. It does not approve canonical
import, runtime behavior, UI, builds, rights, or publication.
