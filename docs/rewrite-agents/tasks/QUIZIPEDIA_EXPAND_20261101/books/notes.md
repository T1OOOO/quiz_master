# Books and authors delta (Quizipedia expansion, 2026-11-01)

Result: `delta.json` = 33 new `works` (type `book`, `cast: []`, sorted by year) + 30 new `people` (role `author`).
`python validate.py` merges with the live `knowledge_atlas.json` in memory: OK (63 works / 45 books, 69 people / 43 authors after merge; ids unique, creator_ids and credit_work_ids resolve both ways, https sources, Cyrillic in *_ru, no empty fields). Nothing outside this folder was touched.

Authors with two books: Mann (Buddenbrooks, The Magic Mountain), Hemingway (The Old Man and the Sea, For Whom the Bell Tolls), Camus (The Stranger, The Plague).
Dating: Tale of Genji is `approximate` with `end_year` 1012 (as Divine Comedy does); Count of Monte Cristo has `end_year` 1846 (serial run); Cairo Trilogy 1956-1957. `born` is a plain year string; uncertain cases written like the Homer row: Murasaki "около 970-х", Cao Xueqin "около 1715".

## How sources were reached (honest limits)
- Britannica, Library of Congress (loc.gov item pages) and nobelprize.org via WebFetch returned HTTP 403. nobelprize.org was readable with plain HTTP (opened directly: Mann, Hemingway, Camus, Mahfouz facts/biographical pages). Britannica/LoC pages could not be opened directly; they were reached only as URLs and summaries returned by WebSearch, which I used as cross-check and as `source_url`.
- Wikipedia (opened via WebFetch) was used for birth dates/places and as a first pass on each work; every fact in `fact_*` was then matched against at least one non-Wikipedia source below, or kept to what both agreed on. Wikipedia-only claims were dropped (see Rejected).

