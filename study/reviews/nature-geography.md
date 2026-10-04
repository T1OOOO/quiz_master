# Independent editorial review — nature and geography-countries

Status / task / model: `DONE_WITH_CONCERNS` — `quiz_master-0oj`, independent fact check by `review-nature-geography-0oj`.

Reviewed at source revision `10436f501fe8b08ba74776e5e3b44aa8afa6d065` on 2026-10-04. The files reviewed were uncommitted work belonging to other authors; they were not edited. This report is the only file written by this reviewer.

## Method and blind answers

I read both `questions.candidate.json` files before either key or article. These are my independent answers in candidate order (A–D, not zero-based JSON indexes):

| Module | Blind answers 001–020 | Comparison with key |
| --- | --- | --- |
| Nature | D, C, A, D, B, D, D, A, C, A, B, A, C, B, C, B, B, A, C, D | All 20 match (`3,2,0,3,1,3,3,0,2,0,1,0,2,1,2,1,1,0,2,3`). |
| Geography-countries | A, A, C, D, C, B, A, A, D, A, B, C, C, D, D, B, C, D, B, B | All 20 match (`0,0,2,3,2,1,0,0,3,0,1,2,2,3,3,1,2,3,1,1`). |

The mechanical cross-check also found 20 candidates and 20 keys in each module, identical ID sets, and exactly four options on every question. It is a consistency check, not the editorial verdict.

## Nature — `REVISE`

### Item verdicts

Every intended answer is factually correct, its distractors are not independently defensible under the stated wording, and its explanation is suitable for a beginner. `ACCEPT` below means the question/answer/explanation itself is ready; `REVISE` flags a concrete source-mapping repair before the module can be accepted.

| IDs | Verdict | Independent fact/explanation check |
| --- | --- | --- |
| 001 | ACCEPT | Selection is a generational change in inherited variation within a population, not an acquired trait of one individual. |
| 002 | ACCEPT | Decomposers return simpler substances from organic remains to the environment. |
| 003 | ACCEPT | Energy available to the next trophic level declines because organisms use energy and dissipate heat. |
| 004 | ACCEPT | “Keystone” concerns disproportionate ecological effect; it is not a size, rarity, or colour label. |
| 005–007 | ACCEPT, source-access concern | Condensation is gas→liquid; solar energy and gravity drive the water cycle; infiltration can recharge an aquifer. The claims are correct. See source limitation below. |
| 008–010 | ACCEPT | CO₂ uptake changes seawater chemistry; thermal stress contributes to bleaching; bleaching does not itself mean instant death. |
| 011–013 | ACCEPT | Most active volcanoes occur at plate boundaries; subduction is one plate descending beneath another; Hawai‘i is an intraplate hotspot chain. |
| 014–015 | REVISE source mapping | The answers distinguish non-native from invasive correctly. The linked USGS landing page did not open in this environment; replace or supplement it with a directly inspectable USGS definition. |
| 016 | REVISE source mapping | The answer and explanation correctly distinguish acclimatization from evolution, but `nhgri-natural-selection` supports selection/allele frequency rather than the altitude-acclimatization assertion. Add a source that specifically covers acclimatization. |
| 017 | ACCEPT | An ecosystem includes organisms, their interactions, and the physical environment; a food chain is only one feeding path. |
| 018 | REVISE source mapping | The answer is correct (coral polyps are animals with algal symbionts), but the cited NOAA climate page does not supply this animal/symbiosis fact. Cite a NOAA coral-biology/bleaching page as well. |
| 019–020 | ACCEPT | Plates move relative to one another at centimetres per year; asking for a mechanism is a sound causal-reasoning prompt. |

### Sources actually checked

