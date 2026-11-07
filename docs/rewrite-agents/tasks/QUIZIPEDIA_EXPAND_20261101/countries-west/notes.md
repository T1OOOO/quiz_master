# countries-west notes (Quizipedia expansion 20261101)

Output: delta.json (151 items, 60 countries, 136 new sources, ids prefixed `qzw-`). Rebuild with `python -I build.py`, check with `python -I validate.py`.
Kinds used: landmark 79, fact 68, food 4 (all within the kinds already in the asset; no `culture` kind used on purpose).

## Verification method
- unesco.org (whc and ich) and britannica.com return HTTP 403 to every fetch tool here, so they could not be opened directly.
- Almost every item was checked by fetching the matching English Wikipedia article and reading the quoted sentence/infobox that supports the exact claim (dates, heights, years).
- Sources surfaced only through WebSearch result summaries, not opened as pages: whc.unesco.org/en/list/1245 (San Marino), eda.admin.ch (Liechtenstein customs treaty 1923/1924), Wikipedia 1984 Liechtenstein suffrage referendum, maisonsvictorhugo.paris.fr (Hauteville House), en.wikipedia Mont_Orgueil, Castle_Cornet, Durrell_Wildlife_Conservation_Trust, Museum_of_Nevis_History, guinnessworldrecords.com (Saint Lucia Nobel laureates), visitcaymanislands.com (blue iguana), en.gouv.mc (Grimaldi 1297).
- Wording was kept to what the source states; contested superlatives are attributed ("described as", "thought to be") or dropped.

## Rejected / dropped (could not verify or sources conflicted)
- Exuma Cays Land and Sea Park ("first land and sea park"; Wikipedia says 1958 and 1959, claim absent).
- Gibraltar St Michael's Cave, Europa Point lighthouse (not found in the fetched text).
- Isle of Man Manx cat (source says "short or no tails"), Manx Gaelic Ned Maddrell.
- Mărțișor UNESCO year and the four-country joint inscription (2017) — not stated on the fetched page, so only "Moldova and Romania" and "UNESCO list" are claimed.
- Saint Lucia "most Nobel laureates per capita" (sources disagree: first vs second behind Faroe Islands), so only the two laureates and prizes are stated.
- Nobelprize.org pages (403), Harrison's/Jesuit Missions of Paraguay/Oxherding in Costa Rica/Casco Viejo/Bermuda UNESCO year (404 or year not on page), Barbuda frigate-bird sanctuary, Antigua Betty's Hope, St Vincent, Vatican Museums.
- Anything political about Gibraltar's status, Transnistria, Falklands war.

## Items I am least sure about
1. Durrell Jersey Zoo "1959": sources vary between 1958 and 1959 for the start; the trust year (1963/1964) is deliberately omitted.
2. Mont Orgueil "begun after 1204": Wikipedia gives a 1204-1450 build span; the earliest parts are dated roughly 1200-1230 by other sources.
3. Liechtenstein customs treaty: Liechtenstein government says franc since 1921, EDA says 1924; the item states only the treaty (29 March 1923) and the 1 January 1924 start.
4. Mount Scenery 870 m (Wikipedia) vs the 887 m figure seen elsewhere; Wikipedia value used.
5. Lake Enriquillo "46 m below sea level" and "largest lake in the Caribbean" come from the Wikipedia text (older sources give about -40 m).
6. Nelson's Dockyard "only continuously working Georgian-era dockyard": Wikipedia citing the park; attributed with "described as".
7. Russian transliterations (Крикова, Мон-Оргей, Тингганес, Хойя-де-Серен, Лахемаа, Мадриу-Перафита-Клор, дельта Дикис) follow common usage but were not cross-checked against ru.wikipedia.
8. Duplicate-looking names across countries: none inside the delta; checked against all existing (kind, name_en) pairs.
