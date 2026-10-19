# Independent code review — BELIEFS_A0IZ (initial stable UI/model snapshot)

**Reviewer:** `brand_review` · **scope:** `belief_atlas.dart`,
`belief_atlas_models.dart`, and `belief_atlas_test.dart` only. The country
integration and canonical asset were intentionally excluded because they were
still changing. This report is not content or release approval.

## Verdicts

**Requirements compliance — request changes.** The implementation has a
separate model/parser, searchable list, manual zoom controls, a selected-node
detail and a local quiz. Selection itself does not overwrite the transformation
controller. However, the actual relationship graph does not meet the packet's
direction, localization, source-version and full-graph requirements.

**Code quality — request changes.** The split between model and page is useful,
but parser acceptance and graph geometry leave valid-looking input able to
crash the quiz or hide most nodes. The three current tests do not cover these
boundaries.

## Required findings

1. **Graph direction, locale and source version are not rendered.**
   [belief_atlas.dart](../../../../next/apps/quiz_app/lib/belief_atlas.dart#L403)
   draws an undirected line and `e.en` only. It omits arrowheads, Russian
   `label_ru`, and `scope_ru/en`; the neighbour buttons in the detail card also
   omit the edge relation. Thus a parent-to-child link has no visible direction
   or versioned qualification, and Russian users receive English edge labels.
   Render an arrow from `from_id` to `to_id` and a localized label plus scope,
   or expose the same semantic relation and scope in the localized detail list.

2. **Full graph nodes below row three are clipped and cannot be panned to.**
   The graph scene and `CustomPaint` are both fixed at 280 pixels high
   ([belief_atlas.dart](../../../../next/apps/quiz_app/lib/belief_atlas.dart#L338)),
   but node positions grow by 110 pixels per row
   ([belief_atlas.dart](../../../../next/apps/quiz_app/lib/belief_atlas.dart#L370)).
   With the required 20–24 Greek figures, nodes from index six onward are
   outside the scene; `Fit` currently has the same identity transform as
   `Reset`. Give the InteractiveViewer a scene sized from the number of rows,
   retain the 280-pixel viewport, calculate a real fit transform, and add a
   20+-node full-graph mobile regression.

3. **Empty source reference arrays pass validation and then crash feedback.**
   `refs` uses only `every` in
   [belief_atlas_models.dart](../../../../next/apps/quiz_app/lib/belief_atlas_models.dart#L217),
   so an empty `question.source_ids` is accepted. Quiz feedback then dereferences
   `q.sourceIds.first` in `belief_atlas.dart:642`. Require a nonempty source ID
   list for every node fact, edge and question reference, and test the rejected
   payload.

4. **Empty content has no empty state.** An accepted empty `nodes` array makes
   `_load` access `a.nodes.first` at `belief_atlas.dart:49`; switching into an
   otherwise empty section accesses `_nodes.first` at line 152. The packet
   requires an empty state. Render an explicit empty page/section or reject an
   unusable section before accessing `first`.

5. **Malformed HTTPS URLs pass the parser.**
   [belief_atlas_models.dart](../../../../next/apps/quiz_app/lib/belief_atlas_models.dart#L37)
   checks only the scheme, so `https:///path` has `https` but no host. Validate
   a nonempty `Uri.host`, as the source contract requires, and add a negative
   test.

6. **Selectable religion practice can have fewer than ten questions.**
   `round` returns `min(10, list.length)` in `belief_atlas_models.dart:249`;
   the packet currently asks for ten-question frozen rounds while its initial
   content target permits only six religion questions. Resolve this explicitly:
   supply ten questions for each selectable section, or disable/label a
   deliberately shorter section mode instead of presenting it as the specified
   ten-question practice.

## Evidence and gates

- I reviewed the three authored tests but did not rerun them; the lead owns the
  focused test slot and broader checks.
- No canonical belief asset is present, so source integrity, exact content
  coverage and final registry/menu integration remain unreviewed.

## Final re-review — integrated stable snapshot

**Requirements compliance — approve.** The six required findings above are
resolved in the reviewed snapshot:

1. Directed edge tips now terminate outside fixed 140×56 node rectangles;
   the graph paints localized labels, and both graph semantics and the detail
   card expose direction and source/version scope.
2. The graph scene height grows with its rows, Fit accounts for scene width and
   height, and the full 21-node mobile test covers the reachable scene.
3. Nonempty IDs are required at the model boundary, including facts, edges and
   quiz questions; hostless HTTPS URLs are rejected.
4. An empty requested section presents a button to its populated counterpart.
5. `domains_*` and `symbols_*` now validate as the specified string lists and
   are joined only for display.
6. The asset supplies ten Greek questions and nine religion questions. The UI
   explicitly states the available count for the intentionally shorter religion
   section, avoiding a false ten-question claim.

Country affiliation integration correctly distinguishes Pew population
affiliation estimates from official state religion, carries the 2020 data year
and 2025 publication year, skips rounded ties for quiz associations, preserves
the country-map camera on layer/detail changes, and includes the full
source-specific seven-share detail.

**Code quality — approve.** Model, graph and country-affiliation boundaries
are explicit; the fixed node geometry keeps labels bounded at large text while
the interactive scene remains pan/zoomable. The canonical belief asset SHA-256
matches the independently accepted revision:
`94859807508313190BC035A2B5C3E01F60A7C80D3435FCA89ECB586CD8216969`.
Static structural inspection found 30 nodes (21 Greek, 9 religions), 32 edges,
20 questions, nonempty source references and in-section four-option questions.

### Final evidence reviewed

- `focused-tests.log`: 17 focused navigation, graph, parser, asset and country
  UI checks passed.
- Existing `country-tests.log` records all four country parser/data checks
  passed; `country-ui-tests.log` records its camera/detail test passed.
- `belief-fact-review.md` final recheck accepts the same canonical asset SHA.

The displayed `analyze.log` still contains the earlier one-warning run, so it
is not fresh clean-analysis evidence. The lead reported that warning fixed and
owns the final analyzer/build run. This review approves the implemented scope,
not publication or release.
