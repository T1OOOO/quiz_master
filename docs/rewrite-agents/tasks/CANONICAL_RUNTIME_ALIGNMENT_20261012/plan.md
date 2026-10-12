# Canonical/runtime alignment follow-up plan

## Status and boundary

This is a read-only plan. It does not approve a source edit, change the current package, or certify the whole bank. Source commit `42a2aaf4ed66698d3f7303b716bbac36913ff139` remains pinned for the pending Next4C release work. Any alignment is a later, separately reviewed source-integrity task.

The comparison baseline must be explicit:

- Current Git canonical source is the source-42 tree.
- The previously verified runtime baseline is `C:/ap/quiz_master/.run/culture_next2b_release_20261012/quiz-2026.10.12-culture-939f231`.
- The Next4C V2 package preserves that runtime baseline for seven non-People paths. `preserved-runtime-clarification.json` records byte equality to that runtime baseline and public-production comparisons; it does **not** make the seven paths equal to current Git.

## Seven-path ledger

| Path | Evidence-backed distinction | Alignment decision needed |
| --- | --- | --- |
| `next/content/home-alone-1-part-1/bundle.json` | Git/V1 used `q-ha1-p1-7-opt-3`; preserved runtime uses `q-ha1-p1-7-opt-1`. The clarification records the preserved text as “Бросается на брата”, plus publication/version/difficulty metadata differences. The accepted V2 review traces this to the independently reviewed, out-of-band `HOME_ALONE_REPAIR_20261011`, published as `e0d13f4`. | Treat the key as editorial correction, not metadata. Cite that repair evidence and require independent answer-key review before choosing runtime-to-source alignment or a runtime correction. |
| `next/content/theme-harry-potter/bundle.json` | This is a real source/runtime content gap: Git/`939f231` contains the reviewed HP006 “hippogriffs” distractor while actual runtime bytes contain “ghosts”. The reviewed source fix did not reach production across at least two releases; it is tracked as `quiz_master-2ln.1`. V2 and live runtime wording match each other. | Do not call this normalization or metadata. Keep the source fix and runtime gap as a separately approved deployment/alignment decision. |
| `next/content/theme-harry-potter/draft.json` | The draft is part of the same HP006 source/runtime lineage; its text/version state cannot be decided separately from the bundle. | Retain the bundle and draft in one field-level decision record; do not align one independently. |
| `next/content/theme-harry-potter/manifest.json` | `source_sha256` follows the selected draft/bundle inputs. | Regenerate only after the approved draft/bundle disposition; never hand-edit the hash. |
| `next/content/cinema-encore-20261011/bundle.json` | The accepted V2 review reports version-tag-only drift and zero question-level differences; the clarification records matching public stems/options and exact public DTO equality. | Preserve this classification with an exact field diff, then regenerate from the approved canonical source. |
| `next/content/music-encore-20261011/bundle.json` | Same accepted finding: version-tag-only drift and zero question-level differences; public stems/options and exact public DTO equal the runtime. | Same bounded metadata proof and deterministic regeneration requirement. |
| `next/content/planet-paradoxes-20261010/bundle.json` | The accepted V2 review reports version-tag-only drift and zero question-level differences; the earlier review also identified a one-hour `published_at` change. | Verify timestamp/version provenance before deterministic regeneration. |

The evidence does not establish all seven files’ factual correctness. It establishes release lineage, the Home Alone repair trail, the distinct HP006 production gap, and a bounded metadata finding for the three remaining bundles.

## Review lineage to retain

1. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/static-v2-rework.json` is the independent review that detected the seven non-People Git/runtime differences and blocked describing them as People-only source changes.
2. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/static-final-acceptance.json` independently rechecked the prior runtime. It distinguishes the Home Alone repair from the HP006 hippogriffs/ghosts production gap and records the zero-question-diff finding for Cinema Encore, Music Encore, and Planet Paradoxes.
3. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/preserved-runtime-clarification.json` records the V2 byte and public-runtime comparison. Its current scope text explicitly says HP006 is a real pre-existing content gap, not metadata normalization.
4. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/release-evidence.json` records that V2 retained these paths from prior runtime rather than current Git, with `release-evidence-v2-before-clarification.json` preserved separately.

The follow-up must cite the underlying repair records named by the review (`HOME_ALONE_REPAIR_20261011`, `actualpublic-verification.json`, and `production-checkpoint`) for each actual change. A path without traceable predecessor data is blocked rather than copied in either direction.

## Smallest safe follow-up

Create a separate, post-release source-integrity task with write scope limited to these seven `next/content` paths and only generated files the deterministic pipeline necessarily changes. Do not include People packs, articles, catalog rows, or release directories in its initial scope.

1. Snapshot every path from source-42 and the stated prior runtime. Produce a field ledger with question ID, option ID/text, `correct_option_id`, source URI, revision/hash, version, and publication timestamp.
2. Attach repair/deployment evidence to every row. Classify it as editorial content/key, generated metadata, or unresolved. “Metadata-only” requires an observed field diff and accepted provenance.
3. Independently review the Home Alone key and the HP006 deployment gap before writing. Public API omission of private keys is not proof of grading correctness.
4. Make one approved disposition per pack: source-to-runtime alignment, runtime-to-source correction, or hold. Preserve question and option IDs, ordering, linked article IDs, and all unrelated private grading/revisions.
5. Run the importer/rehasher only in staging. Regenerate the Harry Potter manifest from approved draft/bundle inputs; never copy a runtime bundle into source.
6. Gate promotion on the field ledger, semantic parity for all non-target questions and private grading, unchanged article bodies/source references and question-article bindings, unchanged non-target catalog rows, taxonomy validation, and a different-provider review of the staged diff.

## Risks and hold points

- Copying old runtime may perpetuate the HP006 production gap; restoring Git blindly may change a live quiz without an approved rollout. Blindly reverting the Home Alone repair may regress a reviewed answer key.
- URI/revision changes can affect DTO equality and article bindings even when wording is unchanged; prove them field by field.
- Raw bundle copying bypasses canonical hashes and manifests. Use the existing import/re-hash pipeline.
- This plan contains no all-bank factual audit, test, build, browser, deployment, or publication result.
