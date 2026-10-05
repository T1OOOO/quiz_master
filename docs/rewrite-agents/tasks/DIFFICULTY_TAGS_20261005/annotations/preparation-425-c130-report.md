# preparation-425-c130 authoring report

Scope: the 130 ordered identities in `PREPARATION_425_C130_IDS.json`, authored as individual metadata assessments. Source baseline: `e802ed21db936bdb9809bab2d137903eb0aa425e`; taxonomy: `qm-tags-v1` / `07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151`.

## Source coverage

All 130 full source records (stem, choices, keyed answer and explanation) were read in chunks of 25, 25, 25, 25, 25 and 5. The seven frozen source-pack SHA-256 checks all matched `INVENTORY.json`: folklore `a9f5e30b…0677ee9`; Greek mythology `1174471c…9ff7f7`; history events `3194f2c7…681392`; musicals `6bcb3606…9c1b06`; Norse mythology `2233d4a2…53d9ea`; opera `ace5175d…51314f`; paintings `c30ed21d…e9f26c`.

## Editorial result

Candidate SHA-256: `0262FFFE44596E5E30DBC2E304ECE552381DB5D1A8F130487100A814622F2F35`.

Score counts: 1=7, 2=37, 3=35, 4=26, 5=14, 6=6, 7=3, 8=2, 9=0, 10=0. Every record has a literal rationale, sorted known tags with a domain and specific topic, and player-safe visible-theme context only.

Flagged IDs: `prep-folklore-011`, `prep-folklore-012`, `prep-folklore-013`, `prep-folklore-014`, `prep-folklore-015`, `prep-folklore-016`, `prep-folklore-017`, `prep-folklore-019`, `prep-folklore-020`, `greek-009`, `greek-012`, `greek-013`, `history-011`, `norse-011`, `norse-015`, `norse-016`, `norse-017`, `norse-020`, `music-oct3-010`, `music-oct3-058`, `music-oct3-060`, `wave20-paintings-002`, `wave20-paintings-003`, `wave20-paintings-005`, `wave20-paintings-010`, `wave20-paintings-016`. These retain uncertainty around variants, narrow source claims, or interpretation; none is factual certification. No record has low confidence.

## Checks

`python metadata/quiz_metadata.py check …preparation-425-c130.json --partial` passed: `Validated 130/4078 annotations; source integrity preserved.` Exact manifest order passed, with 130 records, 130 unique identities, zero missing and zero extra. Scan of the current accepted directory found 2,777 accepted keys and zero overlap. `git diff --check` passed for both owned leaves.

## Limits

This is an authoring candidate only. It does not accept, publish, alter source content, certify disputed claims, or replace independent review.
