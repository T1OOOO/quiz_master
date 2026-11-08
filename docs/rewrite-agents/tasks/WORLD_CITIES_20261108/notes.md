# Well-known cities of 30 countries (ids `wc-*`) for country_links.json: notes

89 items (kind `fact`, one per city), 89 Britannica sources. Scripts: `build.py` → `delta.json`, `validate.py`
(schema, duplicates, lengths), `merge.py` (append to the asset), `fix.py` (one-off: applies the fact-check below).

Countries and cities: IT Rome, Milan, Venice, Florence, Naples · ES Madrid, Barcelona, Seville, Valencia ·
DE Berlin, Munich, Hamburg, Cologne, Frankfurt · GB London, Edinburgh, Manchester, Liverpool, Oxford ·
CN Beijing, Shanghai, Xi'an, Hong Kong, Guangzhou · JP Tokyo, Kyoto, Osaka, Hiroshima, Nara ·
IN Mumbai, Delhi, Kolkata, Jaipur, Varanasi · BR Rio, São Paulo, Brasília, Salvador · EG Cairo, Alexandria,
Luxor, Aswan · AU Sydney, Melbourne, Canberra, Perth · CA Toronto, Montreal, Vancouver, Quebec City ·
MX Mexico City, Guadalajara, Cancún, Oaxaca · NL Amsterdam, Rotterdam, The Hague · GR Athens, Thessaloniki ·
PT Lisbon, Porto · AR Buenos Aires · ZA Cape Town, Johannesburg · PE Lima, Cusco · MA Marrakech, Casablanca ·
KR Seoul, Busan · TH Bangkok, Chiang Mai · AE Dubai, Abu Dhabi · VN Hanoi, Ho Chi Minh City · IL Jerusalem,
Tel Aviv · CZ Prague · AT Vienna, Salzburg · PL Warsaw, Kraków · SE Stockholm · NO Oslo, Bergen ·
CH Zurich, Geneva, Bern.

## Verification (2026-11-08)
Every page was opened in the built-in browser pane by a verifier agent (full Britannica text via "Load Next Page",
main article only): 40 items confirmed as drafted, 43 partially supported and reworded to the page, 6 dates
contradicted and corrected:
- Guadalajara founded 1531 (not 1542); Thessaloniki founded 316 BCE (not 315); Vasco da Gama reached India in
  1498 (not 1497); Warsaw became the capital in 1611 (not 1596); Oslo got its name back in 1925 (not 1924);
  Munich's founding is the 1157 market right (not 1158).
- Dropped as unsupported: Vatican "enclosed" by Rome, Madrid at the geographic centre, Barcelona "second largest",
  Seville's trade "monopoly", Valencia as "home of paella", BMW in Munich, eau de cologne, Edinburgh "largest arts
  festival", Manchester "first industrial city", Oxford "oldest in the English-speaking world" (page: in England),
  Beijing 2022 Olympics, the Bund, Hong Kong's "densest skyline", Tokyo "most populous metro area", Kyoto spared
  from bombing, Nara's deer, Jaipur painted pink in 1876, Varanasi "holiest" (page: one of seven sacred cities),
  Rio "Marvellous City", Cairo founded 969 and "largest city of Africa", Luxor as New Kingdom capital, Lake Nasser
  and Philae, Canberra as a Sydney–Melbourne compromise, Perth's isolation, mariachi and tequila, Cancún "most
  visited", Amsterdam on piles, Rotterdam 1940, Athens "gave democracy", Douro naming Portugal, Buenos Aires "a
  third of the population", Johannesburg "largest city", Marrakech "Red City", Casablanca minaret, Seoul "a fifth",
  Dubai "largest city", Sheikh Zayed Mosque, Hanoi's 36 streets and mausoleum, Salzburg 1803/1756, Kraków square
  "one of the largest", Stockholm "fourteen islands" and Nobel ceremonies, Oslo's Peace Prize, Bergen "gateway".
- Slugs: Milan-Italy, Kyoto-Japan, Jaipur-India, Quebec, Rotterdam-Netherlands, Lima, Cuzco, Chiang-Mai, Zurich, Bern.

Study-fact total 18282 → 18460 (two facts per item).
