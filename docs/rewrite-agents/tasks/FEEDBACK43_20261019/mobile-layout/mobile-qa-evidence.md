# Mobile QA evidence — feedback-5df1d538

Checked `http://127.0.0.1:8791/#/quizipedia` in the isolated
`feedback43_layout` browser session at **320 × 568**. The lead identified the
served build as `quiz-2026.10.19-feedback-5df1d538` (source `5df1d538`).

## Compact country map recheck — ACCEPT

Route: **Quizipedia → Страны мира → card arrow → Атлас стран**.

- `after-fix-country-fresh-320.png` visibly shows the country label, four
  48 px map controls (+, −, show selected, reset), and the two-line gesture
  hint above the map without overlap with the bottom navigation.
- A browser-automation click on **+** visibly enlarged the map:
  `after-fix-country-zoom-settled-320.png`.
- A browser-automation click on **reset** returned it to the world view:
  `after-fix-country-reset-320.png`.
- A browser-automation map click selected **Mali** and retained the world-scale view:
  `after-fix-country-select-320.png`. This confirms selection does not
  auto-fit the camera.

The prior 320 px failure is retained for comparison in
`country-atlas-320.png` and `country-atlas-320-scrolled.png`: neither showed
the control strip. The recheck screenshots above were opened and visually
inspected after the rebuild.

## Earlier 361 × 738 visual checks

- Library catalog/category/direct compact pack cards/difficulty filtering:
  `library-361.png`, `library-geography-361.png`,
  `library-pack-cards-361.png`, `library-hard-361.png`.
- Study article contents jump and responsive table reading:
  `article-top-361.png`, `article-toc-link-361.png`,
  `article-map-middle-361.png`, `article-map-lower-361.png`.
- Country map zoom and no-auto-fit selection:
  `country-manual-zoom-361.png`, `country-select-361.png`.
- Sky atlas constellation selection and label toggle:
  `sky-atlas-open-361.png`, `sky-select-361.png`,
  `sky-toggle-labels-361.png`.

`library-320.png` was also visually readable at the narrow viewport.
Large-font simulation was not run: the available agent-browser controls expose
viewport and device selection but no text-scale setting. No product file was
edited and no test, build, or deployment was run by this QA session.
