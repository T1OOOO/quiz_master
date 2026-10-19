# Brand atlas v1 — source and coverage audit

Checked: 2026-10-19.  The shipped registry is
`next/apps/quiz_app/assets/quizipedia/brands.json` and follows
`qm-brand-atlas/v1`.

## Deliberate scope

This is a 61-record starter corpus for learning, not a claim to enumerate every
brand in the world or to settle trademark law.  It has 39 owner/group records,
six sectors and eleven countries.  It covers technology; automotive; sports and
fashion; fashion and luxury; food and beverages; and media and games.  Every
brand has an explicit group/owner relationship, source IDs, a launch/founding
date note, and one concise fact. Twenty-four brand records carry historical names and
the final reviewed data has sixteen records with logo-history notes, twelve of
them dated. The app must show the coverage note and
source links rather than imply completeness.

## Method

The final source registry contains 47 official company, group, heritage or investor references.
URLs were opened on 2026-10-19 in batches; inaccessible endpoints were retained
only as direct citation pointers and are not a substitute for later independent
review.  Particularly substantive primary pages opened successfully include:

| Area | Opened primary evidence | What it anchors |
| --- | --- | --- |
| Apple | Apple 50-year newsroom article | 1 April 1976 founding date and product-history context |
| Google | Google `Our story` | 1998 incorporation, BackRub, LEGO server and first Doodle |
| Microsoft | Microsoft company-history pages | 1975 founding, Micro-soft and Altair BASIC context |
| Nike | NIKE company and Swoosh-history pages | group relationship, Blue Ribbon Sports and 1971 Swoosh account |
| adidas | adidas Group history | 1924 predecessor, 1949 registration and three-stripes history |
| Toyota / BMW / Mercedes-Benz / Volkswagen | Official group-history and portfolio pages | founding qualifiers, official brand-group relationships and dated marks |
| McDonald's | McDonald's corporate history | 1940 restaurant, 1948 service change, 1955 Kroc system and franchise distinction |
| Kering / Gucci | Kering Gucci house page | 1921 founding and Gucci's 1999 entry into Kering |
| KitKat | Nestlé Kit Kat fact sheet | Hershey manufactures/sells KitKat in the US under Nestlé licence |

The official pages for some fashion portals (for example Hermès and Inditex)
were unavailable to the reader or redirected to a storefront during this pass.
Their links remain in the data for traceability, but their historical claims are
review targets rather than evidence of a successful fetch.

## Ownership rules applied

* A parent/group is not silently substituted for its brand.  Disney/Pixar/Marvel,
  Alphabet/Google/YouTube, NIKE/Converse and Volkswagen Group marques are marked
  as group relationships.
* McDonald's and KFC restaurant operations are marked as possibly franchised.
* Starbucks remains owned by Starbucks Corporation; the Nestlé packaged-goods
  arrangement is a licence, not brand ownership.
* KitKat has a country-specific qualification: Nestlé's fact sheet identifies
  Hershey as US manufacturer/seller under licence.
* PUMA is assigned to PUMA SE.  A shareholder must never be represented as the
  owner of the PUMA brand merely because it holds a stake.

## Mechanical integrity evidence

Run from `E:\Projects\quiz_master`:

```powershell
$d = Get-Content -Raw next/apps/quiz_app/assets/quizipedia/brands.json | ConvertFrom-Json
# Final: 61 brands, 39 owners/groups, 47 sources, 24 brands with historical names,
# 16 brands with logo history, including 12 dated entries.
```

The same check resolved every `owner_id` and every source ID used by a brand,
fact, former-name item and logo-history item: `bad_owners=0 bad_sources=0`.
`git diff --check -- next/apps/quiz_app/assets/quizipedia/brands.json` completed
without output.

## Review priorities

An independent content reviewer should sample every sector and focus on dates
which distinguish a brand launch from a corporation/predecessor, logo dates,
and ownership/territorial licences.  The registry intentionally does not include
logo image files: its logo field is dated, source-linked history for quiz prompts.

## Integration corrections after independent review

`fact-review.md` records the initial findings and the final sampled recheck;
`data_corrections.py` applies the historical/date fixes. The current snapshot
uses Skydance Corporation as the parent of the former WBD business after the
6 October 2026 closing (SEC filing), and the PIF / Silver Lake / Affinity Partners
consortium for EA after the 4 August 2026 closing (EA announcement). It does not
present those businesses as independently owned groups as of 19 October.

Samsung Electronics uses its 1969 company date, while its group’s 1938 history
is a separate fact. Nestlé qualifies the 1866 Anglo-Swiss predecessor, Henri
Nestlé’s 1867 business and the 1905 merger. Porsche uses the 1931 engineering
company date and separately explains the first branded car in 1948. Date scopes
distinguish company/brand/product/service/name, store/restaurant/franchise and
predecessor events. Ambiguous lineage entries remain readable but cannot generate
literal former-name questions. Unsupported exact logo years were removed;
Pepsi uses the directly sourced 1951 bottle-cap event, while LEGO’s 1936 name
history is an ordinary fact, not a logo-creation date. Designer and predecessor
founder names were removed from the relevant brand-founder fields.

The original 39-reference candidate was expanded with eight more focused primary
references during review. This is sampled independent fact checking, not a claim
that every historical statement in every card has been individually researched.
