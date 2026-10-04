# Independent final LOTR factual review

Status: `REVIEW_COMPLETE`. This is an independent editorial review of all 253 final candidate/key pairs at revision `396a1fd21866f80490c96bcf0dec589d9d8b60ce66470b503cb1fb774a198201`. It does not publish, import, or accept the quiz.

Blind-answer evidence predates the corresponding keys: `blind.json` covers the initial 153 (`FA0C697E893F5C62759A45F047203B7A3FBC5D477B1F86DD8336F4F323F1437A`) and `blind-return.json` covers Return 100 (`CE9448CAFEC6F9819FF1A24F849B039C5FE341CD3B76DBAE17C8369542E98B38`). Earlier-round reports were retained separately by the lead; this directory contains the current frozen-revision result.

The rewritten explanations for all 100 Two Towers cards were checked for substantive factual support and do not use the former generic answer-only form. The final five-card option delta was independently checked candidate-first: TT18 accurately scopes the warg-rider film attack; TT22 identifies the lower culvert/drain from Gríma’s film description; TT45’s Russian explanation is grammatical; TT52 asks the distinct Book IV Henneth Annûn waterfall fact; and TT59 asks the distinct Book III Dunland forces fact.

`review.json` contains one record for every final ID: 253 `accept`, 0 `revise`, and 0 `reject`. Its records include direct URL/chapter anchors. Freshly opened evidence included *The Two Towers*, Book III, *Flotsam and Jetsam* (Huorn theory); [IMSDb’s Two Towers script](https://imsdb.com/scripts/Lord-of-the-Rings-The-Two-Towers.html) (warg-rider attack and Gríma’s culvert description); *The Two Towers*, Book IV, *The Window on the West* (Henneth Annûn); the checked [Silmarillion language appendix](https://martijn.coppoolse.com/books/part/1238/elements-in-quenya-and-sindarin-names) (aran = king); [Appendix A](https://thefreenovelsread.com/the-return-of-the-king/book-vi-appendix-a-128582) and [Appendix B](https://thefreenovelsread.com/the-return-of-the-king/book-vi-appendix-b-128583); and the [Academy's 2004 results](https://www.oscars.org/oscars/ceremonies/2004) for “Into the West.” The ae-lib *Return of the King* mirror was not used as an appendix source because it ends at the Grey Havens.

Checks run from `C:\\ap\\quiz_master`:

- JSON parse and exact ID comparison: 253 review records, 253 unique, 253 final-key IDs, 0 missing, and 0 extra — passed.
- Schema/source check: every record has exactly `id`, `verdict`, `reason`, and `source`; every source begins with an actual URL — passed.
- Final candidate SHA-256: `B89EA4CAD25011D5C3F20D41BAE29D9124A05496A884B0703F7CE4FC0AACE996`.
- Final key SHA-256: `2CDF2CD5553B6DE4A3937F4CD6C3A3EA592B40F43DF4FF4EC0FC1B612F7397CD`.
- Review SHA-256: `E5D10119639B64DDB8D343CDAB1AE42F96170C1E311A5EAF76C0FE4B67071837`.

Remaining risk: the accessible full-text and script hosts are public mirrors, so edition and Russian-localization consistency should remain a release/editorial concern. No unresolved factual or option-integrity blocker remains at this frozen revision.
