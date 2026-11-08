# US states and cities (US, `usa-*`) and French regions (FR, `frr-*`) for country_links.json: notes

67 items, 66 new sources. Scripts: `build.py` → `delta.json`, `validate.py` (schema, duplicates, lengths; `--links`
only for non-Britannica hosts), `merge.py` (append to the asset), `shorten.py` (one-off length pass, kept for the record).

US 47: 20 states (fact), 17 city facts, 10 landmarks (Central Park, Capitol/Mall, Willis Tower, Alcatraz, Hoover Dam,
Independence Hall, Pearl Harbor, the Alamo, Gateway Arch, Mount Rushmore), gumbo, Yankees, Packers.
FR 20: the 13 metropolitan regions (Île-de-France, PACA, Occitanie, Nouvelle-Aquitaine, Auvergne-Rhône-Alpes, Grand Est,
Hauts-de-France, Normandy, Brittany, Pays de la Loire, Centre-Val de Loire via the Loire Valley, Bourgogne-Franche-Comté,
Corsica) plus Marseille, Mont Blanc, Provence, Côte d'Azur, Chaîne des Puys, champagne and crêpes.

## Verification (2026-11-08)
Every page was opened in the built-in browser pane by a verifier agent (Britannica full text via "Load Next Page",
claims matched against the main article only). Only supported wording stayed; the draft was cut from 69 to 67 items.

Fixed after the check:
- Willis Tower was the world's tallest until 1996 (Petronas), not 1998.
- Côte d'Azur: Britannica defines it as the Riviera between Menton and Cannes extending into southern Var; the
  "Toulon to the Italian border" phrasing, Saint-Tropez and the Cannes festival were dropped.
- Alamo defenders: "some 180–190", not "about 200"; Georgia founded 1732 (settlement at Savannah 1733); Wyoming's
  "first constitution to grant women full voting rights" replaces the 1869 territory claim; Hawaii, Alaska, Texas
  superlatives and the Colorado "highest mean elevation" claim reworded to the page.
- Slugs: topic/gumbo, topic/Pearl-Harbor, place/Alamo, topic/Mount-Rushmore-National-Memorial,
  topic/champagne-alcoholic-beverage, place/Normandy, topic/crepe-pancake, place/Provence-region-France.

Dropped (no support on the opened page): Chicago deep-dish pizza (Britannica's pizza article only names it),
Camembert/cider of Normandy, "only state owned by fans" for the Packers, Home Insurance Building 1885, Santa Fe as
"oldest capital" (page: oldest continuously used seat of government in North America), Atlanta's airport, Motown 1959,
Mont Blanc Tunnel, Strasbourg's European Parliament, Toulouse aerospace, Bordeaux wine, Dijon mustard, Lyon gastronomy,
Brittany origin of crêpes and galettes, Roman remains of Nîmes and Orange.

Thin sources: the 2016 French region pages on Britannica are stubs (creation, components, capital), so those items
carry only that.
