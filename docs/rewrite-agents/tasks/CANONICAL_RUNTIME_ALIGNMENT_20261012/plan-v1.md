# Canonical/runtime alignment follow-up plan

## Status and boundary

This is a read-only plan. It does not approve a source edit, change the current package, or certify the whole bank. Source commit `42a2aaf4ed66698d3f7303b716bbac36913ff139` remains pinned for the pending Next4C release work. Any alignment is a later, separately reviewed source-integrity task.

The comparison baseline must be explicit:

- Current Git canonical source is the source-42 tree.
- The previously verified runtime baseline is `C:/ap/quiz_master/.run/culture_next2b_release_20261012/quiz-2026.10.12-culture-939f231`.
- The Next4C V2 package preserves that runtime baseline for seven non-People paths. `preserved-runtime-clarification.json` records byte equality to that runtime baseline and the public production comparisons; it does **not** make the seven paths equal to current Git.

## Seven-path ledger

| Path | Evidence-backed distinction | Alignment decision needed |
| --- | --- | --- |
| `next/content/home-alone-1-part-1/bundle.json` | The V2 review found a real answer-key difference: Git/V1 used `q-ha1-p1-7-opt-3`; preserved runtime uses `q-ha1-p1-7-opt-1`. The clarification records the preserved key text as “Бросается на брата”, and also records metadata differences (publication date, `2026.10.11.duplicates`, and `difficulty_level`). | Treat the key as an editorial correction, not metadata. Locate its prior repair evidence and require an independent answer-key review before selecting runtime-to-source alignment or a runtime correction. |
| `next/content/theme-harry-potter/bundle.json` | The review reported a choice-text difference plus bundle version/date drift. The clarification says public stems/options match current production, while its exact public DTO mismatch is attributable to runtime source/revision normalization. | Diff fields from the named Git and runtime baselines. Any text difference needs its own source/evidence decision; only demonstrated URI/revision fields may be classified as normalization. |
| `next/content/theme-harry-potter/draft.json` | The review reported the same choice-text and version/date lineage issue. | Keep its question text and the bundle in one decision record; do not align one independently. |
| `next/content/theme-harry-potter/manifest.json` | The review reports `source_sha256` drift following the draft/bundle divergence. | Regenerate only after the approved draft/bundle disposition; never hand-edit the hash. |
| `next/content/cinema-encore-20261011/bundle.json` | The review reported bundle hash/version drift. The clarification records matching public stems/options and exact public DTO equality with production. | Verify field-level diff before calling it metadata-only, then regenerate from the approved canonical source. |
| `next/content/music-encore-20261011/bundle.json` | Same reported bundle hash/version drift; clarification records matching public stems/options and exact public DTO equality. | Same metadata-only proof and deterministic regeneration requirement. |
| `next/content/planet-paradoxes-20261010/bundle.json` | The review reported bundle hash/version drift and a one-hour `published_at` change; clarification records matching public stems/options and exact public DTO equality. | Verify the exact timestamp/version provenance before a deterministic regeneration. |

The current evidence deliberately does not establish that the Harry Potter choice text or the Home Alone key is factually correct. It establishes a release-lineage discrepancy and a documented prior-runtime preservation decision.

## Review lineage to retain

1. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/static-v2-rework.json` is the independent review that detected the seven non-People Git/runtime differences, including the Home Alone key and Harry Potter text concern. Its scope finding correctly prevented an undisclosed change from being described as a People-only source change.
2. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/preserved-runtime-clarification.json` records Root’s subsequent byte comparison to the prior verified runtime, public DTO/stem/option comparisons, the preserved Home Alone private key, and the limitation that no private keys are returned by the public API.
3. `docs/rewrite-agents/tasks/CULTURE_NEXT4C_20261012/release-evidence.json` records that V2 retained those paths from the prior runtime rather than from current Git, and preserves the earlier V2 evidence separately as `release-evidence-v2-before-clarification.json`.

The follow-up must locate and cite the underlying prior repair evidence mentioned by the clarification (`actualpublic-verification.json` and `production-checkpoint`) for each path. If an individual repair cannot be traced to a review and exact predecessor data, that path is blocked rather than copied in either direction.

## Smallest safe follow-up

Create a separate, post-release source-integrity task with write scope limited to these seven `next/content` paths and only the generated files that the existing deterministic pipeline necessarily changes. Do not include People packs, articles, catalog rows, or release directories in its initial scope.

1. Snapshot each path from source-42 and the stated prior runtime. Produce a field-level ledger with question ID, option ID/text, `correct_option_id`, source URI, revision/hash, version, and publication timestamp.
2. Attach the prior repair evidence to every ledger row. Classify each row as either editorial content/key, generated metadata, or runtime normalization. “Metadata-only” requires an observed field-level diff, not inference from a matching public screen.
3. Obtain independent review of the Home Alone key and every Harry Potter text row before writing. Do not turn the public API’s omission of a private key into proof of grading correctness.
4. Make one approved disposition per pack: align source to the preserved runtime, repair the runtime lineage in source, or leave it unchanged pending evidence. Preserve question and option IDs, ordering, linked article IDs, and all unrelated private grading/revisions.
5. Run the existing importer/rehasher in a staging copy, never by copying a runtime bundle over source. Regenerate the Harry Potter manifest only from its approved draft/bundle inputs.
6. Gate promotion on exact bounded diffs: seven-path field ledger; byte/semantic parity for every non-target quiz question and private grading entry; unchanged article bodies/source references and question-article bindings; unchanged catalog rows outside the target packs; taxonomy validation; and an independent-provider review of the final staged diff.

## Risks and hold points

- Blindly copying the old runtime could preserve an incorrect Home Alone key or stale Harry Potter text; blindly restoring Git could regress current production behavior.
- URI/revision normalization may change DTO equality or article bindings even when public wording is unchanged. It must be separately proven rather than silently normalized.
- A raw bundle copy can bypass canonical hashes and manifests. The existing import/re-hash pipeline is the only acceptable alignment path.
- This plan has no all-bank factual audit, deployment, publication, browser, or test result. Those remain outside this read-only task.
