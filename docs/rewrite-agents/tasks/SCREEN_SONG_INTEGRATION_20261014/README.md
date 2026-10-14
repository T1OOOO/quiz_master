# Screen Song inert integration proposal

This proposal converts the genuinely accepted v2 four-card pilot into reviewable raw, private canonical draft, manifest, Reader draft and bundle-projection data. It writes only this task’s owned proposal/scratch folders. It contains no live apply mode, quizctl invocation, build, browser, Git, Beads, SSH or release operation. Root approved pack `screen-song-20261014`, title «Песни на экране: за кадром», category «Кино».

## Input and review pins

- Candidate: `dd843139167a1a32316925983a35d53b4b77bf53463e69096f7754f221e74bc4`.
- Editorial: `b930b1e6d091b28ff1740944612d3a3e62517a64a9dc609612c20db5549d5b3b`.
- Full actual `SCREEN_SONG_PILOT_20261014/independent-review-v2.json`: `2ebed6f16385ed6bc650dc59fabd73d356856cce10b0d5be63e50b79af50128c`.
- Taxonomy file: `98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c`.

The loader verifies all hashes before any output. It requires the real review/accept callback for task `task-4e2da7de87f048fbb77c6810a9acfe89`, distinct reviewer/assignee, successful actual CLI exit and the accepted candidate/editorial hashes in that callback’s review note. A status-only accepted stub fails. Prior v1/current accepted source files are untouched. The existing factual review qualified its eight source responses as partial HTTP200 reads; this integration work did not fetch or recertify sources.

## Exact conversion

The four original stems, ordered a/b/c/d option texts, zero-based keys0/1/2/3, explanations, difficulties7/6/4/6 and source URL/title/support/date values remain identical. Each source card maps to the same `screen-song-pilot-00N` ID and option IDs `screen-song-pilot-00N-opt-1..4`. Estimated difficulty remains estimated; its bands follow the current Go thresholds.

All five accepted tags are actually registered and player-safe: `domain:arts`, `domain:screen`, `topic:film-music`, `skill:comparison`, `skill:direct-recall`. Their per-question arrays are retained exactly; no tags are added or dropped. Raw sources include the existing taxonomy reference. Draft source objects contain only `uri: /app/quizzes/Cinema/screen_song_20261014.json`; explanations remain private in raw/manifest, grading and editorial tags stay outside public questions.

Reader conversion moves the initial `###` heading to `title_ru`, retains subsequent heading words as plain text, preserves all prose words and real paragraph breaks, and moves the exact trailing source list to two existing-format source controls. No literal backslash-n is accepted or silently repaired. Every article remains `status: draft`, has one projected question revision reference, empty target_refs, and two exact source records. The first title is not repeated inside the body. Subsequent heading words remain readable without raw Markdown markers.

`bundle-projection.json` is deliberately a projection. Its version/time fields describe the proposed deterministic content build, not an observed publication. Python follows the existing Go import/type/canonical/public projection structure, and the hash helper reproduced all eight actual Actor question hashes and its draft hash. Root’s actual official quizctl import, validation, normalization, build and diff must establish final authoritative files and refs. This worker ran none of those commands.

## Reproduce the inert work

Run from `C:/ap/quiz_master`:

```powershell
python -m unittest discover -s docs/rewrite-agents/tasks/SCREEN_SONG_INTEGRATION_20261014 -p test_proposal.py -v
python docs/rewrite-agents/tasks/SCREEN_SONG_INTEGRATION_20261014/proposal.py
python docs/rewrite-agents/tasks/SCREEN_SONG_INTEGRATION_20261014/proposal.py --output-root C:/ap/quiz_master/.run/screen_song_integration_worker_20261014/proposal-v3
python .run/screen_song_integration_worker_20261014/inspect_duplicates.py
```

