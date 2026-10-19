# Independent Russian naming review — RU_A15C

**Packet label:** `ru-naming-a15c`
**Reviewed hashes:**

- `country_labels_ru.dart` — `9D3F13D69821FD9F6883DC9C92B0A33C6E088B6180524D71B13C64A693C27D54`
- `russian_learning_text.dart` — `24882DAF9971B3D75F1F521ACD087A67601BE06BDD6C40397CBC71CB2F59EF68`
- `country_facts.json` — `38283995143F52F4A82E947FC35CC5EB4B7419F92DEBD3697CD71D2728821063`

**Verdict:** **REVISE — small, concrete Russian source-caption and terminology
repairs are required.** The 560 country labels themselves are ready; no
capital, language, or currency-label repair is required by this review.

## Method and coverage

I independently compared every nonempty capital, language, and currency value
from the shipped country facts with the static Russian map, then reviewed the
display dictionary's source-title map and replacement order. The country data
has 244 distinct capitals, 155 languages, and 161 currencies. All 560 values
are direct map keys; no resulting mapped value contains Latin letters.

The eight currency values that differ from the current Node ICU/CLDR Russian
display names are precisely the documented unavailable-code fallbacks (CKD,
FOK, GGP, IMP, JEP, KID, TVD) and the intentional Russian expansion of XAF's
BEAC acronym. They retain the unchanged ISO codes as lookup keys and are clear
Russian currency names, so they do not change the underlying currency entity.

I checked potentially uncertain names rather than inferring them from English:

- The current `Cockburn Town` label, `Кокбёрн-Таун`, matches a Russian UN
  territorial report. The alternative `Коберн-Таун` seen in secondary Russian
  references does not establish an error in the current conventional form.
- The Great Russian Encyclopedia uses `кхое` for the relevant Khoekhoe family
  label and `койсанские` for Khoisan. The current `кхое` and `койсанский`
  preserve the two distinct source entities. The cautious forms for Chibarwe,
  Kwangali, Norfuk, Upper Guinea Creole, and the Zimbabwean `Tonga` likewise do
  not introduce a different language or country entity.
- Composite capitals retain their factual qualifiers: Amsterdam/government in
  The Hague; Sucre/constitutional capital; and the three South African capital
  roles. Common Russian exonyms such as `Пекин`, `Кишинёв`, `Киев`, and
  `Эль-Аюн` are presentation-language choices, not edits to the English data.

For source titles actually rendered through `learningSourceTitle`, all titles
from the belief (13), brand (47), food (12), music (33), and anatomy (21)
catalogues have a dictionary entry. Country Learning intentionally displays a
generic Russian `Источник` link label rather than calling
`learningSourceTitle`; its raw country-source registry is therefore not an
untranslated runtime caption in this implementation.

## Required repairs

All repairs below are in `russianSourceTitles`; they must preserve the same map
keys. They change only Russian display text.

| Current source-title key | Current Russian caption | Required Russian caption / reason |
|---|---|---|
| `Bath Spa University · Mbira Hut` | `Батский университет искусств: традиция мбира` | Use `Университет Бат-Спа: «Мбира-хат»` (or an equally faithful Russian rendering of *Mbira Hut*). Bath Spa University is its proper institutional name; the current caption changes it into an invented “Bath university of arts” and drops the project name. |
| `NCI SEER Training, Ovaries` | `Национальный институт рака США: яичники` | Use `Учебный курс SEER Национального института рака США: яичники`. The source is the NCI's SEER Training programme, not the Institute in general. `SEER` may remain as its identifying programme acronym. |
| `NCI SEER Training, Testes` | `Национальный институт рака США: яички` | Use `Учебный курс SEER Национального института рака США: семенники`. This both preserves the source programme and uses the conventional anatomical term. Russian MSD and the Great Russian Encyclopedia use `семенники` in anatomy/endocrine context. |
| `Hyosun Ro, Korean Bapsang: Bibimbap` | `Хёсун Ро: пибимпап` | Use `Хёсун Ро, «Корейский стол»: пибимпап`. The current caption drops *Korean Bapsang*, the named source publication. |
| `Apple — 50 years of thinking different` | `Эппл: пятьдесят лет компании` | Use `Эппл: 50 лет «думать иначе»` (or equivalent Russian wording retaining *thinking different*). The present wording changes the named article into a generic company-history caption. |
| `UNESCO · Aitysh/Aitys` | `ЮНЕСКО: айтыс` | Use `ЮНЕСКО: Айтыш/Айтыс, искусство импровизации`. The direct UNESCO record identifies both forms; reducing it to one spelling loses the shared Kazakhstan/Kyrgyzstan source identity. |
| `Qur'an 2:177, Quran.com` | `Коран, сура 2, аят 177` | Use `Коран, сура 2, аят 177 — Quran.com`. `Quran.com` is the identifying source site, not prose that can be silently dropped. Its official site name may remain as a source identifier under the packet exception. |
| `Skydance / SEC acquisition closing, 6 October 2026` | `Скайдэнс: завершение приобретения, 6 октября 2026 года` | Use `Скайдэнс / Комиссия по ценным бумагам и биржам США: завершение сделки, 6 октября 2026 года` (or retain `SEC` as its identifying agency acronym). The current caption removes the SEC entity. |
| Every `OpenStax Anatomy and Physiology...` source-title key (15 entries) | `Открытый учебник анатомии и физиологии: ...` | Prefix the publisher identity, for example `OpenStax: анатомия и физиология: ...`, retaining `OpenStax` as the official identifying source mark. The current captions turn a named publisher/source into a generic textbook. |

