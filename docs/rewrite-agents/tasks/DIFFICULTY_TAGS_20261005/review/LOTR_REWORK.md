# LOTR rework independent review

**Reviewer label:** `review-lotr-rework-20261005`
**Frozen source revision:** `e802ed21db936bdb9809bab2d137903eb0aa425e`
**Scope:** `annotations/lotr-reworked.json`, its report, the four frozen LOTR
quiz sources, `INVENTORY.json`, `CONTRACT.md`, `RUBRIC.md`, and the current
403-tag dictionary. No production files were edited. No network, browser,
provider, or heavyweight check was used.

## Verdict

**Requirements: ACCEPT.** The rework covers the exact four-source, 253-record
scope; uses the frozen `qm-tags-v1` identity/hash; retains the required
annotation shape; and records ambiguity as private flags/confidence rather
than converting it into a score of 10.

**Annotation quality: ACCEPT.** I independently read the raw stem, every
option, keyed answer, and explanation for all 29 flagged records (including
all four low-confidence records), plus a deterministic 30-record unflagged
sample. The scores, tag specificity, safe-context subset, rationale, and
flagging are coherent with the stated rubric. I found no required correction.

This is a review of annotation semantics. It does **not** independently verify
the factual truth of all 253 original questions or certify their keys.

## Frozen inputs and mechanical evidence

| Input | SHA-256 observed | Result |
| --- | --- | --- |
| `quizzes/Cinema/LOTR/lotr.json` | `ea5c763bd578805d9200fef2edf86883916ead4588f3693e024ae1bac8b7d79a` | matches inventory |
| `lotr_fellowship_100.json` | `eb20f18f0736c1467d825b5385b610cb582d02d82bd28c321850b8f829e5e184` | matches inventory |
| `lotr_return_king_bts_100.json` | `da496ad3af3dcf3e33276639bd63b64a84de421229fb77f97d8c295e13571f5c` | matches inventory |
| `lotr_two_towers_lore_100.json` | `73265066f54e43d6d124f63036ab1382f88ad1ef955fe7a69ba76eee0bbe5ea4` | matches inventory |
| `annotations/lotr-reworked.json` | `8da54a8916c23cbfba6a627ee9ee49f020737b4eed5beeebd485e1103eab8b69` | reviewed output |
| `annotations/lotr-reworked-report.md` | `d2a5449be05bbcf587eead10567fab8f31b349474dbb799cb4e077cf10b4ccd8` | reviewed report |
| `metadata/tags.v1.json` | `eb91c227bd4d08ee2dee5083bd99c4df77bd15f85aae37d3aa0879937c55ad35` | current 403-tag dictionary |

The annotation envelope and dictionary both declare `qm-tags-v1` with
taxonomy hash `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`.

Text/JSON checks performed:

- 253 raw records; 253 annotation records; 253 unique annotation IDs; no
  missing or extra IDs across the four packs (3 + 50 + 100 + 100).
- All records have the required provider, pack/question IDs, score in 1..10,
  nonempty rationale, permitted confidence, sorted unique tag arrays, known
  taxonomy IDs, at least one domain and one franchise/topic, and safe context
  as an editorial-tag subset.
- No context tag uses a default-private country, ingredient, place, cuisine,
  or person facet. Person tags appear only in private editorial metadata.
- Score distribution is 2:17, 3:28, 4:41, 5:37, 6:54, 7:53, 8:21, 9:2;
  the eight available score levels are represented in the sample below.
- There are exactly 29 flagged records and exactly 4 low-confidence records.

The source hashes are the preservation evidence for original stems, option
order, keys, explanations, IDs, and source metadata. I also read those exact
raw fields for every mandatory and sampled record.

## All flagged and low-confidence records

Each row was read against the raw source's stem, complete option array, keyed
answer, and explanation. `OK` means the annotation describes the visible
question/announced pack context and the stated difficulty reasoning; it does
not authenticate the underlying fact.