Default is read-only preview. Output must be absent and resolve within this task’s docs folder or `.run/screen_song_integration_worker_20261014`; live paths and Root’s separate scratch are rejected. The script checks that prospective new live raw/content/Reader/review outputs do not exist before writing anything. Existing outputs are never overwritten. Actual tests exercised collision rejection against an existing live Actor file, input-hash rejection before side effects, and no-clobber of the existing owned proposal.

Two actual proposal runs in owned `proposal-v1` and `proposal-v2` returned0; all six JSON artifacts/evidence files were byte-identical. Eight tests first failed against the inert skeleton and then passed. The red/green logs and local guard checks remain in owned scratch.

## Duplicate inspection and preservation

`duplicate-inspection.json` records a normalized-stem and named-entity sweep across all134 raw packs/4060 questions, plus manual inspection of84 nearby stems from seven Film/Actor/Music Craft, musical, Music People/Encore and Cinema Encore packs. There are no matching new stems and no matching work/person entities for cards001/002/004. Card003 shares Barantini with the existing Actor rehearsal question, but asks about a different production and filming method. Card001’s article mentions ADR, adjacent to existing Film Craft; its keyed fact is the spoken-sung transition. Card004 overlaps the general authorship theme of older musical cards while asking a different work and specific collaboration. These are disclosed subject adjacencies. This is a bounded inspection, not a complete semantic audit of every question.

The script snapshots all134 raw file hashes, all134 catalog objects, all260 accepted Reader objects and the fixed asset/taxonomy hashes; the before/after snapshots matched. Current totals remain134/4060/260. Planned totals after a separate reviewed Root append are135/4064/264. Every existing row/object/file must survive unchanged. No real feedback or runtime state was read or changed by this proposal.

## Proposed later Root ownership and commands

After genuine independent proposal review and any ambiguity findings, Root needs exclusive ownership of these new live paths:

- `quizzes/Cinema/screen_song_20261014.json`.
- `next/content/screen-song-20261014/{draft,bundle,manifest}.json`.
- `study/question_articles/drafts/screen-song-20261014.json`.
- Later, `study/question_articles/reviews/screen-song-20261014-review.json`, using only an actual independent integration callback and final article hashes.

Root separately owns append-only changes to `next/apps/quiz_app/assets/catalog.json`, `next/apps/quiz_app/assets/study/question-articles.json` and `next/apps/quiz_app/test/question_articles_test.dart`; preserving the134/260 old objects is a gate. These paths are not written by this script.

The later authoritative flow is:

1. Check that all new live paths remain absent and all accepted input/proposal hashes still match. Copy only the proposed raw file under Root ownership.
2. Run official `go run -p=1 ./next/server/cmd/quizctl import --in quizzes/Cinema/screen_song_20261014.json --out .run/screen_song_integration_20261014/imported --taxonomy metadata/tags.v1.json`.
3. Normalize only imported question source URI from the exact relative raw path to the exact `/app/` URI, then explicitly recompute question and draft revisions using the existing canonical mechanism. Compare every normalized draft/manifest value with this projection; stop on any mismatch rather than adopting projected hashes blindly.
4. Run actual quizctl validate on that normalized draft, then actual quizctl build with version `2026.10.14.screen-song-v1`, published-at `2026-10-14T00:00:00Z` and taxonomy. Validate the actual bundle. Rebuild to a separate Root-owned file and run actual quizctl diff.
5. Recheck exact keys, source normalization, private/public separation and registered tags. Bind four Reader drafts to those actual final revisions. Obtain genuine independent integration acceptance before accepted review metadata/export.
6. Append only one catalog row and four accepted articles, verify135/4064/264 with all old objects unchanged, update the existing fixture with four actual refs, and run the appropriate actual compiler/Flutter gates. Compilation, runtime cache/rehearsal, browser checks and publication remain separate work.

No authoritative import/build/diff, live integration, new acceptance, client build, browser QA or release has occurred in this worker’s scope.
