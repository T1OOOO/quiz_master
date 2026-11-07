# Turkey (TR) culture and everyday life: notes

30 new `countries.TR` items, 29 new sources (all `https://`, ids prefixed `tr-cul-`). Validate: `python validate.py` (prints `OK`).
Kinds: fact 17, food 7, sports_team 4, filming_location 2. Nothing under `next/` was touched.

## How each source was checked
Every page below was opened (WebFetch or the built-in browser) on 2026-11-07 and the claims were read from the page text.
- UNESCO ICH element pages: Mevlevi Sema (2008), Karagöz (2009), Âşıklık (2009), Kırkpınar (2010), Mesir Macunu (2012), Ebru (2014), Çay (2022, joint with Azerbaijan), Nasreddin Hodja (2022, seven states). The inscription years come from the UNESCO Türkiye list page.
- Britannica (opened via the browser pane): Iznik ware, Kilim, Turkish delight, Baklava, Döner kebab, Nazım Hikmet, Yaşar Kemal, Naim Süleymanoğlu.
- NobelPrize.org (Pamuk), Festival de Cannes (Winter Sleep, 196 min, Palme d'Or 2014), UEFA.com (Galatasaray 2000), fenerbahce.org (history), FIFA.com (Şükür), turkishairlines.com (our story), GoTürkiye (hammam, simit, kahvaltı), KU CREES (nazar boncuğu).

## Least-sure items (check first)
1. `maidens-tower-world-is-not-enough`: the only page opened is a Bond fan site (James Bond Dossier). Fan sources disagree on the tower's role (M's prison vs. Renard's hideout), so the relation says only that it appears in the 1999 film and, in the background, in From Russia with Love.
2. `besiktas-jk`: the source is the Beşiktaş Municipality's English page, not the club's own site. It states March 1903 for Bereket Gymnastics Club and 13 Jan 1910 for the first registered Turkish sports club. Other sources give 1911 for registration.
3. `anadolu-efes-euroleague`: the source (Yeni Şafak) confirms the 2022 win over Real Madrid, 58-57 in Belgrade, as the second straight title. The 2021 title and "Istanbul" are not in that article; they were cross-checked on AA (beat Barcelona 86-81 in Cologne) and Eurohoops (Sinan Erdem Arena, Istanbul). Euroleague's own site was not reachable.
4. `hakan-sukur-fastest-world-cup-goal`: FIFA and Guinness say 11 seconds, but FIFA's own article says the exact time was 10.8 s. The text says "about 11 seconds".
5. `simit-sesame-bread-ring` and `turkish-breakfast-kahvalti`: from the official tourism portal (promotional). The simit "named after İzmit" and "16th century" claims were left out as unverifiable folk etymology.
6. Russian forms: «Назым Хикмет», «Яшар Кемаль», «Хакан Шукюр», «Наим Сулейманоглу», «Анадолу Эфес», «Фенербахче», «Бешикташ», «Галатасарай», «Девичья башня» follow common ru.wikipedia spellings but were not individually re-fetched. «Назар-бонджук» and «кахвальты» are transliterations without a settled ru.wikipedia form.

## Deliberately left out
- Turkish bath as a UNESCO element: the UNESCO Türkiye list (32 elements, last Antep İşi, Dec 2025) has no hammam. The `turkish-hammam-bath` item cites GoTürkiye only and makes no UNESCO claim.
- Disputed origins: baklava, döner, kebab, lokum; only attributed or neutral statements are used ("often credited", "name means").
- THY superlatives ("flies to the most countries"): that is the airline's own claim. Only 1933 / five aircraft / 1947 Istanbul-Athens are used.
- Tulip Era / Istanbul Tulip Festival (history lane; only travel blogs found), Troy (existing item), Turkish series exports (no source opened), Whistled language (UNESCO page does not name Kuşköy), carpets beyond kilim.
- Not used though verified: Meddah, Çini-making (ICH), Keşkek, Yufka flatbread, Hıdrellez, Dede Korkut, Hüsn-i Hat, Turkish archery, Semah, tulum. They are available as a second batch.

## Phrasing note
The app asks "Which culinary tradition is listed...", "Which sports club is based in...", "which distinctive fact...", so `name_en` is the answer option. Names are self-contained and tied to Türkiye; relations are single sentences of at most ~190 characters (validator warns on overflow).
