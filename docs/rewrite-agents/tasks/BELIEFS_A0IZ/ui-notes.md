# BELIEFS_A0IZ UI notes

The atlas opens with a small selected-node neighborhood so labels stay readable
on a 390 px display. The full graph is optional and grows its scene by rows;
Fit scales that scene to the viewport while Reset returns to the manual baseline.
Directed edges include arrowheads, localized labels and visible/semantic scope text.

Selecting either a graph node, list entry, or linked neighbor updates the detail
card without changing the `TransformationController`. Users alone control pan,
pinch, zoom, fit and reset. The local quiz is intentionally unranked and uses
the asset's available question count when a section has fewer than ten items.
