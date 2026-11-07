# Independent fact-check: country_links delta (west 151 + east 157 = 308 items)

Read-only review. Nothing under `next/` or any delta file was touched. Machine-readable findings: `review.json` (48 entries, 33 distinct items, 0 drops; field `note` added for the reason).

## Counts
- Flagged **fix**: 33 items (west 25, east 8), **drop**: 0.
- **ok, actually looked up: about 163** (west about 122, east about 41). West: every Wikipedia-sourced item was machine-checked against the full text of the cited page (all numbers, dates and names in the claim), context read for about 110 of them, plus targeted lookups for Hauteville House (Wikipedia, since the Paris site returned 503), Grimaldi 1297, Saint Lucia laureates (Guinness page), Treaty of Concordia, customs treaty (Swiss customs museum), IANA .tv.
- East ok: duduk, Al Sadu, khachkars, royal drum, Pyongyang raengmyon, Manas, kok boru, ceebu jen, Arabic coffee, diwaniya, Karthala (OSU page), kakapo (DOC page), .tv (IANA), Tjibaou facts (NC tourism page), Hukuru Miskiy (Visit Maldives), HK geopark, Echmiatsin, Mogao, Island of Mozambique, Cidade Velha, Phoenix Islands, Dja, Marquesas, Sarazm, Ounianga facts, Chongoni, Twyfelfontein, Vallee de Mai, Robben Island, Shark Bay, Kunta Kinteh, Levuka, Bwindi, Virunga, Gobekli Tepe, Hatra, Crac des Chevaliers, Wadi Al-Hitan, K'gari, French Austral Lands, Gola-Tiwai (71,203 ha confirmed via IUCN table), Henderson/Asmara/Rock Islands only partly.
- **Not independently verified (about 108 east items, 4 west items)**: whc.unesco.org returns HTTP 403 to every tool here, so the remaining UNESCO World Heritage texts could not be opened (many ich.unesco.org pages did open and were used). West not looked up: harrisons-cave, junkanoo-festival, faroe-name-sheep-islands, sisserou-parrot-national-bird (plausible, unchecked).

## Author's doubtful items, verdicts
| item | verdict |
|---|---|
| Jersey Zoo 1959 | ok. Durrell article: "originally established by Gerald Durrell in 1959". |
| Mont Orgueil "begun after 1204" | ok in English (cited page: built after the 1204 conquest, first mentioned 1212, main fortress until Elizabeth Castle 1594). Russian name wrong, see json. |
| Mount Scenery 870 vs 887 m | 870 m is the 2024 re-measurement (NOS); Britannica and old sources say 887/877. Soft fix: "about 870 m". |
| Lake Enriquillo depth | -46 m is the Wikipedia/Guinness figure; recent levels -29 to -41 m. Soft fix. |
| Liechtenstein customs treaty | Facts ok (29 Mar 1923 / 1 Jan 1924); cited EDA URL does not contain them, repoint to the Swiss customs museum page. |
| Karthala source | ok: OSU page quotes 2,361 m, 3x4 km caldera, more than 20 eruptions since 19th century. Mirror of GVP text, acceptable. |
| Kakapo "about 325" | ok today (DOC page: "325 kakapo alive today", heaviest parrot, only lek-breeding parrot). Will date. |
| Church of the Nativity | Wording is neutral and the 2nd-century tradition is standard; UNESCO page unreadable (403), so not confirmed from the page. |
| Baa Atoll | fix: it was designated in June 2011; "nominated" is misleading. Areas 144,024 / 142,984 ha confirmed on the MAB page. |
| Russian transliterations | Крикова: ok (ru.wikipedia calls the winery «Крикова», the town Криково). Ааправаси-Гхат: ok (matches ru.wikipedia). Тамгалы: ok (UNESCO ru name; ru.wikipedia also has Танбалы). Калъат-аль-Бахрейн: left as is (ru.wikipedia writes Калат-аль-Бахрейн; UNESCO ru form not opened). Wrong or non-standard: Хинджар (Ханджар), Тжибау (Тьибау), Баджбим (Бадж-Бим, low confidence), Мон-Оргей (Монт-Оргёй), Тингганес (Тинганес), Мадриу-Перафита-Клор (Кларор), дельта Дикис (Диквис). Лахемаа ok. Хойя-де-Серен ok. |

## Most serious
1. castle-cornet (GG): claims "last Royalist stronghold to surrender"; the cited page says penultimate.
2. mount-flagstaff-sint-maarten (SX): "on the Dutch side"; cited page says directly on the border.
3. grand-etang-lake (GD): "one of two such lakes that helped form Grenada"; source lists three explosion craters.
4. martisor (MD): UNESCO element is Bulgaria + Moldova + North Macedonia + Romania; item says Moldova and Romania only and cites a page that never mentions UNESCO.
5. coffee landscape (CO): Valle del Cauca missing; court of justice (LU) 1952 vs source's 1951; Pelée 29,000 not in source (28,000); blue iguana 1,000th release was 23 July 2018, not August; Lake Turkana "249 km" unsupported.
6. Russian: Мичинес (not Мюкинес), Бонайре (not Бонэйра), Боботов-Кук, Лиамуига, Мескель, Банк-д’Арген, Унианга, Померания.

## Ok but cited page does not state it (claim is true, source weak; not in json)
Åland Convention of 20 Oct 1921 (cited Åland page only says League of Nations confirmed autonomy in 1921); Historic Centre of Riga 1997 and Colonia del Sacramento 1995 (cited pages say "UNESCO World Heritage Site" without year); Estonian song festival "UNESCO 2008" (page mentions only the 2003 Masterpiece proclamation). Mont Orgueil "first mentioned 1212" is on the page but not in the item (fine).
Also: TF "over 1,662,000 km2" matches the current UNESCO page (after the 2023 modification) but at the 2019 inscription it was about 672,000 km2; kind `fact` on many place items (Awash, Ahwar, W-Arly-Pendjari, Atsinanana, Barberton, TF) would fit `landmark` better.
