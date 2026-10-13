# Home Alone Reader articles v3 — source evidence

Accessed 2026-10-13. Each linked page was opened as a full page, not used as a search snippet.

Article-body word counts use the `check_structure.py` token convention required by the lead: `question:q-ha1-p1-1` is 164 words and `question:q-ha1-p1-2` is 160 words.

| Article | Opened primary/licensed page | Claims supported |
| --- | --- | --- |
| `question:q-ha1-p1-1` | [20th Century Studios Family — Home Alone](https://family.20thcenturystudios.com/movies/home-alone) | Kevin’s first-film situation in suburban Chicago; the family’s France trip; Harry and Marv; 1990 release; Chris Columbus as director and John Hughes as writer. |
| `question:q-ha1-p1-1` | [Apple TV — Home Alone](https://tv.apple.com/us/movie/home-alone/umc.cmc.43qg0hbj3zyyum9us4nzbz9x5) | Cast-and-character mapping: Macaulay Culkin plays Kevin McCallister; synopsis of the child’s separation from his family. |
| `question:q-ha1-p1-2` | [Apple TV — Home Alone](https://tv.apple.com/us/movie/home-alone/umc.cmc.43qg0hbj3zyyum9us4nzbz9x5) | The first-film family trip is to Paris; Kevin is left behind and protects the home. |
| `question:q-ha1-p1-2` | [20th Century Studios Family — Home Alone](https://family.20thcenturystudios.com/movies/home-alone) | The first-film description says the family travels to France and Kevin remains in suburban Chicago. |
| `question:q-ha1-p1-2` | [20th Century Studios Family — Home Alone 2: Lost in New York](https://family.20thcenturystudios.com/movies/home-alone-2) | 1992 release; the family travels to Florida and Kevin reaches New York. |

## v2 scope and limits

v2 replaces only the first article’s body, title, and claim wording. It removes the v1 discussion of question-answering and source-verification procedure, and leaves the second article’s body and source links byte-for-byte unchanged. The distinction between a character, actor, director, and writer is explanatory terminology rather than a claim of unlisted production-credit detail.

Both rows preserve the exact published question bindings from `candidate-input.json`, including the runtime `/app` source URI provenance and the published SHA-256 values. These differ from older Git hashes because published metadata also has numeric difficulty levels. No question, answer, canonical source, runtime metadata, or Reader asset was edited. Independent review, binding/export validation, and publication remain outside this draft.

## Lead mechanical V3 correction

Only q1 narrative-analysis wording now explicitly says the story can be read this way and repeats that qualification. This addresses the fresh Claude delta review finding; it is an interpretation, not an extra primary-source fact. q2 remains exactly unchanged. Apple TV fresh static retrieval yielded only its storefront shell, so V3 retains the distinct earlier V1 independent full-page finding without claiming the delta reviewer reconfirmed it. No auth bypass or fabricated source access. Formal Hub V2 resubmission was denied; do not claim formal task acceptance.
