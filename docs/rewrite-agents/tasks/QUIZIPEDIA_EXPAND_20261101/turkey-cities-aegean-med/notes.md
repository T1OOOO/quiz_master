# Turkey cities: Aegean and Mediterranean coast (TR delta)

61 items (35 landmark, 15 food, 11 fact), 59 new sources, all ids/source ids prefixed `trae-`.
Check with `python validate.py`. Nothing under next/ was touched.

## Coverage
- Antalya 14: Aspendos theatre, Aspendos festival, Perge, Termessos, Side (Apollo), Hadrian's Gate, Kaleici, Yivli Minaret, Lower Duden, Phaselis (Kemer), Kekova (Demre), St Nicholas (Demre), Golden Orange, piyaz.
- Adana 9: Stone Bridge, Sabanci mosque, Great Mosque, Yilankale, kebab, salgam, Golden Boll festival, Orange Blossom Carnival, Seyhan Dam.
- Mersin 10: Kizkalesi, Cennet/Cehennem, Uzuncaburc, Mamure (Anamur), Cleopatra's Gate and St Paul's Well (Tarsus), tantuni, cezerye, Tarsus hummus, 2013 Mediterranean Games.
- Izmir 4, Manisa 1, Aydin 2, Mugla 6, Denizli 2, Isparta 2, Burdur 2, Hatay 5, Osmaniye 1, Kahramanmaras 3.

## How claims were verified (pages actually opened)
- Food: TURKPATENT geographical-indication PDFs downloaded and text-extracted (nos. 211, 226, 268, 315, 330, 344, 347, 355, 361, 379; cezerye via its register PDF; Isparta rose oil via the TURKPATENT success-story PDF no. 421). Kunefe and Aydin figs: TURKPATENT English news page (EU registration, 13 March 2023). Hatay: UNESCO Creative Cities page.
- Landmarks/facts: en.wikipedia article text read through the MediaWiki API; Britannica (Tarsus, Adana) opened as second source for the cities. Russian names taken from ru.wikipedia interlanguage links where an article exists (Perge=Перге, Phaselis=Фаселис, Sagalassos=Сагалассос, Kekova, Kaleici=Калеичи, Mamure=Мамуре, etc.); where ru.wikipedia has no article the name is a standard transliteration (Taskopru, Yilankale, Cennet/Cehennem, Uzuncaburc, Karatepe-Aslantas...).
- Dish claims are phrased "registered as geographical indication X" (year = TURKPATENT registration date), not "origin/invented".

## Least-sure items
- trae-adana-kebab: Wikipedia only; Adana kebab GI status is reported inconsistently (2004/2005 vs no TURKPATENT entry found), so the item makes no GI claim.
- trae-adana-salgam: "festival since 2010" is from Wikipedia only.
- trae-saint-pauls-well-tarsus, trae-st-nicholas-church-demre: UNESCO Tentative List status is from Wikipedia, not from whc.unesco.org.
- trae-termessos-antalya: Alexander's 333 BC siege is Wikipedia's summary of Arrian.
- trae-hatay-unesco-creative-city-gastronomy: "13 civilizations" is UNESCO's "it is said" wording.
- trae-mersin-cezerye: the register PDF gives two dates (2002 notice, 2003 registration), so no year is stated.
- trae-aydin-fig: relation rests on the TURKPATENT news list of EU registrations; the sarilop definition was checked in the EU product specification (assets.publishing.service.gov.uk Aydin_Inciri.pdf) but that URL is not used as a source.
- Many Wikipedia-sourced items have a single source; a second source was not opened for each.

## Dropped
- Aphrodisias, Pamukkale, Ephesus, Xanthos, Mesir macunu (existing ids); Hatay "second-largest mosaic collection" (unsupported superlative); Priene, Datca almond, Marmaris, Kas/Kemer-specific food, Osmaniye peanut, Isparta rose water, Burdur food (no verified page); Tarsus Waterfall (flows only after heavy rain); Hierapolis (overlaps pamukkale-wonder).
- Several Hatay/Kahramanmaras sites (Habib-i Neccar, Maras Ulu Cami, Antakya museum) were not added: damaged in the February 2023 earthquakes and not needed. The Church of St Peter and Titus Tunnel items state only historical facts.

## Merge note
Source ids such as `trae-unesco-hatay` or `trae-wp-adana` could collide with sibling authors; merge.py should dedupe by id/url.
