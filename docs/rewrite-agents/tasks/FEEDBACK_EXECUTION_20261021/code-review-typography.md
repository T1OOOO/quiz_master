Conversation: 66667919-1334-40f6-a1de-b5ac1485abe0

**ACCEPT**

### Review Findings

1. **Node Readability (`horizontal: 4, vertical: 6`, `fontSize: 12`)**:
   - In [`_Graph.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/belief_atlas.dart#L584-L602), reducing horizontal button padding to `4` (giving `84px` inner text width on a `92px` minimum node width) and setting `fontSize: 12` with `maxLines: 2` and `TextOverflow.ellipsis` prevents awkward mid-word wrapping on longer Russian names (`Кронос`, `Персефона`) in the 3-column phone layout while keeping 2-line multi-word labels readable.
   - No other production logic or camera behavior was touched; [`_BeliefAtlasPageState._choose`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/belief_atlas.dart#L160-L162) continues to preserve manual camera transforms on node selection.

2. **Geometry & Mobile Graph Tests**:
   - [belief_mobile_graph_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/belief_mobile_graph_test.dart#L92-L139) accurately asserts the 3-column layout (`columns: 3`, `sceneWidth: 320`, `nodeWidth >= 92`, ordered non-overlapping rects) and tests [`BeliefGraphGeometry.captionFits`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/belief_atlas.dart#L61-L66) both for a fitting `Size(8, 16)` midpoint caption (`isTrue`) and for collision refusal against an existing caption (`isFalse`), plus the `320px` scene width at `1.5x` text scaling.
   - [belief_atlas_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/belief_atlas_test.dart#L29-L176) honestly verifies manual transform preservation across node selection, initial overview fit at `361x738`, full-graph `Fit` scaling (`sceneHeight * scale <= 280.01`), and section-switch overview fitting.