Opened and relevant: [NHGRI variation activity](https://www.genome.gov/25019961/online-education-kit-activity-1-genetic-variation-in-populations) supports selective advantage and changing allele frequency; [EPA ecosystem primer](https://nepis.epa.gov/Exe/ZyPURL.cgi?Dockey=40000IKE.TXT) explicitly defines decomposers, ecosystem, and food web; [NPS glossary](https://www.nps.gov/articles/parkscience31-1_eckert-plumb.htm) defines a keystone species by its disproportionate effect; [NOAA coral climate](https://oceanservice.noaa.gov/facts/coralreef-climate.html) supports CO₂-driven acidification and warming/bleaching; and the cited [USGS tectonics page](https://pubs.usgs.gov/gip/volc/tectonics.html) opened through direct HTTP and explicitly describes plate-boundary volcanoes, subduction, and the Hawaiian hotspot chain.

Limitations are real, not inferred from a link label: the cited [USGS water-cycle FAQ](https://www.usgs.gov/faqs/what-earths-water-cycle) and [USGS invasive-species landing page](https://www.usgs.gov/science/invasive-species) returned 403 to direct HTTP in this session; the browser fetcher also timed out on them. USGS search-indexed first-party material corroborates the water claims, but that is not a substitute for a reviewer-opened target page. The source catalog's blanket `evidence_status: opened` therefore is not reproducible for these two URLs. The question facts remain correct; replace with an accessible official URL or retain captured/dated source evidence.

For the hotspot detail, a second primary USGS page, [Geology of Hawai‘i Volcanoes National Park](https://www.usgs.gov/geology-and-ecology-of-national-parks/geology-hawaii-volcanoes-national-park), was opened and confirms the Pacific Plate’s movement over a stationary plume and the age progression. It does not create a new required question change.

### Article, images, duplicate knowledge, and scores

The article is unusually clear for a beginner: it consistently explains mechanism before terminology, uses useful contrasts (energy vs. matter; warming vs. acidification), relates to all 20 questions, and gives usable retrieval exercises. The table is factually sound. The hero image is an attractive illustrative forest/ecosystem scene and contains no textual factual assertion; it is not treated as evidence.

The listed source quizzes (`dogs_science_and_experiments`, `nature_raccoons_anatomy`, `nature_raccoons_behavior`, `nature_raccoons_habitat`) concern dogs/raccoons. I found no duplicate nature question or near-duplicate knowledge target; a raccoon habitat prompt mentions invasive species, but it tests a species-specific example rather than this module’s definition/mechanism.

| Axis (5 max) | Score | Basis |
| --- | ---: | --- |
| Factual accuracy | 4 | All 20 answers and explanations are correct; three source mappings need repair or reproducible access. |
| Clarity | 5 | Concrete contrasts and short causal chains make the material accessible. |
| Interest | 4 | Reefs, Hawai‘i and water routes make concepts memorable; one short named ecosystem case could raise it further. |
| Question variety | 3 | Topics vary well, but all 20 use the same single-choice format and several are definition-recognition prompts. |
| Explanation quality | 5 | Explanations tell why the answer works and why each distractor fails without overstating certainty. |

**Minimum fix for acceptance:** repair source mappings/access for 014–016 and 018 (and preserve an auditable primary source for 005–007), then recheck only those records. No answer-key alteration is requested.

## Geography-countries — `REVISE`

### Item verdicts

All 20 blind answers match the key. None of the other three choices is a plausible co-correct answer under the actual wording.

| IDs | Verdict | Independent fact/explanation check |
| --- | --- | --- |
| 001–002 | ACCEPT | Latitude is north/south of the equator; longitude is east/west of the prime meridian. |
| 003 | ACCEPT | Equal latitude does not fix climate; elevation, currents, relief, winds and nearby water matter. |
| 004–008 | ACCEPT, source-access concern | Globe/projection/Mercator/equal-area claims and the loxodrome explanation are correct. The cited projection PDF was opened by direct HTTP but could not be text-extracted in the browser fetcher; preserve a page/section citation in evidence. |
| 009–012 | ACCEPT | M49 is a statistical identifier/grouping scheme, not a political-development ranking; a state boundary is political geography. |
| 013–015 | ACCEPT | UNCLOS Article 57 sets the EEZ maximum at 200 nautical miles; Article 58 preserves specified other-state freedoms; delimitation is needed between opposite/adjacent coasts. |
| 016 | ACCEPT | Locating parliament tests a political function, not a physical-geography fact. |
| 017 | REVISE duplicate knowledge | The statement is correct, but South Africa's three capital functions are already directly tested in `prep-capitals-1` and administrative South Africa is repeated in `prep-capitals-world`. Replace this item with another well-sourced multi-function-capital example, or explicitly mark it as intentional review rather than new knowledge. |
| 018–020 | ACCEPT | Asking the exact function prevents “largest city = capital” error; a map projection preserves properties selectively; classifying the question type is sound strategy. |

### Sources actually checked

Opened and substantively relevant: [NOAA latitude](https://oceanservice.noaa.gov/facts/latitude.html), [NOAA longitude](https://oceanservice.noaa.gov/facts/longitude.html), and the [NWS climate-factors PDF](https://www.weather.gov/media/ilm/Newsletter/WilmingtonWave_Fall_2018.pdf); the PDF lists latitude, elevation, ocean currents, topography and nearby water. [UNSD M49](https://unstats.un.org/unsd/methodology/m49/?hl=en-GB) confirms numerical codes for statistical processing, statistical-convenience groupings, mutually exclusive statistical geographies, and no UN definition of developed/developing countries. [South Africa’s official provinces page](https://www.gov.za/about-sa/south-africas-provinces) explicitly identifies Cape Town as legislative/Parliament, Bloemfontein as judicial, and Pretoria as administrative.

The cited [USGS map-projections PDF](https://store.usgs.gov/assets/mod/storefiles/PDF/16573.pdf) returned 200 by direct HTTP but did not produce inspectable text in the browser fetcher. Its proposition is corroborated by accessible USGS publication results, but the report should retain a stable page/section reference rather than relying on a generic file URL. The cited [UNCLOS Part V](https://www.un.org/Depts/los/convention_agreements/texts/unclos/part5.htm) returned 403 to the browser fetcher but 200 by direct HTTP; the opened text contains Articles 57 (maximum 200 nautical miles), 58 (navigation, overflight and cables), and 74 (delimitation). This satisfies the needed primary legal corroboration; the browser-only limitation should still be recorded in source evidence.

### Article, images, duplicate knowledge, and scores

The article is coherent and engaging, particularly the projection table, the distinction between physical and political geography, and the active-recall tasks. It accurately supports all questions. The important qualifier that M49 groupings are statistical rather than cultural/political is well handled. The hero image is a clear decorative illustration of a globe, map, coast and relief; it makes no verifiable factual claim and is not a source.

There is a substantive overlap with listed `source_quiz_ids`: `prep-capitals-1` already asks the legislative, administrative, and judicial capitals of South Africa, and `prep-capitals-world` asks its administrative capital. `study-geography-countries-017` reuses their core learning outcome (distributed capital functions) rather than merely using a different format. Questions 016 and 018 are general reasoning prompts, so they are adjacent reinforcement rather than duplicates. `prep-flags-world` has no relevant overlap.

| Axis (5 max) | Score | Basis |
| --- | ---: | --- |
| Factual accuracy | 5 | All 20 answers/explanations checked out, including M49 and UNCLOS qualifiers. |
| Clarity | 5 | The two-layer framing and projection comparison make distinctions easy to retain. |
| Interest | 4 | Greenland/Mercator, sea zones and capital functions provide strong hooks; a small worked coordinate example would add practice. |
| Question variety | 3 | Good conceptual spread but entirely single-choice and one core capital example repeats the assigned source quizzes. |
| Explanation quality | 5 | Each key explains the mechanism/category error rather than merely naming the option. |

**Minimum fix for acceptance:** replace or explicitly label `study-geography-countries-017` as deliberate spaced review and add a stable page/section reference for the projection source. Recheck 017 and the revised source evidence afterward. No other key change is requested.

## Fresh check evidence

Command (cwd `C:\ap\quiz_master`): PowerShell JSON cross-check of candidate/key counts, IDs and option counts; exit code 0. Result: both modules have 20 matching records and four choices per question. SHA-256 at review time:

| File | SHA-256 |
| --- | --- |
| `nature/questions.candidate.json` | `C46FFE37D0DBD5E8B9E91612E989152A9E09762D64F722BD7E5E9F8B9EB8352D` |
| `nature/questions.key.json` | `73E756BF2A47652B7AC31AE7ADC251A9891ACFFE06F60399D63AD15AA464F8F7` |
| `nature/article.md` | `4AB8B330EED2FEBDE29DD56AF33ADD7FF89423C990CD65D7541A7448D1A3FFD1` |
| `geography-countries/questions.candidate.json` | `02E5E564B69AD21E302638EDE289D5D889761175C271AA3FB71B6C3396DB06FB` |
| `geography-countries/questions.key.json` | `184BA685833DDBB72117EA75B5AF293EDA678E86FB9E886ABD24E20D7C38EF61` |
| `geography-countries/article.md` | `A9F8DA998B92CAC563CFB924DA8309A0EE40E461FB397F6645AC1FC1A73A8B95` |

No publication, import, production acceptance, or integration commit is claimed. Usage: unavailable.
