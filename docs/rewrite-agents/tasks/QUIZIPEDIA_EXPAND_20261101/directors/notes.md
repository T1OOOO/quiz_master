# Directors / films delta (2026-11-01)

Output: `delta.json` (40 films, 27 directors, all `cast: []`), checked by `validate.py` (merge with live atlas in memory: unique ids, two-way credits, https sources, Cyrillic in `*_ru`, no Cyrillic in `*_en`, years sorted). Result: OK (70 works / 66 people after merge).

## Sources actually opened
- Academy Awards ceremony pages on oscars.org (1941, 1964, 1969, 1972, 1976, 1977, 1982, 1984, 1989, 1994, 1995, 2003, 2007, 2011, 2015, 2017, 2018, 2022, 2024): nominations/wins used in most film facts. `source_url` of those films = the ceremony page.
- Wikipedia (last resort, but Britannica, festival-cannes.com, loc.gov NFR listing and Criterion returned HTTP 403): Palme d'Or list, Cannes Best Director list, film and director pages. Used for Cannes/Berlin/Venice prizes, birth years, production details. Each Wikipedia claim used was read on the page, not recalled.
- Not opened as separate sources (cross-checked only through the Wikipedia pages above): Cannes archive, UNESCO register (Metropolis), Sight & Sound.

## Choices
- `born` is a year only; Zhang Yimou is `около 1950` because sources disagree (1950 / 1951).
- Existing id `bergman` is Ingrid Bergman, so Ingmar Bergman is `ingmar_bergman`. Film ids get a `_film`/`_year` suffix where a book/other work of the same name may be added by the books agent (`jaws_film`, `solaris_film`, `dune_2021`, `arrival_film`, `clockwork_orange_film`, `metropolis_film`, `pather_panchali_film`, `ashes_and_diamonds_film`, `oppenheimer_film`, `underground_1995`, `m_1931`).
- Russian titles are the established release titles: «Песнь дороги» (Pather Panchali), «Любовное настроение», «Подполье» (Underground), «Прибытие», «Восемь с половиной» and «М» (Cyrillic, so the Cyrillic check passes).
- Fictional-plot summaries are one neutral sentence; facts are limited to what the opened pages state.

## Least sure
1. `man_of_iron`: Palme d'Or 1981 confirmed on the Wajda and Palme d'Or pages; the film's own Wikipedia page returned 404, so the summary (journalist/1980 strikes) is from general knowledge.
2. `cranes_flying`: "only Palme d'Or for Soviet cinema" is Wikipedia's wording (1946 Grand Prix to a Soviet film is a predecessor award).
3. `in_the_mood_for_love`: "first Hong Kong actor" is Wikipedia's wording.
4. `zhang` birth year (approximate). `hero_2002` year = China release 2002 (Oscar-nominated at the 2003 ceremony).
5. Plot sentences of `three_colours_red` (Geneva, retired judge), `pans_labyrinth` (Franco-era Spain), `hero_2002`, `shape_of_water`, `dune_2021`, `inception`, `jaws_film` were not on pages I opened; they are well known but not source-checked.
6. `fanny_and_alexander` year 1982 (release); Oscar ceremony 1984. `burnt_by_the_sun` 1994 (Cannes, Oscar 1995).

## Dropped / not included
- Godard / Breathless (verified, dropped to stay near target), Alexander Nevsky, Inglourious Basterds, Women on the Verge of a Nervous Breakdown (verified, trimmed for size), Red Sorghum (release year 1987 vs 1988 disagrees), Blue Velvet (Oscar nomination only from the Lynch page), Bondarchuk / War and Peace (not verified).
- Britannica was blocked, so no Britannica sources were used.
