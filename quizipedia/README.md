# Quizipedia source data

Local unranked visual learning, independent of ranked attempt payloads. Version 1
contains 20 country targets on a 177-feature world background, six endocrine
targets, six photographs and eight fixed-J2000 constellation learning patterns.

`python quizipedia/build_catalog.py` builds the Flutter catalogue and manifests
offline. `python -m unittest discover -s quizipedia -p test_catalog.py` checks
determinism, identity joins, preserved polygon rings, known tags, source star
values, image checksums and coordinate space. Visual alignment and UI behavior
require separate review; these data checks cannot establish them.

`content.json` holds original bilingual explanations and editorial line chains.
`hotspots.json` holds original-image pixel coordinates before normalization.
`sources/` preserves the acquired world JSON, 56-star subset and original SVG.
`text-manifest.json` pins the source commits and dataset hashes;
`images-manifest.json` records each individually licensed image and changes.
The application bundles the resulting manifest and exposes attribution links.

`acquire_images.py` is an explicit network acquisition step. Run it only under
the project's admitted asset resource lease. It uses per-file source pages,
bounded downloads and a small maximum raster size; no runtime image service is
required. Existing downloaded artifacts must be removed deliberately before
reacquisition, followed by manifest review; the builder never refreshes sources.

## Asset reuse

Natural Earth vector data are public domain. The bundled 1:110m generalized
de facto boundaries are background geography, not an assertion that all world
countries or small islands have targets. Target identities use the reviewed
195-country project registry; only the explicit 20 IDs are quiz targets.

HYG v4.1 data by David Nash / Astronexus are CC BY-SA 4.0. The 56-star subset,
Quiz Master connecting-line adaptation and corresponding sky catalogue data
are distributed under CC BY-SA 4.0. RA/Dec values have equinox/epoch J2000.
Patterns are editorial figures, not official IAU constellation boundaries.

The endocrine SVG by OpenStax, Tomáš Kebert and umimeto.org (Commons upload,
13 September 2020) is CC BY-SA 4.0. Its rasterized asset and Quiz Master hotspot
adaptation are distributed under CC BY-SA 4.0. The displayed diagram is unchanged.

Each photo's creator, original source, selected license and resize operation are
in `images-manifest.json`; resized photos retain those selected licenses.
These asset licenses do not replace the application's code license.

Future bounded modules: bones and muscles, rivers/mountain ranges, tree leaves,
bird recognition, minerals, and a Solar System ordering/scale exercise. Each
needs its own factual sources and reviewed imagery before becoming a quiz.
