# Stage-musical article draft report — 2026-10-16

## Scope and state

This packet contains four private, draft-only Russian learning articles. It
changes no quiz question, answer, option, runtime asset, canonical content,
registry, release input, or publication target. Native checking and independent
acceptance remain pending.

## Bound public question revisions

| Quiz | Question | Public revision SHA-256 |
| --- | --- | --- |
| `prep-musicals` | `music-oct3-011` | `314ad3b40c8a970e0d01eac0e75fb0284e79710dc595a534e26c429eb4e10772` |
| `prep-musicals` | `music-oct3-012` | `dfb7c7734bfe9b65cd85588c3334ae42c7fbf321cfcccf94befc26668af5c3d6` |
| `prep-musicals` | `music-oct3-014` | `4ed701b098e2edcb98dd68c28c56d29d0548b684d35f7d4536430c4312ad219c` |
| `prep-musicals` | `music-oct3-018` | `474b8a784405a8f273e7c206f30e23ad01b8d5829077325f8abd2c4e0057c34a` |

The public stems and all answer options in `candidate-questions.json` were
read. No question, key, or option was edited. These are the public snapshot
revisions, rather than revisions from a local content bundle.

## Inspected primary evidence

All listed sources were opened on 2026-10-16 before drafting.

| Article | Sources and evidence |
| --- | --- |
| Cats | [Concord’s licensed record](https://www.concordtheatricals.com/s/44850/cats-lloyd-webber?variantId=138537) credits Andrew Lloyd Webber for music, identifies Eliot’s source poems, and records the stated extra text material. [Andrew Lloyd Webber Musicals](https://www.andrewlloydwebber.com/show/cats) gives the original London premiere date. [The Tony Awards](https://www.tonyawards.com/winners/year/1983/category/any/show/cats/) independently records the score credit. |
| Jesus Christ Superstar | [Concord’s licensed record](https://www.concordtheatricals.com/s/44748/jesus-christ-superstar) separates Rice’s lyrics and Lloyd Webber’s music and describes the through-sung dramatic approach. [Andrew Lloyd Webber Musicals](https://www.andrewlloydwebber.com/show/jesus-christ-superstar) records the early album development through music and lyrics. |
| Starlight Express | [Andrew Lloyd Webber Musicals](https://www.andrewlloydwebber.com/show/starlight-express) records the 1982 development and the 1984 London world premiere. [Concord’s 2024 licensed record](https://www.concordtheatricals.com/p/44581/starlight-express-2024-lloyd-webber) separately credits Lloyd Webber for music and Richard Stilgoe for lyrics; it is expressly treated as a later-version supplementary record. |
| Sweeney Todd | [Music Theatre International](https://www.mtishows.com/sweeney-todd) credits Hugh Wheeler for the libretto and Stephen Sondheim for music and lyrics. [The Tony Awards](https://www.tonyawards.com/winners/year/1979/category/any/show/any/) independently records the same division in its 1979 book and original-score entries. |

## Drafting decisions

Each article is 150–220 Russian words, has two or three opened source links,
uses only `domain:arts` and `topic:musical-theatre`, and is marked `draft`.
The text uses the Russian theatrical term “либретто.” It distinguishes original
stage work from album origins, later licensed editions, revivals, and screen
adaptations where that distinction bears on the question. It does not add
unsupported award totals, casting trivia, or a claim that any later revision is
the original work.

The cited 2024 Concord `Starlight Express` page is not used as evidence for the
1984 production history; its role is only supplemental confirmation of the
music/lyrics credit split for a later licensed version. The 1982/1984 history is
supported by the Andrew Lloyd Webber source.

## Completed structural verification

After saving, a PowerShell validation parsed `articles.json` and confirmed the
schema, four unique article IDs, all four exact public references and SHA-256
revisions, `draft` status, the two permitted tags, two-to-five sources per
article, and the `2026-10-16` access date. Russian body-word counts were:

| Question | Words | Sources |
| --- | ---: | ---: |
| `music-oct3-011` | 178 | 3 |
| `music-oct3-012` | 169 | 2 |
| `music-oct3-014` | 180 | 2 |
| `music-oct3-018` | 174 | 2 |

`articles.json` SHA-256 after this validation is
`05647a11b0078b6131ccdd387ece60977828ee8a46244be81169a35b8cd62903`.
The companion report checksum is recorded with the final handoff. Native factual
checking, independent review, acceptance, export, and publication remain
pending.

## Narrow editorial repair

Before native review, the Jesus Christ Superstar draft changed “записи
правообладателя” to “лицензионной карточке Concord”; the source establishes a
licensing credit card, not copyright ownership. The Sweeney Todd draft now adds
source-supported context from the already opened MTI page: it calls the work a
musical thriller about a barber returning to nineteenth-century London to seek
revenge on the judge who framed him. No other article reference, tag, status,
or source URL changed. The pre-repair `articles.json` SHA-256 was
`05647a11b0078b6131ccdd387ece60977828ee8a46244be81169a35b8cd62903`;
post-repair validation passed with `articles.json` SHA-256
`ec8bdc0008c7bcba83ea9d1ce1aa9f5a526cbc23233f2622e2dc0303e993a263`.
Post-repair word/source counts are 178/3, 170/2, 180/2, and 179/2 in question
order. JSON parse, exact public revision binding, draft status, allowed tags,
source dates, and article bounds were all rechecked.
