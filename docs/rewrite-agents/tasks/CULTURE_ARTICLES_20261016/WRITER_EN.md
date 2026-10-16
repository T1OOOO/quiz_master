# Culture article draft report — 2026-10-16

## Scope and state

This packet contains four **draft-only** Russian mini articles. It changes no
runtime asset, canonical quiz, source bundle, registry, or publication input.
Each article is bound to the public DTO snapshot in `public-selected.json`, not
to a local content-bundle hash. Native editorial review, independent factual
review, acceptance, export, and publication remain pending.

## Bound public question revisions

| Quiz | Question | Public revision SHA-256 |
| --- | --- | --- |
| `prep-film-actors-2` | `prep-film-actors2-001` | `082b1575cc8deed37a8b17442dc336e77ac7d7c880d2ad0bb99a341de247fff4` |
| `prep-film-actors-2` | `prep-film-actors2-002` | `65a7bae593a00b0d4009ef3d038419d4a126ca948df5f7e01cd87036d92f91ca` |
| `prep-musicals` | `music-oct3-016` | `ca805e55e443d83f1c01f5de6f49f97d2b3c944a9ac123843ff9e003c94b853b` |
| `prep-musicals` | `music-oct3-017` | `4f701224f848e1e3b702f6c05992b5c49bd783954179cb78b96f55bef93f7775` |

The stems and options in `candidate-questions.json` were read for relevance.
No answer or option edit was made.

## Source evidence actually inspected

All links below were opened in the browser on 2026-10-16 and are also recorded
on the relevant article.

| Article | Sources and evidence |
| --- | --- |
| Dorothy / Judy Garland | [AFI film record](https://catalog.afi.com/Catalog/moviedetails/7892?mobile-app=true&theme=false) records Garland as Dorothy Gale and the film’s Kansas/Oz visual treatment. [AFI Garland filmography](https://catalog.afi.com/Person/90673-Judy-Garland) records `THE WIZARD OF OZ — Dorothy [Gale] — 1939`. |
| Rick / Humphrey Bogart | [AFI film record](https://catalog.afi.com/Film/27175-CASABLANCA) records Bogart as Rick Blaine and the wartime café context. [AFI Bogart filmography](https://catalog.afi.com/Catalog/PersonDetails/71928) records `CASABLANCA — Rick Blaine — 1942`. |
| Into the Woods / Stephen Sondheim | [MTI show record](https://www.mtishows.com/into-the-woods) credits James Lapine for the book/libretto and Stephen Sondheim for music and lyrics. [Library of Congress Sondheim Papers finding aid](https://tile.loc.gov/storage-services/service/gdc/gdcfindingaidpdfs/mu025009/mu025009.pdf) records the 1986 workshop and 1987 Broadway opening. |
| Company / Stephen Sondheim | [MTI show record](https://www.mtishows.com/company) credits George Furth for the book/libretto and Sondheim for music and lyrics; it also gives Robert’s 35th-birthday premise and the cited songs. [Library of Congress Sondheim Papers finding aid](https://tile.loc.gov/storage-services/service/gdc/gdcfindingaidpdfs/mu025009/mu025009.pdf) records the 26 April 1970 Broadway opening. |

The film records are scholarly AFI catalog records; the musical credits are
from the official licensing holder and the Library of Congress archive.

## Duplicate and answer review

The exact-ID search across `study/question_articles` and
`docs/rewrite-agents/tasks` found question snapshots and planning annotations,
but no existing question-article draft for the four bindings. `scope.json` also
records `existing_registered_draft_duplicates: []`.

No factual or option error was found in the four current public DTOs. Both
musical questions correctly ask for **music and lyrics**, not for sole
authorship of the whole musical. The drafts therefore distinguish Sondheim’s
role from Lapine’s or Furth’s libretto role. For the Dorothy item, Shirley
Temple is a plausible distractor because she appeared in casting discussion,
but the finished film credits Garland. The Casablanca article now discusses the
actual distractor choices Henreid, Rains, and Grant; it does not treat Bergman
as a candidate option.

## Revision and completed structural checks

`validation-initial.json` preserves the initial article hash
`ba4c8f7fa13dd0b202b4f43554df8c71644a18835e4aba06798c81daefa4e2c5`.
After the editorial revisions, the current `articles.json` SHA-256 is
`12069ba2066852795735c8a0c8508ee789c13a46f1d8fcd35f0fa352a4367768`.
The revisions use Russian theatrical terminology for the librettist, mark the
three reading/memory aids as interpretation, remove the unregistered
`topic:composers` tag, and narrow the Casablanca option discussion.

Structural validation completed after the revision: `articles.json` parses as
JSON; it has four unique article IDs and four exact public DTO references; all
four articles retain `draft` status; each article has two inspected source
links dated 2026-10-16; body word counts remain in the assigned range. A final
native editorial recheck, independent factual review, acceptance, export, and
publication are still pending.
