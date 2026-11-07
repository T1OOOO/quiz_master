# Turkey cities: Central Anatolia and Black Sea (delta notes)

90 new TR items, 67 new sources (all ids prefixed `trc-`). Counts by kind: landmark 49, food 20, fact 19, sports_team 2.
Run `python -I validate.py` in this folder (checks ids/names vs the whole country_links.json).

Source policy
- Food: TÜRKPATENT geographical-indication portal detail pages (opened) or registry PDFs (text extracted with pdftotext). Claims are phrased "registered geographical indication since YEAR" (tescil date); dish descriptions only where the registry text or a page said it.
- Landmarks: UNESCO WHC pages (list/1694 wooden mosques, tentative lists 5905 Kültepe, 5735 Hacı Bektaş), Ministry of Culture and Tourism (Atatürk Pavilion), Bolu provincial directorate (Mengen), TURKSOY (Kayseri 2027), GoTürkiye (Şeb-i Arus). English Wikipedia is the source of record for the rest (opened pages); Britannica/UNESCO list pages returned 403/404 for most targets.

Items per city
- Kayseri 14 (incl. Soğanlı, Mount Erciyes; Erciyes is NOT in country_links.json at the time of writing, so it was added here).
- Cappadocia (Nevşehir, Aksaray Ihlara, Avanos, Ürgüp, Hacıbektaş) 11.
- Trabzon 11.
- Ankara 6, Konya 6, Eskişehir 6, Amasya 4, Tokat 3, Sivas 3, Kastamonu 3, Sinop 3, Samsun 3, Bolu 3, Çorum 2, Giresun 2, Rize 2, Artvin 2, Niğde 2, Ordu 1, Zonguldak 1, Karabük 1, Yozgat 1.

Least sure
- Ahi Şerefettin mosque: UNESCO text spells it "Aslanhane", Wikipedia "Arslanhane"; name uses the latter in parentheses.
- Kaçkar Mountains tied to Rize only through Wikipedia category/caption; Çapanoğlu Mosque has no build date (not claimed).
- Hat Revolution: Wikipedia says started 23 Aug 1925 at Kastamonu; item says "August 1925" only.
- Sinop prison, Sivas Gök Medrese banknote, Boztepe lift, Yusufeli Dam height are single-source (Wikipedia).
- Konya etli ekmek and Sivas köfte, Nevşehir testi kebabı: description kept minimal (registry page gives only product group); "cooked in a clay jug" derives from the name "testi".
- Seb-i Arus dates 7-17 December are the 2021 programme from GoTürkiye; 17 Dec 1273 death date is from Wikipedia "Mevlana Museum".

Dropped (not verified or conflicting)
- Ankara tahin helvası (no GI record found), kuymak/muhlama for Trabzon/Rize (page does not link them), Trabzon hamsi GI (none), Safranbolu lokumu (single company registrant; Safranbolu already in file), Hacıbektaş festival dates 16-18 Aug (not on any opened page), Amasya Circular date (sources give 12 vs 22 June 1919), Atatürk Pavilion builder (sources conflict), Kültepe "UNESCO inscribed" (only tentative list page opened), Zil Castle, Yozgat dishes, Çorum İskilip dolması, Kangal dog/fish, Ordu hazelnut share (Giresun item covers hazelnut), Mount Bolu tunnel, Zonguldak Uzun Mehmet 1829 / Gökgöl cave, Karabük İncekaya aqueduct, Safranbolu items, Amasya Bimarhane 1309 (UNESCO page 403).
