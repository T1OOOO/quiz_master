# countries-east: notes

Scope: Africa, Asia (incl. Middle East, Central Asia) and Oceania. Output: `delta.json` (157 items, 101 countries, 151 new sources), checked by `validate.py` (run `python validate.py`; last run: OK, 0 errors, 0 warnings).
Nothing under `next/` or any existing file was touched. Text data only, no media downloaded.

## Sources actually opened

- UNESCO World Heritage Centre pages `https://whc.unesco.org/en/list/<id>/` (read directly, "Brief synthesis" text): about 100 properties. Source ids `qe-unesco-whc-<id>`.
- UNESCO Intangible Cultural Heritage element pages `https://ich.unesco.org/en/RL/<slug>-<code>` (read with WebFetch; inscription year and description taken from the page, state listings from `ich.unesco.org/en/state/...`). Source ids `qe-unesco-ich-<code>`.
- NobelPrize.org "Facts" pages (Soyinka 1986, Maathai 2004, Tu Youyou 2015, Salam 1979, Malala 2014).
- U.S. Department of State, Office of the Historian: South Sudan, Liberia.
- IANA root zone database entry for `.tv`.
- Oregon State University Volcano World page for Karthala (reproduces the Smithsonian/USGS GVP description; the GVP page itself returned 403).
- Hong Kong Tourism Board (geopark), UNESCO MAB page (Baa Atoll), Visit Maldives (Hukuru Miskiy), Brunei Tourism (Kampong Ayer), New Caledonia Tourism (Tjibaou), Library of Congress Maps blog (stick charts), New Zealand DOC (kakapo), DarkSky International (Niue).
- Wikipedia was not used as a source for any item.

## Found but rejected / dropped

- Dropped for lack of an openable primary source: Samoa skipping 30 Dec 2011 (BBC blocked), Yap rai stones (Smithsonian pages 403), Ha'amonga 'a Maui (only secondary pages), Nauru phosphate (Britannica 403, rest secondary), Peak Tram / Tian Tan Buddha (HK), Bhutan GNH (official page had no checkable facts), Maldives tentative-list status of the Friday Mosque, Brunei population figures, Palau National Marine Sanctuary (site parked), Hunga Tonga eruption (NASA page moved).
- Dropped to stay near the 150 target, all verified but from countries already well covered: Gebel Barkal (SD), Matobo Hills (ZW), Tomb of Askia (ML), Saint Catherine's Monastery (EG), Kasbah of Algiers (DZ), Volubilis and Gnawa (MA), Kairouan (TN), Fossil Hominid Sites (ZA), Orkhon Valley (MN), Ayutthaya (TH), Sangiran (ID), Fort Jesus (KE), Salonga (CD), Kasubi Tombs (UG), Simien (ET), Gunung Mulu (MY), Geet-Gawai (MU). Their facts were read from the same UNESCO pages and can be added back on request.
- Not attempted (no usable source found in time): DJ, GQ, ST, GW, SZ, TG, SO, LS, BT, TL, TW, WS, FM, NR, EH.

## Items I am least sure about

1. `mount-karthala-grande-comore`: source is the Oregon State mirror of the GVP text, not smithsonian volcano.si.edu itself.
2. `kakapo-flightless-nocturnal-parrot`: "about 325 birds" is a current DOC figure and will date.
3. `church-of-the-nativity-bethlehem` (PS): UNESCO lists it under "State of Palestine". Wording is neutral (no sovereignty claim); Hebron and Battir deliberately not used.
4. `baa-atoll-biosphere-reserve`: the UNESCO MAB page gives "year of nomination 2011", so the text says "nominated", not "designated".
5. `hong-kong-geopark-hexagonal-volcanic-columns`: the HKTB page says the Ung Kong and Ninepin groups have hexagonal volcanic columns and that the park joined the network in 2011; no rock type is claimed.
6. `tv-country-code-top-level-domain`: IANA lists a Tuvalu ministry as manager; the text says exactly that and nothing about commercial operation.
7. Russian transliterations worth a native glance: Ааправаси-Гхат, Калъат-аль-Бахрейн, Хинджар, Тамгалы (Tanbaly), Баджбим (Budj Bim), Тжибау, Кусейр-Амра, Чебу жен (тьебудьен), Мргвловани/нусхури/мхедрули.
8. Superlatives are used only where the cited page states them and the text says so ("UNESCO calls it ..."): Lake Turkana, Lamu, Salonga, Saint Catherine (dropped), Kairouan, Merv, Phoenix Islands (stated "at inscription").
9. Kind balance: 92 landmark, 57 fact, 6 food, 2 scientist. Many World Heritage places are `landmark` because they are locatable points; ICH elements are `fact`/`food`.
10. About half of the touched countries get only 1 new item (the ones with a single verifiable source in hand), so the "at least 2 per country" aim is met for 42 of 101 countries.
