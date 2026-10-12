# CULTURE NEXT8 singers v4 — independent source review

Review date: 2026-10-12
Input: `singers-v4.json`
Input SHA-256: `DF6FEC149517529884544CBFDC0913A200B83957BCA57D2E30067B6BF9B780CB`
Reviewer: `culture-next8-v2-factcheck` / `session-79f42d8274ac4d6aa02cbdfc60df567f`

## Direct source access

| Record | Primary URL opened directly | Outcome | What it supports |
| --- | --- | --- | --- |
| next8v4-singer-01 | https://www.moma.org/explore/inside_out/2014/06/11/biophilia-the-first-app-in-momas-collection/ | **HTTP 403** | Nothing accepted from this inaccessible page. It was intended to support the hybrid tablet app, interactions, and Solstice detail. |
| next8v4-singer-01 | https://shop.bjork.com/products/bjork-biophilia | Accessible | The official store describes *Biophilia* as an interdisciplinary exploration where music, nature, and technology meet. It does not establish the MoMA-specific tablet/app mechanics. |
| next8v4-singer-02 | https://www.queenonline.com/freddie_mercury | Accessible | Official Queen page identifies Farrokh Bulsara, Zanzibar, and the later London/Queen context. |
| next8v4-singer-02 | https://freddiemercury.com/bio/ | Accessible | Official biography says he was born Farrokh Bulsara in Zanzibar and took piano lessons at St Peter's boarding school in Bombay. |

## Record decisions

| Record | Verdict | Reason |
| --- | --- | --- |
| next8v4-singer-01 | **HOLD** | The MoMA source required for central factual claims returned HTTP 403. The keyed option is 38 characters versus 21 and 22 for two distractors, and the concert distractor is a different type of thing from the media-format answers. |
| next8v4-singer-02 | **REVISE** | The official sources support the key and all factual biography claims, and the options are unique with no material length cue. The final two article sentences merely expose and explain the distractor set; replace them with sourced biographical context before acceptance. |

## Boundaries and checks

- This is **not a blind-solve review**: the supplied file exposed its answer key before assessment.
- Article-body counts are 106 and 111 words, within the required 100–150 range.
- `domain:arts` is an existing player-safe tag in `metadata/tags.v1.json`.
- Targeted stable-content searches in `quizzes`, `categorized`, and `quizipedia` found no Biophilia or Farrokh/Bulsara duplicate. This is a bounded check, not a full-bank audit.
- No author/runtime file was changed. No import, build, Git, publication, or deployment action occurred.
