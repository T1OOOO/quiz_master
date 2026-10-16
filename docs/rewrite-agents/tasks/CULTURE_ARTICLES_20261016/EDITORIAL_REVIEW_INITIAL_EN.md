# Independent editorial review — Culture Articles (four-question batch)

Reviewed `articles.json` at SHA-256
`ba4c8f7fa13dd0b202b4f43554df8c71644a18835e4aba06798c81daefa4e2c5`.
This is a same-provider native editorial review. It is useful evidence for a
writer revision, but cannot replace the required different-provider release
acceptance.

## Verdict: REVISE

All four intended answers are correct, all four question-reference hashes match
the authoritative public snapshot, each draft is at least 100 Russian words,
and every article has two cited sources. The corrections below are editorial
precision issues; no canonical answer key or runtime file was changed.

| Article | Independent answer | Verdict | Required revision |
| --- | --- | --- | --- |
| `prep-film-actors2-001` | Judy Garland | Revise | Keep the AFI-supported casting and the Temple casting-history note. Present Dorothy's “inner route” as a learning association or interpretation, not a source-established fact. |
| `prep-film-actors2-002` | Humphrey Bogart | Revise | Correct the option discussion: Bergman is not an option; Rains and Henreid are distractors with roles in the film, while Cary Grant is an option but not in that cast. Separately log the public-stem grammar issue: «кто сыграл Рика Блейна?». |
| `music-oct3-016` | Stephen Sondheim | Revise | Replace bare theatrical «книга» with «либретто (сцены и диалоги)» for Lapine's role. Label the melody/words paragraph as a learning interpretation. |
| `music-oct3-017` | Stephen Sondheim | Revise | Use the same Russian term for Furth's role. Narrow or label the non-linear/“musical reflections” description as interpretation; MTI directly supports the premise and interactions. |

## Evidence checked

- AFI's [*The Wizard of Oz* record](https://catalog.afi.com/Catalog/moviedetails/7892?mobile-app=true&theme=false) credits Judy Garland as Dorothy Gale and records the Kansas/Oz visual treatment and Shirley Temple's casting discussion.
- AFI's [*Casablanca* record](https://catalog.afi.com/Film/27175-CASABLANCA) credits Humphrey Bogart as Rick Blaine, Paul Henreid as Victor Laszlo and Claude Rains as Louis Renault; its synopsis supports the wartime refugee and café context.
- MTI's [*Into the Woods* record](https://www.mtishows.com/into-the-woods) credits James Lapine for the book and Stephen Sondheim for music and lyrics. The [Library of Congress finding aid](https://tile.loc.gov/storage-services/service/gdc/gdcfindingaidpdfs/mu025009/mu025009.pdf) gives the 4 December 1986 workshop and 5 November 1987 Broadway opening.
- MTI's [*Company* record](https://www.mtishows.com/company) credits George Furth for the book and Sondheim for music and lyrics, and gives Robert's 35th-birthday premise. The same Library of Congress finding aid dates the Broadway opening to 26 April 1970.

## Checks

`ConvertFrom-Json articles.json` succeeded. The batch has four unique IDs, four
matching public question references, draft status throughout, two links per
article, and Russian body counts of 170, 171, 167 and 162 words.

No article export, runtime asset, canonical quiz, production DTO, release input
or answer key was altered. Re-review the revised draft before any integration.
