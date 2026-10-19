# Brand atlas v1 — independent fact review

Checked: 2026-10-19. Reviewer scope: `brands.json` and its source audit only;
no production record was edited by this reviewer.

## Verdict: REWORK

The registry is a useful, internally parseable starter set, but its historical
and ownership questions must not be released as answer-generating facts until
the required corrections below are applied. The important issue is not merely a
missing citation: several records currently make a question answerable with a
wrong date or an obsolete owner.

### Blind-answer check before reading keys

| Candidate-facing prompt | Independent answer | Result |
| --- | --- | --- |
| Which group ultimately owns the former Warner Bros. Discovery business as of 2026-10-19? | Skydance Corporation; WBD is a wholly owned subsidiary after the 6 October 2026 closing. | The corrected current registry now says this. |
| Who acquired Electronic Arts in 2026? | The PIF, Silver Lake and Affinity Partners consortium; closing was 4 August 2026. | The corrected current registry now says this. |
| When was the Samsung consumer-electronics company/brand founded? | 1969. The 1938 date is for the Samsung Group, not Samsung Electronics. | Still wrong in the reviewed record. |
| When did Pepsi introduce the red-white-blue bottle cap that evolved into the globe? | 1951. | Still wrong in the reviewed record (1950). |
| When was the LEGO name officially used? | January 1936 according to LEGO's current heritage article. | The 1934 logo entry is wrong in both date and category. |

## Ownership: current corrections rechecked

The parent applied both time-sensitive corrections correctly.

