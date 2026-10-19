# 53w8: independent country-facts review

**Reviewed:** 2026-10-19 (the client date)
**Scope:** source and quiz-ambiguity review only. This report does not change application or data files.

## Required data corrections and question gates

| Record | Required handling | Primary evidence |
| --- | --- | --- |
| `ZW` currency | Replace erroneous `ZWB`. The Reserve Bank says that the retired ISO code is **ZWL** and the replacement ISO alpha code for Zimbabwe Gold is **ZWG**. Store the national currency as `ZiG (ZWG)`; Zimbabwe's multiple accepted currencies mean a generic singular “currency of Zimbabwe?” card needs a label such as “national currency.” | [RBZ currency-code statement (2024)](https://www.rbz.co.zw/documents/press/2024/July/PRESS_STATEMENT_ON_ZiG_CURRENCY_CODE.pdf); [RBZ 2026 monetary-policy summary](https://www.rbz.co.zw/documents/mps/2026/2026_MPS_FINAL_-_At_A_Glance.pdf) |
| `US` official language | The 2025 federal executive action makes English the official language of the United States. Add `English` to the curated official-language field, with a retrieval/status date. | [White House fact sheet, 1 March 2025](https://www.whitehouse.gov/fact-sheets/2025/03/fact-sheet-president-donald-j-trump-designates-english-as-the-official-language-of-the-united-states/) |
| `ZA` languages and capital | Include **South African Sign Language**: the government lists twelve official languages. Do not ask a one-answer language question. Do not ask bare “capital of South Africa?”: Pretoria is administrative, Cape Town legislative and Bloemfontein judicial. | [Government of South Africa: country at a glance](https://www.gov.za/about-sa/south-africa-glance) |
| `NZ` languages | English is the de-facto common language. Māori and New Zealand Sign Language have explicit statutory official status; preserve that distinction in the data/model or do not make a naked “official languages” card. | [Māori Language Act 2016, s. 5](https://www.legislation.govt.nz/act/public/2016/17/en/2016-04-29.pdf); [New Zealand Sign Language Act 2006, s. 6](https://www.legislation.govt.nz/act/public/2006/0018/latest/DLM372759.html) |
| `MX` language | Do not make Spanish the sole “official language.” The federal language-rights law gives Spanish and Indigenous languages status as national languages with equal validity. A one-answer card is invalid. | [General Law on Linguistic Rights of Indigenous Peoples, Chamber of Deputies](https://www.diputados.gob.mx/LeyesBiblio/pdf/LGDLPI.pdf) |
| `AU` language | Keep legal official-language value empty. Parliament's paper says Australia has no official language and English is de facto national language. | [Parliament of Australia paper](https://www.aph.gov.au/DocumentStore.ashx?id=b2638e4e-1fb8-44dd-b92c-551ffdfccca1&subId=670871) |
| `GB` language | Keep legal official-language value empty. The UK government's toponymic guidance describes English as having no official status in any part of the UK; other languages have territory-specific statuses. | [UK Government guidance](https://www.gov.uk/government/publications/toponymic-guidelines/toponymic-guidelines-for-map-and-other-editors-united-kingdom-of-great-britain-and-northern-ireland--2) |
| `ER` language | Keep legal official-language value empty. The Constitution guarantees equality of all Eritrean languages, rather than naming one official language. | [Constitution of Eritrea, art. 4(3), WIPO Lex](https://www.wipo.int/wipolex/en/legislation/details/8937) |
| `JP` language | Retain `official_languages: null` unless the product introduces a separate category for main/national language. Government-facing English pages use both “Japanese” and “official language” terminology, so this is not a stable strict-legal one-answer card. | [Government of Japan overview](https://www.japan.go.jp/japan/index.html); [Japan National Tourism Organization FAQ](https://www.japan.travel/en/faq/) |
| `ID` capital | At the review date, continue to answer **Jakarta**. Otorita IKN says the formal transfer requires a Presidential Decree; no such decree was located in the current official material. Do not quiz Nusantara as an already-current capital. | [Otorita IKN statement, 21 May 2026](https://ikn.go.id/id/posts/pembangunan-ikn-maju-tanpa-ragu-otorita-ikn-tegaskan-progres-terus-berjalan); [Law No. 3/2022](https://peraturan.bpk.go.id/Download/192290/UU%20Nomor%203%20Tahun%202022.pdf) |
| `BO` capital | Do not ask a bare capital question. The Constitution calls **Sucre** the capital; the government describes **La Paz** as the seat of the executive, legislative and electoral organs. Ask with a qualifier. | [Constitution, art. 6](https://diputados.gob.bo/wp-content/uploads/2025/11/constitucion_politica.pdf); [Bolivian Ministry of Education](https://www.minedu.gob.bo/index.php?Itemid=889&id=1014%3Aboletin-informativo-avanzamos-n-07-2023&option=com_k2&view=item) |
| `NL` capital | Amsterdam is the national capital, while The Hague is the seat of government and parliament. Keep Amsterdam for a qualified capital card; avoid conflating it with the seat of government. | [European Union country profile](https://european-union.europa.eu/principles-countries-history/eu-countries/netherlands_en); [Dutch Government background publication](https://www.government.nl/binaries/government/documenten/publications/2017/04/21/culture-at-a-first-glance/CIB2015_ENG_publicatie_v8_DEF.pdf) |
| Population cards | The World Bank `SP.POP.TOTL` indicator is annual mid-year population, based on de-facto residents. Every prompt/result must show the value year (the asset requests 2024) and not attribute the figure solely to REST Countries. | [World Bank metadata for SP.POP.TOTL](https://databank.worldbank.org/metadataglossary/millennium-development-goals/series/SP.POP.TOTL) |

## Keep excluded pending a different legal-status model

The current source's `official_languages: null` for Argentina, Chile and Uruguay is safer than presenting a generic legal-official-language answer. No unambiguous current primary authority establishing a national one-answer list was verified in this bounded review. For context, Argentina's official gazette recognises Argentine Sign Language; that is not evidence for replacing the null field with a single national list. [Argentina official gazette](https://www.boletinoficial.gov.ar/detalleAviso/primera/285603/20230503). Uruguay's government-linked linguistic discussion itself notes that the Constitution does not prescribe a language. [Uruguay Ministry of Education and Culture attachment](https://www.gub.uy/ministerio-educacion-cultura/sites/ministerio-educacion-cultura/files/2025-07/ANL_GrosE_Discurso.pdf).

## Loader/data-model finding

`country_facts.json` contains non-null scalar `official_languages` values (for example `AT`, `BG`, `BR`, and `NL`), while the current Dart loader accepts only a JSON list. Normalize every non-null value to an array before the existing `cast<String>()`, then retain an explicit status/provenance field where legal and de-facto language claims differ. This is a data-contract issue, so no question card should be released merely because a generic source exposes a `languages` array.

## `country_presidents.json` review

The following checks are against the named official sources as retrieved on 2026-10-19. “Verified” means the source identifies the named officeholder; “source access risk” means the data value is plausible/current but the configured URL was not reliably fetchable in the review tool and should be augmented with an accessible official current page before release.

| ISO | Stored name | Result | Official evidence |
| --- | --- | --- | --- |
| `US` | Donald Trump | Verified | [White House administration](https://www.whitehouse.gov/administration/) |
| `FR` | Emmanuel Macron | Verified | [Élysée profile](https://www.elysee.fr/en/emmanuel-macron) |
| `RU` | Vladimir Putin | Source access risk: configured Kremlin structure URL timed out in review; retain only after an accessible current Kremlin record is captured. | [Configured Kremlin URL](https://kremlin.ru/structure/president) |
| `DE` | Frank-Walter Steinmeier | Verified from the indexed official profile; direct source fetch was intermittent. | [Federal President profile](https://www.bundespraesident.de/EN/federal-president/frank-walter-steinmeier_node.html) |
| `IT` | Sergio Mattarella | Verified | [Quirinale biography](https://new.quirinale.it/page/biografia) |
| `IN` | Droupadi Murmu | Verified | [President of India profile](https://www.presidentofindia.gov.in/president-india-smt-droupadi-murmu) |
| `KZ` | Kassym-Jomart Tokayev | Verified | [Akorda](https://www.akorda.kz/en) |
| `UA` | Volodymyr Zelenskyy | Verified | [Office of the President biography](https://www.president.gov.ua/en/president/biografiya) |
| `ZA` | Cyril Ramaphosa | Verified | [Government of South Africa, 17 Sep. 2026](https://www.gov.za/news/media-statements/president-cyril-ramaphosa-booked-public-engagements-17-sep-2026) |
| `BR` | Luiz Inácio Lula da Silva | Source access risk: the configured PDF redirected to an authentication barrier during review. Replace or supplement it with an accessible dated official `gov.br` record. | [Configured 2026 official PDF](https://www.gov.br/casacivil/pt-br/.arquivos/mensagem-ao-congresso-nacional-2026.pdf) |
| `TR` | Recep Tayyip Erdoğan | Source access risk: configured presidency site did not fetch in review. Preserve the name only with a dated accessible presidential source. | [Configured Presidency site](https://www.tccb.gov.tr/en/) |
| `MX` | Claudia Sheinbaum | Verified from a current Presidency press record. | [Presidency, 5 Sep. 2026](https://www.gob.mx/presidencia/prensa/gobernamos-para-el-pueblo-de-mexico-y-de-jalisco-presidenta-claudia-sheinbaum-desde-tlajomulco-de-zuniga?idiom=fr) |

The configured Mexico source is also a weaker choice than the dated press record above. No presidents data was edited as part of this review.