| Record | Score | Confidence | Flag(s) | Result |
| --- | ---: | --- | --- | --- |
| `lotr_f_11` | 4 | high | book-vs-film-canon-boundary | OK: explicit film wording and the Glorfindel alternative justify film context and comparison. |
| `lotr_f_35` | 7 | medium | medium-not-explicit; translation-boundary | OK: English-original wording supports no medium tag and the boundary flag. |
| `lotr_f_44` | 5 | medium | option-elimination | OK: book/prologue is visible; extreme metric options lower a quantitative recall question. |
| `lotr_rk_16` | 6 | medium | book-episode-version-unspecified | OK: Sam-as-mayor is a book-epilogue detail without an explicit version. |
| `lotr_rk_18` | 2 | medium | stem-option-clue | OK: the stem and `Фродо Гэмджи` make the answer nearly self-identifying. |
| `lotr_rk_34` | 7 | low | overlapping-answer-options | OK: the necklace option can overlap the keyed jewel-on-chain description. |
| `lotr_rk_45` | 2 | high | stem-option-clue | OK: `Дом исцеления` and `Палаты исцеления` are an overt lexical cue. |
| `lotr_rk_47` | 2 | high | option-category-clue | OK: cinema wording is visible and only visual effects fits Weta Digital. |
| `lotr_rk_5` | 3 | high | book-vs-film-canon-boundary; stem-option-clue | OK: explicit film wording and literal title cue support both flags. |
| `lotr_rk_52` | 6 | medium | option-elimination | OK: option types identify the sea by elimination. |
| `lotr_rk_58` | 7 | medium | translation-boundary; version-unspecified | OK: the exact adjective is translation-sensitive and no version is named. |
| `lotr_rk_59` | 2 | high | option-grammar-clue | OK: plural `сыновья` leaves the only paired option. |
| `lotr_rk_62` | 8 | low | book-vs-film-canon-boundary | OK: this is an absence-of-name textual claim, not a film fact; private Gandalf entity tag is not in context. |
| `lotr_rk_64` | 2 | high | option-category-clue | OK: only the keyed option is an office. |
| `lotr_rk_74` | 6 | medium | book-film-episode-context-unspecified | OK: the episode/medium is absent from the stem. |
| `lotr_rk_84` | 2 | high | option-category-clue | OK: Bilbo is the only hobbit option. |
| `lotr_rk_85` | 7 | medium | medium-not-explicit | OK: no book or film claim is exposed through context tags. |
| `lotr_rk_95` | 6 | low | location-episode-unspecified | OK: White Ships lack epoch/episode qualification; alternate port is plausible. |
| `lotr_rk_96` | 2 | high | stem-option-clue | OK: `Корсаров Умбара` is repeated in the key; both book and film are visibly asserted. |
| `lotr_rk_99` | 6 | medium | option-category-clue; translation-boundary | OK: book/prologue is visible and hobbit-only alternatives reduce recall scope. |
| `lotr_tt_17` | 5 | high | name-resemblance-clue | OK: Теоден/Теодред cue is explicit in the names. |
| `lotr_tt_48` | 6 | medium | stem-option-clue | OK: only the key repeats Мелиан. |
| `lotr_tt_6` | 6 | medium | stem-option-clue | OK: `энт` directly cues `Энтмолт`. |
| `lotr_tt_62` | 8 | medium | book-episode-version-unspecified | OK: narrow scene detail without version in the stem. |
| `lotr_tt_65` | 6 | medium | translation-boundary; version-unspecified | OK: explanation identifies film but public context does not infer it. |
| `lotr_tt_66` | 7 | medium | book-episode-version-unspecified | OK: narrow dialogue/motive claim without stated version. |
| `lotr_tt_75` | 7 | low | book-film-canon-context-unspecified | OK: distinguishes book account from film-prologue association without forcing score 10. |
| `lotr_tt_84` | 2 | high | stem-option-clue | OK: `нуменорцы`/`люди Нуменора` makes the class answer direct. |
| `lotr_tt_87` | 2 | high | stem-option-clue | OK: Gandalf's initial and rune `Г` are a direct clue; entity remains editorial-only. |

The four low-confidence records are `lotr_rk_34`, `lotr_rk_62`,
`lotr_rk_95`, and `lotr_tt_75`; each is included in the flagged table above.

## Deterministic unflagged sample

Method: exclude all flagged and low-confidence records; calculate SHA-256 over
UTF-8 `lotr-rework-review-v1|<question_id>`; select the lowest rank for every
available score 2..9, then the lowest rank for every pack not already covered,
then lowest remaining ranks to 30. The listed IDs are source-specific and the
method is reproducible from the reviewed JSON.

| Pack | Source-specific sampled IDs (score) |
| --- | --- |
| `lotr` | `q_lotr_0_lotr-q1` (2) |
| `lotr_fellowship_100` | `lotr_f_15` (3), `lotr_f_2` (3), `lotr_f_25` (6), `lotr_f_39` (2), `lotr_f_41` (7), `lotr_f_50` (2), `lotr_f_8` (4) |
| `lotr_return_king_bts_100` | `lotr_rk_15` (4), `lotr_rk_19` (7), `lotr_rk_32` (7), `lotr_rk_39` (8), `lotr_rk_4` (4), `lotr_rk_43` (5), `lotr_rk_55` (4), `lotr_rk_67` (9), `lotr_rk_69` (5), `lotr_rk_80` (6), `lotr_rk_88` (6), `lotr_rk_91` (4) |
| `lotr_two_towers_lore_100` | `lotr_tt_10` (4), `lotr_tt_32` (7), `lotr_tt_41` (4), `lotr_tt_47` (7), `lotr_tt_56` (8), `lotr_tt_67` (3), `lotr_tt_68` (7), `lotr_tt_80` (6), `lotr_tt_81` (7), `lotr_tt_90` (5) |

All 30 samples passed the raw-field and semantic read. This includes the
specified boundary checks: `lotr_rk_100` is score 8 for obscure Paladin Took
recall and correctly has no unsupported film tag; `lotr_rk_18` is score 2 due
to its key clue; and reverse spouse facts `lotr_tt_54` and `lotr_rk_97` both
score 6 with matching association reasoning. The sample's medium tags appear
only where stem or announced pack context supports them; private person tags
remain out of public context.

## Recorded source ambiguities and limits

These are properties of the existing source questions/keys. They are recorded
as annotation flags and confidence, rather than resolved here:

| Record | Source ambiguity retained |
| --- | --- |
| `lotr_rk_34` | `Ожерелье с кулоном` may describe the same object as the keyed jewel on a chain. |
| `lotr_rk_62` | The answer depends on an absence-of-name claim in early *The Hobbit*. |
| `lotr_rk_95` | `Белые Корабли` has no epoch/episode qualifier and another Elven port is plausible. |
| `lotr_tt_75` | Book account and the film-prologue association produce different salient answers. |

No conclusion here resolves those factual/edition disputes. The existing
report's additional translation, book/film, and answer-hint flags are treated
as annotation semantics, not as independent factual validation of the 253
source records.
