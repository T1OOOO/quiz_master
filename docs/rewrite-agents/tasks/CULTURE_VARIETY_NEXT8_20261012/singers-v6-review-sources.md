# CULTURE NEXT8 singers v6 — independent source review

Review date: 2026-10-12
Input: `singers-v6.json`
Input SHA-256: `1C3C907F60C39A4877A8BF0DA17E25DCA3132D49B358F55F36F5E0CA12F62880`
Reviewer: `culture-next8-v2-factcheck` / `session-79f42d8274ac4d6aa02cbdfc60df567f`

## Direct source access

| Record | Primary URL opened directly | Outcome | Verified support |
| --- | --- | --- | --- |
| next8v6-singer-01 | https://assets.moma.org/documents/moma_press-release_389534.pdf | Accessible | The PDF says the Biophilia app, acquired by MoMA's Architecture and Design department, was the first app to enter the collection. It lists the Tesla coil, Gravity Harps, gameleste, and pipe organ as Biophilia instruments programmed to play Björk-composed music and sounds. |
| next8v6-singer-01 | https://shop.bjork.com/products/bjork-biophilia | Accessible | The official store calls Biophilia an interdisciplinary exploration where music, nature, and technology meet. |
| next8v6-singer-02 | https://www.queenonline.com/freddie_mercury | Accessible | Official Queen biography gives Farrokh Bulsara and Zanzibar, then the 1964 Middlesex move, Ealing College of Art study, and link to Taylor and May. |
| next8v6-singer-02 | https://freddiemercury.com/bio/ | Accessible | Official biography says he was born Farrokh Bulsara in Zanzibar and had piano lessons at St Peter's boarding school in Bombay. |
| next8v6-singer-02 | https://www.penguinreaders.co.uk/wp-content/uploads/2020/04/PR_L5_FreddieMercury_AnswerKey.pdf | Accessible; conflict recorded | Its answer text says St Peter's School was in Panchgani, southeast of Mumbai. This conflicts with treating Bombay as the school's precise city. |

The standard PDF-to-Markdown converter reported HTTP 403, but this does not describe the source URL's availability: the MoMA PDF itself was fetched directly and its text independently extracted in memory.

## Record decisions

| Record | Verdict | Reason |
| --- | --- | --- |
| next8v6-singer-01 | **ACCEPT** | Both sources are accessible and support every factual claim. The four real Björk titles are comparable; only Biophilia is the first app in MoMA's collection, with no material length cue. |
| next8v6-singer-02 | **REVISE** | The birth name and the article's broader biography are supported, and its teaching prose is now substantive. Replace the city-level school statement: the cited official bio says Bombay, but a directly opened Penguin Readers answer key identifies St Peter's School in Panchgani, southeast of Mumbai. «В Индии» is supported by the Queen biography and avoids the conflict. |

## Checks and limits

- This is **not a blind-solve review** because the supplied JSON contained the answer keys.
- Article-body counts are 111 and 116 words, within the 100–150 requirement.
- `domain:arts` is an existing player-safe tag in `metadata/tags.v1.json`.
- Targeted stable-content searches in `quizzes`, `categorized`, and `quizipedia` found no Biophilia or Farrokh/Bulsara duplicate. This is a bounded check, not a full-bank audit.
- No author/runtime file was changed. No import, build, Git, publication, or deployment action occurred.
