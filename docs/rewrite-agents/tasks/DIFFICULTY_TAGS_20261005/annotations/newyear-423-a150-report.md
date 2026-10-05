# NewYear first150: unstarted scaffold

Root allocated existing exact-file lease targets using the task's existing
bounded text/JSON exception. No annotation decisions have been made here.
Scope is NEWYEAR_423_A_IDS.json; author and independent review are pending.
# New Year 423-A — first 75 annotation report

Scope is exactly the first 75 ordered identities in `NEWYEAR_423_A_IDS.json`, not the remaining 75 in that packet: 55 `new_year_arts_literature` records and 20 `new_year_cinema_intl` records. Baseline: `e802ed21db936bdb9809bab2d137903eb0aa425e`; taxonomy: `qm-tags-v1` / `09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.

Raw reading evidence: three complete, untruncated 25-record batches, each including stem, all options, stored correct-answer index/value, and explanation: arts records 1–25; arts records 26–50; arts records 51–55 plus cinema-intl 0–19. The candidate preserves the frozen first-75 order and has 75 unique question IDs.

Candidate SHA-256: `27772a627f1c72e06dadb3809e68fd0cea1ce2c1a16de78d87d7187ced7432a3`.

Source SHA-256 checked after annotation: `quizzes/NewYear/new_year_arts_literature.json` `9476758bbc8cb97f694aa302d3b8869f7eb0ca7dd6909eb0545adce455ffb603`; `quizzes/NewYear/new_year_cinema_intl.json` `871164ed5fa51fcb354eaa2d84afba6efdf67b614cc0a3b0fc6ccaef22c7836e`.

Levels: 1=1, 2=7, 3=16, 4=20, 5=17, 6=9, 7=5, 8–10=0. Forty records are low-confidence and flagged, principally where the stored answer key contradicts its explanation. Other retained flags cover duplicate content (one), answer cue in stem (three), premise ambiguity (four), factual claim needing source (three), a year-dependent claim, and two superlative claims needing source. All 75 have sorted predefined editorial tags, public-safe context subsets, a domain and a specific topic.

Validation: `python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/newyear-423-a150.json --partial` returned `Validated 75/4078 annotations; source integrity preserved.`

This is editorial metadata, not independent factual certification. The low-confidence and flagged rows need source/key review before any application or publication.

## Root correction after independent full75 review

The opening unstarted scaffold is historical. The original report incorrectly conflated39 low-confidence rows with40 flagged rows. Current corrected candidate has40 low-confidence and43 flagged rows. Root read all10 affected full raw records, added3 key-conflict flags and5 duplicate flags, corrected Scrooge reasoning/confidence, replaced ballet with approved sports/figure-skating tags, marked the Axel superlative and Grinch ambiguity. No numeric rating or source was changed. Dictionary425 preserves all423 former tag definitions; accepted2590 records received reference-only rebinds. Exact10-row evidence: review/NEWYEAR_A75_DELTA.json. Current SHA256 `d671840014dbd862d381a5bb7b7752389d4711173099ae01f36c70de081e4474`. Final delta review pending.
