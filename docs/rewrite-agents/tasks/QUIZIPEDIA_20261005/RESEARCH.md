# Quizipedia v1 research memo

**Prepared:** 2026-10-05
**Base inspected:** `e802ed21db936bdb9809bab2d137903eb0aa425e`
**Scope:** product/technical advice only; no assets were downloaded and no production files were changed.

## Recommendation

Ship one local, unranked **Quizipedia practice** surface using ordinary Flutter
widgets and `InteractiveViewer` before adopting Flame. It should contain four
small exercises: map (country → location and highlighted location → country),
organ/gland hotspots, landmark photo identification, and a fixed-epoch sky
atlas. The existing app has `/study` routes and Study's explicit unranked copy;
the new surface should use the same local-only status, not an attempt API.

The starting data slice is deliberately modest: 20 country targets chosen from
the frozen 195-country registry, 8 endocrine targets, 12 individually licensed
landmark photographs, and 8 familiar IAU constellations/asterisms. It proves
the interaction model, asset provenance UI, RU/EN strings, retry loop and
mobile target policy before expanding coverage. Each prompt has a stable
`topic`, optional `country_iso2`, editorial difficulty, target ID and source
ID. A prompt is never sent to ranked or live/competitive attempt endpoints.

### Why this is the right first cut

Facts: `next/apps/quiz_app/pubspec.yaml` has no Flame dependency and requires
Dart `^3.13.1`; the Flutter client already exposes `/study` and Study practice
is labelled unranked. Flame 1.38.2 is the current stable package listed by
pub.dev (Dart >=3.11) and Flame documents cross-platform pointer/touch input,
but adding it creates an additional package, rendering/input architecture and
test surface. Its documented component hit default is bounds-based unless a
component supplies its own `containsLocalPoint`; that is insufficient for
country polygons on its own.

Proposal: use `CustomPainter` plus Flutter `InteractiveViewer`/pointer
transforms for v1. Maintain the target geometry in local data and compute a
true fill/path containment result after inverse-transforming the tap point.
The same response can be exposed through ordinary, labelled alternative buttons
for screen readers, keyboard and tiny geography. This is the lowest-cost way to
meet Web and Android requirements without an engine migration.

### Two alternatives

1. **Flame canvas module.** Pin stable `flame: ^1.38.2` only after a small
spike verifies the exact Flutter/Dart lockfile resolution. Flame provides
Tap/Drag/Scale event APIs on Flutter-supported platforms. It is useful if the
roadmap requires sprites, a game loop or many animated scenes; custom polygon
hit testing, semantics and button alternatives are still required. No monetary
license fee is stated by the package listing; dependency/update/testing cost is
the practical cost.
2. **Pre-rendered SVG/Rive-like screens.** Appropriate only for the organ
diagram and a fixed sky card, with explicit hotspot overlays in viewBox
coordinates. It is poor as the sole map solution because it does not solve
multi-polygon country containment, zoom or tiny-country selection.

## Data and provenance decision

