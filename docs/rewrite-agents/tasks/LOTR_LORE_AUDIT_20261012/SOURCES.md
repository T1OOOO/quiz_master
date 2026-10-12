# LOTR lore audit — source access ledger

- Audit label: `culture-next8-v2-factcheck:lotr-lore-audit-v1`
- Access date: 2026-10-12
- Scope: `lotr-rk-91` through `lotr-rk-100`; `lotr-tt-95`, `lotr-tt-96` only.
- Candidate SHA-256: `390B993DAC0A1FA7B17B84E81CCA378C1EF8CC1873E8BD83E287A0C43FE63C5D`
- Editorial SHA-256: `81DDB98E307542870D120C37E5EAE03CAADD292FA502B7A0573F34A02907727D`
- Source commit supplied by the packet: `1248f6c21d600789d1e3f113aaa9d7a5cb19bd1f`

## Access outcome

The underlying authority for the book items is Tolkien's original text. I could not open a licensed, searchable complete edition in this bounded audit. Penguin Random House's official series page was opened and confirms the three-volume series, but it does not expose the relevant passages. I therefore do **not** call any book fact “primary-source verified” merely because a secondary page cites it. Each record in `audit-v1.json` identifies the needed book, appendix, or chapter locator for a later edition/page check.

An unaffiliated full-text PDF was reached but returned raw PDF data and has no established publisher/rightsholder provenance; it is not relied upon. It should not be added as a content source.

## Opened URLs

| URL | Class | Result and permitted use |
| --- | --- | --- |
| https://www.penguinrandomhouse.com/series/LOR/the-lord-of-the-rings/ | Official publisher | Opened. Confirms the published series and its component volumes only; no passage-level verification. |
| https://www.theonering.net/torwp/2001/02/27/27632-christopher-lee-talks-lotr-8/ | Secondary republication | Opened. Attributes Lee's annual rereading to a Guardian interview and identifies him as Saruman. It is not the Guardian primary interview. |
| https://archives.theonering.net/features/newsroom/files/042902_chrislee.html | Archive/interview transcript | Access failed: robots retrieval/connection failure. Not used as proof. |
| https://tolkiengateway.net/wiki/Anduin | Secondary encyclopedia | Opened. Locator for Anduin/Great River terminology; page itself flags sourcing needs. |
| https://tolkiengateway.net/wiki/Narya | Secondary encyclopedia | Opened. Locator cites *The Return of the King*, “The Grey Havens”, and Appendix B Third Age for Círdan/Narya/Gandalf. |
| https://tolkiengateway.net/wiki/C%C3%ADrdan | Secondary encyclopedia | Opened. Locator for Círdan and Grey Havens references. |
| https://tolkiengateway.net/wiki/Celeborn | Secondary encyclopedia | Opened. Locator for Celeborn/Galadriel/Lórien; not primary proof. |
| https://tolkiengateway.net/wiki/Mithlond | Secondary encyclopedia | Opened in the fetched batch; locator identifies Mithlond as Grey Havens. |
| https://tolkiengateway.net/wiki/Translations_from_the_Elvish | Secondary encyclopedia | Opened. Locator cites the Prologue, “Note on the Shire Records”, for Bilbo's translations. |
| https://tolkiengateway.net/wiki/Paladin_Took_II | Secondary encyclopedia | Opened. Locator cites Appendix C, “Took of Great Smials”, for Peregrin's parentage. |
| https://tolkiengateway.net/wiki/Naugrim | Secondary encyclopedia | Opened. Locator for Naugrim/Khazâd terminology; page flags sourcing needs. |
| https://www.tolkienfile.com/races/corsairs-of-umbar | Secondary encyclopedia | Opened through search result. Locator for black-sailed Umbar fleet/Pelargir; not primary proof. |
| https://tolkiengateway.net/wiki/The_Black_Ships | Secondary encyclopedia | Located in search. It distinguishes theatrical and extended film scenes; an official film/cut source was not opened. |

## Direct-text repair targets

- `lotr-rk-92`: *The Return of the King*, Appendix B, “The Tale of Years”, Third Age, T.A. 2941.
- `lotr-rk-93`: name the period/place; check Anduin in *The Lord of the Rings* versus Sirion in First-Age material before retaining the current option set.
- `lotr-rk-95`: *The Return of the King*, “The Grey Havens”.
- `lotr-rk-96`: *The Return of the King*, Pelargir/Black Fleet passages; identify a specific theatrical or extended film cut before saying “book and film”.
- `lotr-rk-98`: Appendix B, Third Age and/or *The Return of the King*, “The Grey Havens”.
- `lotr-rk-99`: Prologue, “Note on the Shire Records”.
- `lotr-rk-100`: Appendix C, “Took of Great Smials”.
- `lotr-tt-95`: *The Silmarillion*, appendix “Elements in Quenya and Sindarin Names” (entry `aran`), if that is the intended source.
- `lotr-tt-96`: name the language/register and give the exact canonical source.

No source, canonical content, tag registry, build, or publication file was changed.