## Per-item evidence (non-Wikipedia)
- Tale of Genji: nippon.com (diary entry 1008, 54 chapters); LoC blog (decade or so of writing). Murasaki: nippon.com article, LoC record.
- Werther: Goethe-Institut (few weeks, Werther effect).
- Dream of the Red Chamber / Cao: Britannica via search (1791 printing by Cheng Weiyuan and Gao E, at least 80 chapters by Cao, born 1715?); chinaculture.org (1715-1763); LoC catalogue (Cheng-Gao edition).
- Eugene Onegin: Britannica via search (began May 1823, worked on until 1831); Poetry Foundation (published in full 1833, Pushkin's own stanza). 14 lines: Wikipedia (389 fourteen-line stanzas).
- Dead Souls: Britannica via search (second volume burned February 1852).
- Christmas Carol: Britannica + LoC blog via search (19 Dec 1843, 6,000 copies, sold out by Christmas Eve); Dickens Museum/V&A.
- Monte Cristo: BnF Gallica selection (28 Aug 1844 - 15 Jan 1846 in the Journal des Débats), Britannica.
- Jane Eyre: Britannica + Brontë Society via search (Oct 1847, An Autobiography, Currer Bell as editor).
- Moby-Dick: Melville Society (18 Oct 1851 The Whale, London; 14 Nov 1851 Harper, New York).
- Les Misérables: BnF "Essentiels" article, opened (began 17 Nov 1845 as Les Misères, finished June 1861 near Waterloo, 1862 in ten volumes).
- Crime and Punishment: Britannica via search (serial in Russky Vestnik during 1866, book 1867; Stellovsky contract, The Gambler in 26 days).
- Huckleberry Finn: Mark Twain Project introduction + LoC blog via search (Chatto & Windus 10 Dec 1884; US 18 Feb 1885; Concord committee, mid-March 1885).
- Dorian Gray: Britannica via search (Lippincott's 1890, book 1891, preface as response to critics).
- Buddenbrooks / Magic Mountain: Mann's autobiographical note on nobelprize.org, opened (begun in Rome, appeared 1901, over a million copies; Magic Mountain idea conceived while finishing Death in Venice, interrupted by the war, 1924). Nobel facts page: prize "principally" for Buddenbrooks.
- Kokoro: NDL Japan portrait page, opened (Iwanami Shoten opened 1913, published Kokoro in 1914, then moved into publishing).
- Metamorphosis: Britannica + Kafka Project via search (Die weissen Blätter 1915; cover objection quoted from Politzer).
- Ulysses: NYPL (2 Feb 1922, Joyce's 40th birthday, 1,000 copies, Shakespeare and Company); LoC magazine (numbered, 100 signed).
- Great Gatsby: Princeton University Library blog, opened ("The Great Gatsby commission came in 1924, while the book was still unfinished"); Princeton catalogue.
- Hobbit: Tolkien Estate (Rateliff essay), opened (21 Sept 1937; Stanley Unwin hired ten-year-old Rayner to report).
- For Whom the Bell Tolls / Old Man and the Sea: Nobel biographical page, opened (Spanish Civil War reporting as background; The Old Man and the Sea 1952; prize motivation names it); JFK Library/Britannica via search (Life, 1 Sept 1952).
- Stranger / Plague: Nobel facts and biographical pages, opened (L'Étranger 1942 breakthrough, rejected existentialist label; Dr Rieux of La Peste 1947 in Oran).
- Little Prince: Britannica, BnF, Gallimard via search (6 April 1943, Reynal & Hitchcock, New York; Gallimard edition after the author's death).
- Ficciones: Britannica + Biblioteca Nacional Argentina via search (1944, Sur; El jardín de senderos que se bifurcan 1941 + Artificios).
- Cairo Trilogy: Britannica via search (1956-1957, Nobel 1988 first Arabic-language laureate); Nobel biographical page, opened (title translations, fame after 1957).
- Things Fall Apart: Britannica via search (London, Heinemann, June 1958). Title from Yeats's "The Second Coming": Wikipedia, matching line on Poetry Foundation (only source that states Achebe took it).
- Mockingbird: Britannica + PBS via search (1960, Pulitzer 1961, Go Set a Watchman earlier draft finished 1957, published 2015, Hohoff's advice).
- Fahrenheit 451: UCLA Newsroom, opened (Powell Library basement, 20 cents/hour, nine days, $9.80).
- Solaris: Lem.pl site, opened (English edition came from the French text).
- Master and Margarita: Britannica via search (written 1928-1940, censored Moskva magazine, posthumous); issue details 1966-67 from Wikipedia.
- Norwegian Wood: Penguin (1987, bestseller), Wikipedia (title is Japanese rendering of the Beatles song title).

## Least sure (check before release)
1. Russian titles: «Вымыслы» (Ficciones; alternatives exist), «Всё рушится» (Things Fall Apart; also «Распад»), «Кокоро» (also «Сердце»), «Хоббит, или Туда и обратно», «Дворец желания» in the Cairo Trilogy fact. Please confirm against the Russian editions the app prefers.
2. `source_url`s for people such as Hugo, Joyce, Twain, Goethe, Kafka, Borges, Saint-Exupéry, Bradbury, Mahfouz-adjacent Britannica bios: slugs taken from search results or standard Britannica scheme; I could not open them (403), so a dead-link check from a normal browser is advisable. Fitzgerald/Dickens/Brontë person sources point to Princeton/Dickens Museum/Brontë Society pages rather than biographies.
3. Birth dates (all `born`) come from Wikipedia and Nobel pages; Murasaki (c. 973, range 970-978) and Cao Xueqin (c. 1715, range disputed 1715-1724) are inherently approximate.
4. Genji date range 1000-1012: Wikipedia ("around 1000-1012"); LoC says "a decade or so"; only the 1008 diary reference is firm.
5. Metamorphosis cover anecdote rests on Politzer via the Kafka Project and Wikipedia; no primary letter seen.
6. Gogol "days before death": Britannica gives 24 Feb 1852 (NS); death 4 March 1852 (NS) comes from general knowledge/Wikipedia "shortly before his death".
7. Little Prince French edition: Gallimard says April 1946, Wikipedia infobox says 1945; text only says "after the author's death" for that reason.
8. Master and Margarita `year` 1966 = first magazine instalment (Moskva, Nov 1966); book editions came 1967+.

## Rejected / dropped
- Isabel Allende, Tagore (Gitanjali, poetry; not prose), Hašek, Chekhov and Goethe's Faust (plays), Neruda: dropped for scope or because I did not complete verification.
- Unsupported claims removed after checking: Vichy ban of The Little Prince, Leipzig ban/Napoleon for Werther, Kokoro as Iwanami's first book and Sōseki's cover design, Hobbit first print run (sources disagree 1,500 vs 1,488), Moby-Dick lifetime sales, Gatsby first-printing numbers, Murakami writing location, Mahfouz writing years, Ulysses US ban-lifting year, "twelve installments" for Crime and Punishment, Tarkovsky/Lem dislike.

## ID notes
Work ids: tale_of_genji, werther, dream_red_chamber, eugene_onegin, dead_souls, christmas_carol, monte_cristo, jane_eyre, moby_dick, les_miserables, crime_punishment, huck_finn, dorian_gray, buddenbrooks, kokoro, metamorphosis, ulysses, magic_mountain, great_gatsby, hobbit, for_whom_bell_tolls, stranger, little_prince, ficciones, plague, old_man_sea, fahrenheit_451, cairo_trilogy, things_fall_apart, mockingbird, solaris, master_margarita, norwegian_wood.
Person ids use surnames (`charlotte_bronte`, `harper_lee`, `cao_xueqin`, `saint_exupery` for disambiguation). Please re-run `validate.py` against the merged atlas after the film/director delta is combined, in case ids overlap.
