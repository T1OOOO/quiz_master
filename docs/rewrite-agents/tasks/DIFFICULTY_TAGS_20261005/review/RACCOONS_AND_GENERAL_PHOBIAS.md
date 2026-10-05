# Independent review — raccoons and general phobias

## Verdict

**Requirements compliance: ACCEPT.** Both annotation candidates meet the frozen v1 envelope, exact identity coverage, score and tag requirements for this review scope. Existing low-confidence and factual/ambiguity flags remain review work; they do not establish factual correctness and have not been treated as a reason to alter the private difficulty estimate.

**Code quality: not applicable.** This is a read-only editorial review of JSON candidates; no production implementation, application, publication, or acceptance is asserted.

## Inputs and preservation evidence

| Input | SHA256 / result |
| --- | --- |
| `annotations/raccoons.json` | `9a532565bb7bde89cd833507f10fa622918e0db4df15459fa40691f410e41415`; 250 records |
| `annotations/raccoons-report.md` | `c5acbd3b3c17f7feb238bb820e9348268773c999e58d1921a3c38d184ab2c01e` |
| `annotations/phobias-general-root54.json` | `98699d0839f7c36546cd62d0b49a220d93a6f48808fb62c269eb12a7e7675213`; 54 records |
| `annotations/phobias-general-root54-report.md` | `1895d5c5989814c3e1f94a40f7d6d821fce163913a3b87906104549ec8d42aca` |
| frozen source revision | `e802ed21db936bdb9809bab2d137903eb0aa425e` |
| vocabulary reviewed | frozen `qm-tags-v1`, 403 tags, semantic SHA256 `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11` |

All seven current source files match `INVENTORY.json` exactly:

| Pack | SHA256 |
| --- | --- |
| `nature_raccoons_anatomy` | `a9d3fd9a441c3d633850ddeb2af2ab4e7572c854258dd3d4d9418e57ca71b682` |
| `nature_raccoons_behavior` | `3c356b98b4f31354bc478f56d52d658fefb01eded3d482dccc2f447584c71f7a` |
| `nature_raccoons_culture` | `509f301af909df852c1bb6cd21eab301eaca5f10804140583eacd89387324829` |
| `nature_raccoons_habitat` | `08692cf5ddb327a335166e9926d191b510acd6675e8f7fa30c4b99e5012efcee` |
| `nature_raccoons_science` | `5928f1cf4e26a114db645304b89e320e8cf50719ae25abe4e2330d6e42398a96` |
| `nature_raccoons_trivia` | `bd2ac70f38d7a04997af72360d465082a2b418076e37a168b47089a0de46edb0` |
| `phobias_general` | `2dfc218165733f3aaea4e85df4288a37083e077140baa302cef1c790522f7c7f` |

## Review method and checks

I reread every raw stem, every option, keyed index and explanation, paired with its annotation:

- Raccoons: 250 records in ten batches of 25.
- General phobias: 54 records in three batches of 18.

I checked each record’s stated score/rationale against option clues, tag relevance, public-context visibility, confidence and flags. Focus checks included Tanuki and raccoon-dog questions (`culture_003`, `culture_004`, `culture_007`, `culture_027`, `habitat_022`, `habitat_036`, `science_030`): `topic:dog` is used only for the actual canid classification, and `topic:raccoon` remains relevant where the visible question asks for the distinction from a raccoon. The MetaMask question (`culture_036`) does not receive a video-game tag; actual video-game tags occur only where the visible stem itself identifies a game.

Fresh commands from `C:/ap/quiz_master`:

```text
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/raccoons.json --partial
Validated 250/4078 annotations; source integrity preserved.

python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/phobias-general-root54.json --partial
Validated 54/4078 annotations; source integrity preserved.
```

The records have complete source coverage, valid integer levels, sorted known tags, safe context subsets, a domain plus a specific topic, and no source-byte drift. Rationale text is record-specific and accounts for visible long-answer, parenthetical, direct-name, and broad-category cues where present.

## Concerns retained for subsequent factual review

No factual certification was performed. The source candidates already identify the material issues that must remain visible to an independent fact checker, including:

- raccoon source claims about physiology, records, local statistics, named historical/cultural claims, unsupported terms, internally mismatched keys/explanations, and questions with more than one plausible response;
- phobia terminology, prevalence/diagnostic assertions, generic or mismatched explanations, questionable clinical framing, and potentially nonstandard labels.

The private flags and low confidences distinguish these concerns from difficulty; no score was increased merely because an item may be faulty. Country, cuisine, person and franchise tags are editorial-only where they describe the keyed subject, while context tags stay with visible safe domains/topics.

The pending 423-tag dictionary amendment was not applied to this review. If root later rebinds either artifact to that additive revision, root must rerun dictionary/hash, subset, identity and source-preservation validation; this acceptance only covers the frozen 403-tag reference above.
