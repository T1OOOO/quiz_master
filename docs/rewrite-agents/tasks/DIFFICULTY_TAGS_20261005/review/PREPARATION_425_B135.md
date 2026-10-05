# Preparation B135 independent metadata review

## Verdict: REWORK

Candidate reviewed: `annotations/preparation-425-b135.json`, SHA-256
`8a647d3a4bb86cffa44b2dba4e021cdc892668b8904cd7602871f03eacec8784`.

The partial validator passes (`Validated 135/4078 annotations; source integrity
preserved`). The 135 manifest identities and candidate identities are in the
same order; there is no B/C identity overlap. This is metadata review only: it
does not certify the historical, literary, or folklore claims in the source.

### Required metadata changes

| ID | Finding | Required change |
|---|---|---|
| `prep-folklore-003` | It and `prep-folklore-004` test the same kara-/konoha-tengu contrast in reciprocal form. The wording supplies the decisive physical description, making level 7 too high for an adult general-quiz item. Its narrow terminology has no source-quality flag. | Lower the difficulty after checking against the actual alternatives; add the applicable source-quality flag for the terminology and record the near-repeat relationship. |
| `prep-folklore-004` | Reciprocal near-repeat of `prep-folklore-003`; the long-nose cue identifies the answer directly, so level 7 overstates the task. No source-quality flag accompanies the specialised distinction. | Lower the difficulty after checking against the actual alternatives; add the applicable source-quality flag and record the near-repeat relationship. |
| `prep-folklore-008` | The three-part anatomical description is a specialised claim and drives a level-7 answer, but the annotation has medium confidence and no source-quality flag. | Add the applicable source-quality flag; re-evaluate the level after the source is checked. |

### Review coverage and evidence

- Parsed all 135 B annotations and its frozen manifest. The batch uses six
  source packs; its candidate order equals manifest order.
- The combined B/C candidate inventory is 265 records across 12 pack IDs;
  level distribution is 1:7, 2:46, 3:61, 4:63, 5:48, 6:24, 7:12, 8:3,
  9:1. This record-level enumeration was used to select the required strata.
- Full raw source read in this review: `prep-folklore-001` through
  `prep-folklore-010`, including stem, all alternatives, key and explanation.
  This includes all flagged/low rows in that first ten and the level-2/7/8/9
  items among them. The required combined stratified raw sample is 122 IDs;
  it was selected but **not completed** before this report. Do not represent
  this as a full independent raw review of B135.
- The candidate’s existing flags correctly retain caution for several
  version-specific and regional folklore claims; the three omissions above
  are metadata findings, not factual corrections.

No production files, source quiz records, imports, publication state, or Git
state were changed.
