# Russian cities (RU) for country_links.json: notes

57 items, 43 new sources (ids `ruc-*`), ~30 cities. Scripts: `build.py` → `delta.json`, `validate.py`
(schema, duplicates, lengths, `--links` for HTTP status), `merge.py` (append to the asset).

Kinds: landmark 21, fact 32, food 2 (chak-chak, Tula pryanik), bridge 1 (Neva drawbridges), sports_team 1 (Zenit).
Cities: Saint Petersburg 8, Moscow 6, Kazan 2, Nizhny Novgorod 3, Yekaterinburg 2, Novosibirsk 3, Volgograd 2,
Sochi 2, Vladivostok 1, Kaliningrad 4, Veliky Novgorod 2, Yaroslavl 1, Vladimir/Bogolyubovo/Suzdal 3, Sergiev Posad 1,
Pskov 1, Derbent 1, Murmansk 1, Arkhangelsk 1, Norilsk 1, Irkutsk 1, Yakutsk 1, Krasnoyarsk 1, Omsk 1, Tobolsk 1,
Chelyabinsk 1, Samara 1, Rostov-on-Don 1, Voronezh 1, Perm 1, Tula 2.

## Verification (2026-11-08)
Britannica, whc.unesco.org and several Russian sites return 403 / Cloudflare challenges to scripts and to WebFetch,
so every page was opened in a real browser by a verifier agent and each claim compared with the page text.
Only claims the page supports stayed in the text; the first draft was cut from 62 to 57 items accordingly.

Fixed after the check (first draft was wrong or unsupported):
- Novosibirsk renamed in 1925, not 1926; Novonikolayevsk from 1895.
- Murmansk founded 1915 (Britannica), not 1916.
- Chelyabinsk asteroid about 17 m (Britannica), not 20 m; date left as "2013" because the page gives no day.
- White Nights: Britannica gives ~19 h of daylight and "about 7° south of the Arctic Circle"; the "60° N" and
  "late May to mid-July" phrasing was dropped.
- Rostov-on-Don: about 50 km above the Don mouth (Britannica), not 46 km.
- Slugs changed or 404: St-Petersburg-Russia, Nizhny-Novgorod, Yekaterinburg, Novosibirsk-Russia, Volgograd-Russia,
  Kaliningrad, Murmansk-Russia, Arkhangelsk-Russia, Irkutsk-Russia, Krasnoyarsk-Russia, Omsk-Russia, Voronezh-Russia,
  Rostov-on-Don, topic/Chelyabinsk-meteorite-of-2013, event/Sochi-2014-Olympic-Winter-Games (olympics.com → 403).

Dropped (no support on an opened page): FC Spartak (spartak.com behind a CAPTCHA), Russky Bridge (structurae.net
Cloudflare), Kostroma / Ipatiev Monastery 1613 (not on Britannica's short Kostroma page), Church on Blood in
Yekaterinburg (replaced by the execution fact), Murmansk polar night, Kazan "millennium 2005", Kazan Kremlin
"leaning tower" / "Kul Sharif" name, Peterhof gravity-fed fountains, Nizhny Novgorod "closed city"/Sakharov and the
"pocket of Russia" saying, Motherland Calls height/1967/Vuchetich (only a caption on Britannica), Stolby, Dostoevsky
in Omsk, Decembrists in Irkutsk, Yakutsk permafrost/piles, Tula samovars and the samovar saying, Tobolsk "only stone
kremlin in Siberia" and Mendeleev (Mendeleev is already a separate RU scientist item).

Known limits: ambermuseum.ru/en/ serves Russian content (evidence on /about_museum/museum_buildings/ and
/about_amber/extraction/); tretyakovgallery.ru English "about" page is 404, the Russian history page is cited.
