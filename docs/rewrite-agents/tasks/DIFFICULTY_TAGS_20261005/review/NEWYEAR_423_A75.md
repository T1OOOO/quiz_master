# NewYear 423 A75 — independent metadata review

## Verdict: REWORK

The first 75 annotations have complete individual rationales and accurately
flag most of the numerous frozen key/explanation conflicts. The omissions below
matter because an editor using the private metadata would miss invalid keys,
repeated questions, or an incorrect topic. This is a review of metadata only;
it neither changes nor fact-certifies the frozen source content.

### Required annotation corrections

1. Add `answer-key-conflicts-explanation` (with low confidence retained) to
   these three records. Their stored keys select an option contradicted by the
   same record's stem/explanation:

   - `q_new_year_arts_literature_16_new_year_arts_literature_17`: key is
     `Feliz Navidad`; the clue and explanation identify *I Saw Mommy Kissing
     Santa Claus*.
   - `q_new_year_arts_literature_29_new_year_arts_literature_30`: key says
     Scrooge's wife died; its explanation says he had no wife after Belle
     ended the engagement.
   - `q_new_year_arts_literature_36_new_year_arts_literature_37`: key is
     1979 while its explanation states the ABBA recording was in 1980.

2. Flag these actual duplicate clusters on every unflagged member:

   - `q_new_year_arts_literature_0_new_year_arts_literature_1` and
     `q_new_year_arts_literature_50_new_year_arts_literature_51` both ask who
     wrote the music for *The Nutcracker*.
   - `q_new_year_arts_literature_13_new_year_arts_literature_14` repeats
     Jacob Marley from the already marked
     `q_new_year_arts_literature_17_new_year_arts_literature_18`.
   - `q_new_year_arts_literature_38_new_year_arts_literature_39` and
     `q_new_year_arts_literature_51_new_year_arts_literature_52` both identify
     Taylor Swift's *New Year's Day* from the post-party/cleaning lyric.

3. `q_new_year_arts_literature_6_new_year_arts_literature_7` concerns figure
   skating, not ballet. `domain:arts` and `topic:ballet` in both tag lists are
   inaccurate. The frozen dictionary has no sports/figure-skating equivalent;
   record that as a private taxonomy-gap concern and request the root's
   vocabulary decision rather than publishing ballet as the subject.

4. `q_cinema_intl_19` uses “подружка Гринча”, which can mean the adult romantic
   interest Martha May or the child Cindy Lou Who named by the key/explanation.
   Lower confidence and add a wording-ambiguity flag; the current high
   confidence overstates the precision of the wording.

5. Correct the author report's count: the current first-75 candidate has 39
   `low` records and 40 flagged records, not “Forty records are
   low-confidence and flagged.”

### Review evidence

- I independently read all 75 raw records in five untruncated groups of 15,
  including every stem, all options, stored key and explanation, together with
  each paired annotation. The frozen first-75 selection matches the candidate
  in order: 75/75 unique IDs.
- Fresh command from `C:/ap/quiz_master`: `python metadata/quiz_metadata.py
  check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/newyear-423-a150.json
  --partial` passed: `Validated 75/4078 annotations; source integrity
  preserved.` This structural pass does not resolve the editorial findings.
- Candidate SHA256:
  `27772a627f1c72e06dadb3809e68fd0cea1ce2c1a16de78d87d7187ced7432a3`;
  report SHA256:
  `76094c78ebe52f53242d583156e099d37860b5bd10e5550c048ddef3c301d83e`.
  Taxonomy reference is the actual 423 semantic SHA
  `09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.
- Source SHA256s independently read: `new_year_arts_literature.json`
  `9476758bbc8cb97f694aa302d3b8869f7eb0ca7dd6909eb0545adce455ffb603`;
  `new_year_cinema_intl.json`
  `871164ed5fa51fcb354eaa2d84afba6efdf67b614cc0a3b0fc6ccaef22c7836e`.
- Current candidate statistics: levels 1–7; 39 low-confidence and 40 flagged
  records. Public-context/privacy and known/sorted-tag structural checks pass.

Remaining limit: the many existing answer-key and factual-source concerns are
private flags, not independent source verification or publication approval.

## Final 10-row delta recheck — ACCEPT

I rechecked the supplied `NEWYEAR_A75_DELTA.json` against the live candidate,
then reread the full raw stem, options, stored key, and explanation for each
of its ten changed IDs. The delta declares exactly ten unique annotation
changes and `source_changes: false`; every `after` record and its declared
field set matches the current candidate. The other 65 first-75 records are
outside that declared delta scope.

The three added key/explanation conflict flags match the raw records; the
five reciprocal duplicate links are present; the Scrooge row is now low
confidence with the explicit wife/no-wife contradiction; and the Axel and
Grinch rows now carry the stated superlative and wording-ambiguity concerns.
The updated report correctly states 40 low-confidence and 43 flagged rows.

The candidate SHA256 is
`d671840014dbd862d381a5bb7b7752389d4711173099ae01f36c70de081e4474`,
matching the delta's `after_sha256`. The two frozen source hashes remain
`9476758bbc8cb97f694aa302d3b8869f7eb0ca7dd6909eb0545adce455ffb603`
(arts/literature) and
`871164ed5fa51fcb354eaa2d84afba6efdf67b614cc0a3b0fc6ccaef22c7836e`
(cinema), and a fresh partial check passed: `Validated 75/4078 annotations;
source integrity preserved.`

I also validated the applied 425-tag taxonomy. Its semantic SHA is
`07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151`;
`domain:sports` and `topic:figure-skating` are player-safe and the latter has
the former as parent. The candidate reference matches it. The reference-only
rebind manifest records 2,590 accepted rows and explicitly describes no
record-decision change.

This is an acceptance of the bounded metadata delta only. It does not certify
the flagged source facts, correct frozen quiz content, or approve publication.
