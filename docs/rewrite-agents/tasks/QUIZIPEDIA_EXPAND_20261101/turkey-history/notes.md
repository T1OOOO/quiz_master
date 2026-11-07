# Turkey history/people delta (QUIZIPEDIA_EXPAND_20261101)

30 new TR items (26 `fact`, 4 `scientist`), 29 new sources. `python validate.py` passes (ids/names unique vs country_links.json, sources resolve, https, Cyrillic, length).

All facts were checked on pages opened on 2026-11-07: Britannica (via built-in browser), Turkish Ministry of Culture and Tourism chronology pages (ktb.gov.tr, 1923/1928/1934, Ali Kuscu, Map of Piri Reis), nobelprize.org facts pages, MacTutor (Arf).

Design choices
- `scientist` kind is used only for people born in modern Turkey (the app asks "Which scientist was born in the territory of modern Turkey?"): Sancar (Savur), Hipparchus (Nicaea), Galen (Pergamum), Thales (Miletus). Ali Kuscu (born Samarkand), Arf (born Salonika), Pamuk, Herodotus use `fact`.
- Dropped for lack of a verified/uncontested source: Sabiha Gokcen "first female combat pilot" (contested), Piri Reis "oldest map with America" (not supported), al-Jazari birthplace, Taqi al-Din, Antioch "first Christians".
- Left to other authors: World Heritage sites, nature, food, sport, film, crafts (Hattusa/Troy/Gordion appear only as history facts, not as site entries).

Least sure
- thales-of-miletus: birthplace taken from the epithet plus Britannica's Miletus article (Thales listed among Miletus's figures); Thales page text was paywall-truncated.
- strong wording "first recorded peace treaty" (Kadesh) follows Britannica verbatim in meaning.
- Russian forms checked from memory of ru.wikipedia, not re-opened: Азиз Санджар, Джахит Арф / инвариант Арфа, Али Кушчи, Пири-реис, Сеяхатнаме, Гордион, Богазкале, Гиссарлык.
- ali-kuscu-astronomer: Hagia Sophia madrasa teaching post is from the ktb page only.
