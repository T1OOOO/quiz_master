# Phone map audit

Reviewed the country and constellation atlas paths at a 360 px viewport with
large text. The country map already preserves the manually chosen camera when a
country is selected; this work does not add automatic zooming.

Changes made:

- Country map minimum height is 300 logical pixels, keeping a useful map area
  after the search and filters have scrolled past.
- Constellation labels are clipped to the canvas, shortened with an ellipsis on
  narrow screens, and placed in the first free nearby position. Bright stars
  take label priority; the accessible star list remains available for labels
  that cannot fit without overlap.
- Constellation label and line controls have 48 px minimum touch height.
- Russian map semantics describe pinch, pan, and double-tap gestures; English
  semantics stay unchanged.

Focused widget evidence: `flutter test test/mobile_maps_test.dart` passed two
tests for phone control sizing and country map height. Browser interaction and
full-suite verification remain with the root owner.