* `warner_bros`, `hbo` and `dc` now resolve to `skydance`, and their notes say
  that the WBD business joined Skydance on 6 October 2026. WBD's filed
  [Form 8-K](https://www.sec.gov/Archives/edgar/data/1437107/000119312526415055/d200872d8k.htm)
  states that WBD became a wholly owned subsidiary of Skydance. The
  [closing release](https://ir.paramount.com/news-releases/news-release-details/paramount-completes-acquisition-warner-bros-discovery-creating)
  independently names the resulting company Skydance.
* `electronic_arts` now resolves to `ea_consortium` and makes the 4 August
  2026 date explicit. EA's own [closing announcement](https://www.ea.com/amp/news/ea-announces-completion-of-acquisition)
  says that PIF, Silver Lake and Affinity Partners completed the acquisition
  and that EA shares ceased trading. The UI should retain the word
  “consortium”, so a quiz never implies there is one sole owner.

## Required record corrections

| Severity | Exact records | Required correction | Evidence |
| --- | --- | --- | --- |
| P1 | `samsung`, owner `samsung` | Keep `owner_id: samsung` for Samsung Electronics, set `founded_year` to **1969**, and change the date note to “Samsung Electronics was founded in 1969; 1938 is the Samsung Group's founding year.” Replace the ambiguous trading-company fact with a clearly qualified group-history fact. Add former company name `Samsung Electronics Industry Co., Ltd.` for 1969–1984 only if the UI labels it as a company name. | Samsung's [corporate overview](https://images.samsung.com/is/content/samsung/p5/global/ir/docs/2019_Business_Report.pdf) gives 13 January 1969 and the 1984 renaming. Samsung's [brand story](https://www.samsung.com/us/about-us/brand-identity/brand-story/) also begins the consumer-electronics story in 1969. |
| P1 | `pepsi.logo_history[0]` | Change 1950 to **1951** and use the precise statement: the red-white-blue bottle cap introduced in 1951 evolved into the globe logo. | PepsiCo's [Pepsi history](https://www.pepsico.com/newsroom/stories/2026/pepsi-history-brads-drink-iconic-american-brand) gives 1951, not 1950. |
| P1 | `prada`, owner `prada` | Remove `lvmh_history` from every Prada reference. It is a non-sequitur: Prada is not an LVMH house. Add a dedicated `prada_history` source and point its founding and leather/travel-goods fact to it. | The [Prada Group history](https://www.pradagroup.com/en/group/history.html) says the first Prada store opened in Milan in 1913. |
| P1 | `lego.logo_history[0]` | Remove the 1934 item from `logo_history`; it describes a company/name event, not a logo event. Do not replace it with another dated logo claim unless its year is directly sourced. Add a normal historical-name/fact item: the LEGO name was officially used from **January 1936**. | LEGO's [current name history](https://www.lego.com/en-gb/aboutus/news/2026/february/90-year-history-of-the-lego-name) and its [heritage article](https://www.lego.com/en-pt/history/articles/b-the-beginning-of-the-lego-group) say the official name use began in January 1936. |
| P1 | `warner_bros.logo_history[0]` | Remove the 1923 shield assertion. The cited `warner_history` company page does not establish either the first shield date or continuous central use. A logo question needs a direct Warner archive/brand-history source; otherwise retain no dated logo fact. | The registry's cited page is a WBD company page, while the current ownership change is documented separately by the SEC filing above; neither supports the logo claim. |
| P2 | `gucci.logo_history[0]`, `chanel.logo_history[0]`, `hermes.logo_history[0]`, `disney.logo_history[0]` | Remove the exact years 1933, 1925, 1950 and 1985 until each is backed by a direct house/studio logo-history source. These sources in the registry are generic house/company histories and do not show that the stated mark first appeared in that year. Do not convert an inferred or “associated with” year into a quiz key. | The checked sources do not support the exact-year claims. This is a source-to-claim failure, not a claim that the marks did not exist. |
| P2 | `dior.former_names[0]` | Remove `Christian Dior` as a “former name.” It is the house's formal name, while `Dior` is a short form; there was no stated replacement event. If the product needs it, add a future `formal_name` relation rather than teaching it as a rename. | `lvmh_history` identifies the house; it does not establish a 1946-to-present renaming. |
| P2 | `google.former_names[0]`, `bmw.former_names[0]`, `marvel.former_names[*]`, `dc.former_names[0]`, `loreal_paris.former_names[0]` | These are marked in their own notes as research projects, predecessors or company legal names. They must not power a “What was this brand formerly called?” question. Either introduce a `predecessor`/`company_former_name` relation or exclude these records from former-name quiz generation. | Google describes BackRub as a research project; BMW's BFW entry, Marvel's Timely/Atlas chain, DC's National Allied entry and L'Oréal's 1909 legal company name are lineage facts, not interchangeable brand renames. Marvel's [official history](https://www.marvel.com/articles/comics/stan-lee-silver-age-history-of-marvel-comics) and DC's [official history note](https://www.dc.com/blog/2023/04/13/taking-flight-twelve-moments-that-defined-superman) explicitly use predecessor language. |
| P2 | `adidas.former_names[0]`, `puma.former_names[0]` | Do not generate a direct rename question from the shared Dassler predecessor without a relationship qualifier. `Gebrüder Dassler Schuhfabrik` is shared lineage after a split, not a former name that unambiguously maps to one present brand. | Current notes identify a predecessor/split, not a one-to-one rename. Keep this as lineage until a `predecessor` relation exists. |
| P2 | `nestle` | Keep 1866 only as `date_scope: corporate_lineage`; replace the current claim that Henri Nestlé founded his company in 1866. The 1866 entity was Anglo-Swiss, founded by Charles and George Page. Henri Nestlé began his infant-food business in 1867; the businesses merged in 1905. | Nestlé's [company timeline](https://www.nestle.com/about/history/nestle-company-history) gives all three dates. Henri may remain as the named founder only with an explicit Nestlé-brand/company qualifier, not as sole founder of the 1866 entity. |
| P2 | `mini` | Clear `founders: [Alec Issigonis]`. Issigonis designed the original Mini; he was not a founder of the marque. Retain the 1959 product launch and, if useful, move his name to a clearly labelled designer fact. | The person role must not turn a design-credit question into a founder question. |
| P2 | `mercedes_benz` | Clear Carl Benz and Gottlieb Daimler from the generic `founders` field or label both as founders of predecessor companies. The present Mercedes-Benz brand was created by the 1926 merger of their companies. | Mercedes-Benz's [predecessor history](https://group.mercedes-benz.com/company/tradition/company-history/1886-1920.html) describes the two predecessor companies and their 1926 merger. Its [logo history](https://group.mercedes-benz.com/company/tradition/mercedes-benz/birth.html) supports the existing 1926 combined-sign logo, so that logo item may remain. |
| P2 | `porsche` | Keep 1948 only as `date_scope: brand_launch`; do not make it silently answer the date of Ferdinand Porsche's 1931 engineering office. If retaining people in `founders`, list **Ferdinand Porsche and Ferry Porsche**, whom Porsche calls the company founders in its 1948 account. | Porsche's [historical background](https://newsroom.porsche.com/en_US/company/porsche-cars-north-america-historical-background-18072.html) distinguishes the 1931 engineering firm from the 1948 company, while its [brand account](https://newsroom.porsche.com/en/2021/history/porsche-engineering-anniversary-90-years-24247.html) identifies 1948 as the sports-brand birth. |

## Audit and schema findings

1. `coverage_note_ru` and `coverage_note_en` say 66 records, whereas the
   reviewed JSON has **61 brands**, 39 owners and, after the ownership repair,
   41 sources. Correct the coverage note and `data-source-audit.md` so that
   the user-facing scope and the evidence file match the actual registry.
2. `data-source-audit.md` still describes the old WBD/EA ownership model and
   39 sources. Update its current-owner statements and counts after the data
   corrections, without claiming that a generic company page proves every
   founder, former-name or logo-year statement.
3. The schema calls all years `founded_year`, but several cards deliberately
   hold a parent-company or predecessor date (notably Marvel, DC and L'Oréal
   Paris). Before enabling “when was this brand founded?” generation for those
   cards, add a `date_kind`/`date_scope` field or exclude their dates from that
   question mode. Their current notes help a reader, but they do not make the
   bare answer unique.

## What can be accepted after the fixes

The following types of content are suitable for quiz generation once the table
above is applied: current owner/group with its “as of” date, unambiguous product
launch/founding year, explicitly labelled predecessor/company-name history, and
logo history only where an exact mark-and-year claim has a direct source.

No release, publication or full-corpus acceptance is asserted by this report.

## Recheck after correction batches

The following corrected records were re-read in the JSON and their primary
evidence was opened: the Skydance and EA consortium ownership changes;
Samsung's 1969 company date; Pepsi's 1951 bottle-cap event; Prada's dedicated
source; LEGO's January 1936 name fact; removal of unsupported logo years;
Nestlé's 1866/1867/1905 lineage; cleared MINI and Mercedes-Benz false founder
lists; and Porsche's 1931 engineering-company / 1948 first-branded-car
distinction. The Porsche [heritage timeline](https://investorrelations.porsche.com/en/about-porsche/heritage)
directly confirms both 1931 and 1948.

At this recheck point all 61 records had a `date_scope`, all nested source IDs
resolved, and the registry contained 39 owner/group records and 47 sources.
Two narrow changes remain necessary for the corrected subset to be accepted:

1. Clear `samsung.founders` (or add a separate, non-quiz `group_founder`
   relation). Lee Byung-chul founded the 1938 Samsung Group history, not the
   1969 Samsung Electronics company that the card now dates.
2. Set `nike.former_names[Blue Ribbon Sports].quiz_enabled` to `false`.
   Nike's own history says BRS was still operating when the first Nike shoe
   appeared in 1971, so this company-lineage entry must not yield a former-brand
   answer.

## Final corrected-subset verdict: ACCEPT, with bounded coverage

Both final fixes are present: `samsung.founders` is empty and the Blue Ribbon
Sports row has `quiz_enabled: false`. Static inspection of
`brand_atlas.dart` confirms that it validates `date_scope` and filters former
names by that flag before forming questions.

Current registry integrity evidence, run in `E:\Projects\quiz_master`:

```powershell
$d = Get-Content -Raw next/apps/quiz_app/assets/quizipedia/brands.json | ConvertFrom-Json
# 61 brands; 39 owners/groups; 47 sources; 0 blank date_scope values
# every brand and nested fact/former-name/logo source ID resolves
git diff --check -- next/apps/quiz_app/assets/quizipedia/brands.json `
  docs/rewrite-agents/tasks/BRANDS_UFE9/fact-review.md
```

The accepted corrected sample comprises the four current-owner records
(Warner Bros., HBO, DC and Electronic Arts), and the targeted Samsung, Pepsi,
Prada, LEGO, Warner Bros. logo, Gucci, Chanel, Hermès, Disney, Dior, Nestlé,
MINI, Mercedes-Benz, Porsche and Nike corrections. Their cited primary pages
were opened in this review. This is not a claim that every historic statement
in all 61 cards was individually re-researched; the intentionally broad
starter corpus needs additional per-sector checks before any assertion of full
factual acceptance.

`data-source-audit.md` now reconciles the mechanical totals (61 brands, 39
owners/groups and 47 sources) and records the Skydance/EA ownership evidence.
Its stated limit is appropriate: the primary-source review samples the
corrected subset and does not certify every historical statement in the
61-card starter corpus.
