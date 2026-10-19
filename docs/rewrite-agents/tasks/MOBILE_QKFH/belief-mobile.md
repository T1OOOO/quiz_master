# Belief graph mobile repair

At viewport widths below 600 logical pixels, the relationship graph uses a
single centered column. Nodes are at most 240 px wide and use a 164 px vertical
step, leaving space for an edge caption between them in the 280 px graph view.
The scene width equals the available viewport width, so it does not require a
horizontal pan merely to read the initial two-node graph.

`BeliefGraphGeometry` is shared by node placement, edge caption placement, and
the Fit control. Desktop retains its three-column layout. Selecting a node still
leaves the manual transform unchanged.

Focused verification: `flutter test test/belief_mobile_graph_test.dart
test/belief_atlas_test.dart` passed 6 tests, including 320 px at 1.5× text and
non-overlapping two-node/caption geometry.