## Accepted naming and translation checks

- Capitals, language labels, and currency labels preserve their input entity;
  no map key was altered, conflated, or silently left in English.
- Country, city, language, currency, scientific-symbol, and musical-notation
  labels are Russian. The retained scientific `T` in `T-лимфоцитов` is a
  conventional scientific symbol, as allowed by the packet.
- `russianLearningTerms` has no Latin-script values, and longer overlapping
  source/brand names occur before their shorter substrings. I found no
  replacement cascade that changes a reviewed Russian entity after translation.
- Brand, former-name, and food/music term mappings were reviewed for entity
  continuity. Transliterated proper names such as `Индитекс`, `Юбисофт`,
  `Луи Виттон`, `Нинтендо`, and `Филармония` remain identifiable Russian
  renderings rather than new entities.

## Recheck condition

Provide a new hash of `russian_learning_text.dart` after the listed captions
are corrected. I will recheck only those keys, ensure all source-title map
values remain Russian display text while retaining source identity, and append
the verdict. This naming review does not approve UI behavior, builds, data
facts, release, or publication.

---

## Final changed-scope recheck — 2026-10-19

**Reviewed hash:** `russian_learning_text.dart` —
`3F141CAE9A5EF4363DF0F5282A2B8C02DED9132029B77216E58505FEB1D57836`

**Verdict:** **ACCEPT for the Russian naming and source-caption scope.**

I re-read every repaired caption named in the required-repairs table. Bath Spa
University is now `Университет Бат-Спа: «Мбира-хат»`; both NCI captions retain
the SEER programme and the testes caption uses `семенники`; the Korean Bapsang,
Apple *thinking different*, and UNESCO `Айтыш/Айтыс` source identities are
present. The Quran citation retains the named site as Russian `сайт
«Коран.ком»`, and the Skydance caption retains the SEC in its Russian agency
name.

All 17 current OpenStax anatomy source captions now identify the publisher as
`Издатель «ОпенСтакс»` and retain the source topic. This is a faithful
Russian-script rendering of the source identity; canonical title keys and
linked URLs remain outside this display dictionary. `SEER`, `HYG 4.1`,
`J2000`, and `CC BY-SA 4.0` are the only remaining Latin-script display
fragments in the changed captions/credits. They are programme, catalogue,
epoch, and licence identifiers permitted by the packet, rather than
untranslated prose.

I also reviewed the added Russian term and credit mappings. They translate
source/brand prose and the music-notation words without changing the entity or
claim: examples include `Whole tone` → `Целый тон`, `Semitone` → `Полутон`,
`Arpeggio` → `Арпеджио`, and `Stellarium` → `Стеллариум`. The credits preserve
the named catalogue, attribution, fixed-coordinate epoch, licence, and the
statement that modern constellation lines are not IAU boundaries. `git diff
--check` reported no whitespace errors for the reviewed Dart file.

This acceptance covers only the reviewed display terminology and captions. It
does not assert an application build, UI test, canonical-data import, release,
or publication outcome.
---

## Independent sky-label review — 2026-10-19

**Reviewed assets:**

- `assets/quizipedia/catalog.json` — SHA-256
  `F1EE7292603F09630A01BA8D4F017FB1C994FFA1331983F7DBD19CFCF1546FEE`
- `docs/rewrite-agents/tasks/RU_A15C/apply_sky_ru.ps1`

**Verdict:** **REVISE — the generated coverage is complete, but a short
Russian-name override list and the Bayer/Flamsteed parser repair are needed.**

The catalog has 88 constellations and 685 stars; every star has a nonempty
`name_ru`. The only remaining Latin output is the standard `HIP` catalogue
identifier on 31 stars, which the packet permits. I sampled every one of the
208 names that reached `Convert-Name`'s last transliteration fallback, rather
than treating the generated text as a conventional Russian-name list.

### Blocker: seven broken designation labels

These entries are ordinary Bayer/Flamsteed designations, not rare proper names.
The fallback failed because the source strings omit spaces around the Greek
letter/index. It currently produces unreadable lower-case run-ons. Extend the
Bayer parser to permit those spaces and run the script again; do not maintain
these as one-off transliterations.