| Surface | Recommended source and exact acquisition URL | Reuse/attribution decision |
| --- | --- | --- |
| Country identity and flags | Existing `docs/rewrite-agents/preparation-country-registry/countries.json` and its media ledger; bind strictly by its ISO-2 field. | Reuse the existing 195-country scope. The prior audit says linked flag artwork has no blanket reuse right; retain existing provenance and do not infer public domain. |
| Country geometry | Natural Earth 1:10m Admin 0 Countries v5.1.1: [download page](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-countries/) and direct ZIP `https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip`. | Natural Earth says its raster/vector data are public domain. Attribute “Natural Earth, v5.1.1” in credits anyway; it depicts de facto boundaries. Its 258 features and ISO fields are an input, not the product's 195-country definition. Create an explicit ISO join/exception table; never substitute a `-99`/missing source code. |
| Anatomy image | [Endocrine English.svg file page](https://commons.wikimedia.org/wiki/File:Endocrine_English.svg), original SVG linked there. | CC BY-SA 4.0; credit OpenStax, Tomáš Kebert and umimeto.org, link the file and CC BY-SA 4.0, mark modifications. Legal review must decide whether adapting the SVG imposes share-alike on the adapted asset/distribution. Do not use its labels in challenge mode. |
| Landmark photos | Curate a short, per-file manifest from [Wikimedia Commons](https://commons.wikimedia.org/) File pages. Store source page, original URL, creator, license/version, attribution text, modification status and SHA-256 after approved acquisition. | No Commons-wide license exists. Include only a selected file whose individual page permits the intended reuse, and show a per-photo credit link in-app. Do not replace recognition photos with generated factual imagery. |
| Sky stars | [HYG Database](https://github.com/astronexus/HYG-Database), [license](https://raw.githubusercontent.com/astronexus/HYG-Database/main/LICENSE). | CC BY-SA 4.0; credit HYG Database, link CC BY-SA 4.0 and publish required adaptation/share-alike material if distributing a derivative data/atlas asset. Repository was archived 2025-02-14, so pin a reviewed commit and store the exact source checksum before import. |
| Constellation authority/layout | [IAU Constellations](https://www.iau.org/IAU/IAU/Astronomy-FAQs/Constellations.aspx?hkey=bb9dc841-0618-41b5-ac70-149741062141), including its per-constellation J2000 boundary TXT links and CC BY 4.0 charts. | IAU recognises 88 constellations; its standard defines areas/boundaries, not a canonical stick-figure. Use an editorially authored, versioned line-segment table for the small v1 set and label it “learning line pattern”, rather than implying an official figure. IAU charts are CC BY 4.0 if used directly. |

All acquisition needs a later approved asset/import task. `sources.json` is the
machine-readable source manifest; it records URLs and constraints, not a claim
that an asset has been imported or cleared for production.

## Interaction specification

### Map and flags

* **Explore:** labels, flag and country detail may appear after a tap. **Challenge:**
  remove all map labels/flag/name on the canvas, state one prompt, and show only
  a neutral target highlight after the answer. Feedback has correct/incorrect,
  a short explanation, source/credit link, Retry and Next.
* Store source geometry as every polygon/ring, preserve holes, multi-polygons
  and antimeridian handling; project once into a fixed world coordinate space.
  For every pointer event, invert pan/zoom then run fill containment against
  the retained path/rings. Bounding boxes may narrow candidates but cannot
  decide an answer.
* At normal zoom, any target whose visible geometry is below a 44x44 logical-px
  tap affordance gets an explicit nearby callout/marker that is semantically the
  same target, plus four accessible text options. The marker must not overlap a
  rival target without opening a disambiguation sheet. Tiny states need not
  become artificially enlarged country borders.
* Country target resolution is `registry.iso2 -> reviewed geometry mapping ->
  geometry_id`; reject prompt generation if this is non-unique or absent. Do
  not assume Natural Earth's 258 country features equal the product's 195.

### Organs/glands

* Ship only named visible targets with independently fact-checked location,
  function and overlay coordinates. Keep image `viewBox` and hotspots in the
  same normalized coordinate system; map pointer coordinates through the fitted
  image rectangle before testing a hotspot.
* Challenge hides the diagram's answer-revealing labels. Each target has a
  minimum 44x44 logical-px accessible target; when two targets cannot meet that
  spacing, use a numbered selector/list alternative instead of silently moving
  factual coordinates. Treat terminology and function questions as pending
  independent fact check.

### Landmark photographs

* Start with one landmark per card and a four-name alternative response, not a
  free tap over a collage. Photo credits stay reachable before and after an
  answer; challenge text does not include the landmark/country answer. Avoid
  ambiguous viewpoints, replicas and sites whose identity depends on a label.

### Fixed sky atlas

* State the scope on every game: “fixed J2000 learning atlas; not your current
  sky.” Map stored right ascension/declination through a documented projection
  (equirectangular for v1) before scale/pan. It does not model observer
  location, date, horizon, atmospheric visibility or real-time motion.
* Separate the IAU constellation area from an educational line pattern. A
  challenge asks for an explicitly named selected pattern/area and never makes
  line variant alone the expected ground truth. Make all pattern segments an
  editorial table with source version, not generated astronomy art.

## Acceptance examples for the implementation packet

1. Automated geometry fixtures cover a multipart country, a hole/ring, an
   antimeridian case and a tap after pan+zoom; all resolve to the bound ISO-2
   or no answer, never a bounding-box-only result.
2. At 390 CSS px wide, every sampled target has a 44x44 logical-px route
   (shape, unambiguous marker or text control); zoom and text alternatives are
   keyboard/screen-reader reachable.
3. Map, organ, landmark and sky challenges contain no visible answer in labels,
   alt text, semantics or accessibility identifiers before submission. Explore
   intentionally may reveal it.
4. Scaling an anatomy image at three aspect ratios still resolves each hotspot
   to the same normalized target. Target ID/fact/source binding is validated.
5. The sky fixture verifies J2000 RA/Dec projection, selected segment IDs and
   an acknowledged ambiguous/variant pattern. It never claims a live sky.
6. A route-level Web/Android check reaches the Quizipedia entry from both RU and
   EN, completes retry/restart, and confirms its local unranked feedback makes
   no ranked attempt request.
7. Every shipped geometry/photo/diagram/star asset has a manifest entry with
   source URL, acquisition date, license, attribution text, checksum and
   public/private packaging decision. The check fails on a missing entry.

## Open decisions and risks

* **Fact check required:** anatomy target coordinates/functions, landmark facts
  and the v1 constellation line list are not certified by this advisory memo.
* **Political presentation:** Natural Earth's de facto boundary policy must be
  presented as map-data provenance, while country membership remains the
  project's frozen UN-based 195 registry. A reviewer must approve all mapping
  exceptions and disputed-area display before shipping.
* **Licensing:** HYG and the proposed anatomy diagram are CC BY-SA 4.0. Decide
  distribution/compliance treatment before using derivatives. Landmark images
  remain per-file approvals.
* **Accessibility/performance:** test real 390px Web and Android touch hardware
  after an implementation owner obtains a resource grant; this memo did not run
  Flutter, browser, provider or build work.
