# Fact-check 2: items sourced to whc.unesco.org (never verified) + 4 west ids

Read-only. Nothing under next/ or the delta files was touched. Findings: `review.json` (15 entries, 11 items, 0 drops).

## Method
whc.unesco.org returned 403 to WebFetch but opens in the built-in browser. All 88 UNESCO pages (EN) were fetched and read: description, brief synthesis, inscription year, area; every number, date and superlative in each claim was checked against them. Russian names were compared with the UNESCO Russian pages (whc.unesco.org/ru/list/ID) and ru.wikipedia. West ids were checked on en.wikipedia (Harrison's Cave, Junkanoo, Imperial amazon, Faroe Islands) and ru.wikipedia.

## Counts (92 items checked; ids already in review-countries/review.json skipped)
- ok: 81
- fix: 11 (island-of-goree, east-rennell-lake-tegano, sulaiman-too-sacred-mountain, echmiatsin-mother-cathedral, mana-pools-national-park, tripitaka-koreana-haeinsa, chief-roi-mata-s-domain, qal-at-al-bahrain-dilmun-capital, gola-tiwai-complex-upper-guinean-forest, harrisons-cave, land-of-frankincense)
- drop: 0
- still-unverified: none for facts. Caveat, no change proposed: the RU names "Пещера Харрисона" and "Джункану" have no ru.wikipedia article, so only the transliteration is unconfirmed. "К'гари" (ru.wikipedia: Кгари), "Ахвар Южного Ирака" (ru.wikipedia: Эль-Ахвар) and "Гола-Тивай" (UNESCO ru: Гола-Тиваи) are acceptable variants.

## Notes on fixes
- Numbers: Gorée (28 ha / 3.5 km contradicts 18 ha / 2 km elsewhere), East Rennell (15,500 ha, not 15,000).
- Wording not supported by the source: Sulaiman-Too RU "в средние века"; Echmiatsin "name appeared" (source: used alongside Vagharshapat).
- Russian names: Мана-Пулс, Трипитака Кореана, Владения вождя Роя Маты, Калат-аль-Бахрейн, западная лысая ворона, трамвай.
- Confirmed correct, among others: Shibam "Chicago of the desert" (en.wikipedia), Bamiyan 55/38 m, Mogao 366 AD, Kunta Kinteh 1456, Fiji 1874, Barberton 3.5-3.2 Ga, Mana Pools 676,600 ha, Nyungwe 101,963 ha, Marquesas 1842, Gola 71,203 ha, Faroe "sheep islands" theory, Sisserou national bird and flag.
