# Preparation B135 independent metadata review

## Verdict: INCOMPLETE — no acceptance issued

Candidate reviewed: `annotations/preparation-425-b135.json`, SHA-256
`8a647d3a4bb86cffa44b2dba4e021cdc892668b8904cd7602871f03eacec8784`.

The partial validator passes (`Validated 135/4078 annotations; source integrity
preserved`). The 135 manifest identities and candidate identities are in the
same order; there is no B/C identity overlap. This is metadata review only: it
does not certify the historical, literary, or folklore claims in the source.

### Resolved delta recheck

| ID | Finding | Required change |
|---|---|---|
| `prep-folklore-003` | Rechecked in the source and literal delta. The options are untranslated creature/form names; the stem's bird description does not map directly to the answer name. | Keep level 7; the new low confidence, terminology-source and near-repeat flags are appropriate. |
| `prep-folklore-004` | Rechecked in the source and literal delta. The detailed long-nose option makes this materially easier. | Level 4, low confidence, country/skill tags and option-detail/source/near-repeat flags are appropriate. |
| `prep-folklore-008` | Rechecked in the source and literal delta. Only the keyed option combines three body details and is substantially longer. | Level 4, low confidence, country/skill tags and option-detail/version-source flags are appropriate. |

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
- Delta `PREPARATION_B135_DELTA.json` exactly records three changed and 132
  unchanged rows, with source fields unchanged and context tags unchanged. It
  matches B135 SHA-256 `f69f3cc5c2ce53a10f7132d7952b696bcb39afcf28e10a2fc7794bd634decf00`.
- The remaining 102 selected raw records are still required before a verdict.

No production files, source quiz records, imports, publication state, or Git
state were changed.