| Source `name` | Current `name_ru` | Required display form |
|---|---|---|
| `65Xi 1Cet` | `65кси 1кет` | `65 Кси 1 Кита` |
| `73Xi 2Cet` | `73кси 2кет` | `73 Кси 2 Кита` |
| `5Xi 2CMa` | `5кси 2кма` | `5 Кси 2 Большого Пса` |
| `7Nu 2CMa` | `7ну 2кма` | `7 Ню 2 Большого Пса` |
| `25Nu 2Dra` | `25ну 2дра` | `25 Ню 2 Дракона` |
| `27Pi 1Peg` | `27пи 1пег` | `27 Пи 1 Пегаса` |
| `37Xi 2Sgr` | `37кси 2сгр` | `37 Кси 2 Стрельца` |

### Verified conventional-name overrides

The following are visibly wrong mechanical results for common named stars or
have a well-established Russian form. Add these exact cases to `$proper`
before the generic fallback. The Russian educational constellation table in
[*Небосвод*](https://images.astronet.ru/pubd/2014/11/22/0001326232/neb_0909pp.pdf),
the [Nizhny Novgorod State University astronomical calendar](https://www.unn.ru/site/images/docs/science/astrocalendar_2018.pdf),
and the Russian Astronet discussion of
[Тянь-Гуань](https://www.astronet.ru/db/varstars/msg/1201870/09.html) support
the conventional forms and their star identities.

| `name` | Current `name_ru` | Required `name_ru` |
|---|---|---|
| `Schedar` | `Счедар` | `Шедар` |
| `Rigil Kentaurus` | `Ригил кентаурус` | `Ригиль Кентаврус` |
| `Elnath` (both rows) | `Елнат` | `Эль-Нат` |
| `Adhara` | `Адхара` | `Адара` |
| `Kaffaljidhma` | `Каффалджидхма` | `Каффалидма` |
| `Gienah` | `Гиенах` | `Гиена` |
| `Cor Caroli` | `Кор кароли` | `Кор Кароли` |
| `Alhena` | `Алхена` | `Альхена` |
| `Hamal` | `Хамал` | `Хамаль` |
| `Gomeisa` | `Гомеиса` | `Гомейза` |
| `Rasalhague` | `Расальхаге` | `Рас Альхаге` |
| `Cebalrai` | `Кебалраи` | `Цельбальрай` |
| `Alrescha` | `Алресча` | `Альреша` |
| `Dschubba` | `Дсчубба` | `Джубба` |
| `Peacock` | `Пеакокк` | `Пеакок` |
| `Prima Hyadum` | `Прима хйадум` | `Прима Гиадум` |
| `Secunda Hyadum` | `Секунда хйадум` | `Секунда Гиадум` |
| `Tianguan` | `Тиангуан` | `Тянь-Гуань` |
| `Alya` | `Алйа` | `Алия` |
| `Megrez` | `Мегрез` | `Мегрец` |

The remaining fallback names can remain explicitly documented transliteration
labels: this review found no evidence that a generic Latin-to-Cyrillic routine
could establish an IAU-endorsed Russian proper name for them. The generic
routine does, however, explain why unfamiliar `y`, `zh`, `dsch`, and Arabic or
Chinese-derived spellings should receive individually researched overrides
when they become prominent in the UI.

### Related literal-label check

The current `russian_learning_text.dart` does contain `Chocolate Crisp` →
`Чоколейт Крисп` and renders `Daimler-Benz AG`, `Porsche AG`, and `BMW AG` with
Cyrillic `АГ`. It still drops the legal form from `Mercedes-Benz Group AG`,
`Volkswagen AG`, and `adidas AG`; if the integration policy is to retain that
source identity, change their display values to `Мерседес-Бенц Груп АГ`,
`Фольксваген АГ`, and `Адидас АГ`.

This is a display-name review only. It does not change star positions,
magnitudes, source URLs, catalog IDs, or physical claims, and it does not
assert an integrated build, UI test, release, or publication outcome.
---

## Final sky changed-scope recheck — 2026-10-19

**Reviewed catalog hash:**
`10D96509266C7E174620A251387D8A239CDFCFA7C9FCF33F100A946B32CF05E5`

**Verdict:** **ACCEPT for the reviewed sky-label scope.**

I read the regenerated `apply_sky_ru.ps1` and independently checked the
catalog values. Its widened Bayer parser now accepts unspaced Greek letter and
numeric-index source notation, and all seven formerly broken entries exactly
match the required Russian display labels. Each of the 20 reviewed
proper-name overrides is present, including both Elnath rows. The remaining
fallback names remain labelled as transliterations, which is the documented
policy reviewed above; this acceptance does not convert those labels into
assertions of a single conventional Russian or IAU name.

A field-level comparison with `HEAD:next/apps/quiz_app/assets/quizipedia/catalog.json`,
excluding only `name_ru` and `explanation_ru`, returned `canonical_equal=True`
with the same 88-constellation structure. This verifies that the changed
script/catalog scope leaves identifiers, source data, positions, magnitudes,
and other canonical facts intact. I also confirmed the literal helpers:
`Chocolate Crisp` maps to `Чоколейт Крисп`, `Daimler-Benz AG` to
`Даймлер-Бенц АГ`, and `Porsche AG` to `Порше АГ`.

`git diff --check` passed for this review report. This is a content/naming
acceptance only; I did not rerun the worker's focused test or validate an
integrated UI, build, release, or publication.
