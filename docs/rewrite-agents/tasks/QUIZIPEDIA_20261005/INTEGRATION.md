# Root integration checkpoint

2026-10-05. Acquired the pinned Natural Earth 110m JSON, streamed the pinned HYG
v4.1 file to a 56-star subset, and acquired six individually reviewed photographs
and the unlabeled endocrine SVG/Commons PNG. Sources and exact checksums are
preserved in `quizipedia/`; generated catalogue/manifests and seven small rasters
are bundled in `next/apps/quiz_app/assets/quizipedia/`.

First data checks ran under admitted asset lease
`lease-5f08cd75007543f483224d162c5a1f5d`, renewed by an owned guard. Five checks
passed: deterministic build, all 177 features/rings, 20 country identities/flags,
40 target metadata references, retained star values/line endpoints and actual
raster hashes/image-space coordinates. That lease and guard were released after
quiescence. The targeted independent factual review accepted all 14 hotspots,
all six photo depictions and their provenance; see `review-facts.md`.

The explicit 403-tag metadata amendment required regenerating the catalogue
reference and both manifests. Regeneration and five fresh data checks passed;
nine metadata-pipeline tests also passed under the admitted light5 lease.
Independent static code review requested production
map zoom/pan interaction coverage and correct-score coverage; those tests now
exercise real transformed taps, holes/ocean selection and score=1. Root added import, route, drawer
entry, pubspec asset directory, localized page title and explicit home callback.

Flutter checks were executed under renewable admitted serial7 lease
`lease-ecb2a28cac0e4f2d935210cee611bc5c`, then released after the commands exited.
All ten core Quizipedia tests passed in the full client run. The full run had
87 passes and three failures: stale inventory/category assertions and two
pending difficulty-UI layout regressions. Those were corrected and their
targeted checks passed, including long scaled mobile answers. The added actual
route/drawer round-trip test still needs fake-async asset-IO repair and a fresh
run. Analyzer initially identified two difficulty-code errors, missing l10n
codegen and five Quizipedia lint/API notices; source repairs and codegen are
performed, but clean analyzer acceptance is still pending.

`review-final.md` independently accepts current static implementation and asset
hashes, conditional on runtime gates. A previous separate-provider read-only
review returned APPROVE on an older snapshot; its renewal guard expired and
the owning session reconciled it after confirmed process exit. It cannot
establish current runtime or changed-scope acceptance. A new bounded
changed-scope review returned APPROVE under admitted renewable provider11
lease; actual model/cost and review boundaries are in `review-provider.md`.

Five fresh catalogue checks and nine metadata tests passed again under admitted
256 MiB light-format14 lease. That reservation was used for bounded formatting,
data checks and preparing an isolated baseline client, never for Flutter
runtime tests or a heavy build. Source hashes are also checked against the Git
index. `.gitattributes` preserves acquired and authored data bytes, including
legitimate CRLF, so cross-platform checkout does not invalidate the manifest.

The existing CI workflow gains manual dispatch and builds its Web artifact
with the existing `QM_API_BASE_URL` define pointed at the production origin.
This is a progress commit for remote validation; all runtime gates remain
required before production cutover.

An isolated stable-baseline client release is being prepared so Quizipedia
does not publish the unfinished difficulty API/UI migration. No release,
clean analyzer, web build or production success is claimed by this checkpoint.

Scope: four local unranked learning games, 20/6/6/8 targets; no current-sky
calculation and no assertion that the 110m map supplies all 195 country targets.
Possible later modules: bones/muscles, rivers/mountains, trees, birds, minerals
and Solar System order/scale, each with separate source/visual review.
# Remote CI validation checkpoint

Progress commit `b21571b7a7f349576d015f9871daba89b849de98` was pushed and
dispatched as GitHub Actions run `37306903180`. Android debug compilation and
artifact upload succeeded. This run did not accept Web or the full Go suite:
the source-collection integration assertion still expected 118 packs/3878
questions instead of the existing 126/3958 inventory, and Dart formatting
required one blank line before the new local import in `main.dart`.

The next validation revision changes only those inventory assertions and the
import spacing. It does not change backend behavior or include the pending
difficulty/tag integration. Full CI and production verification remain pending.

Second CI run `37307803096` passed Dart formatting, Flutter analysis, Android
compilation, all Go unit/source integration tests and Go vet. Flutter finished
82 tests with one failure in the second real-route opening (fake-async asset
I/O). The isolated Compose API then exited because its old image/config omitted
required content paths and the runtime content/schema files.

The navigation test now creates both asset-loading routes in `runAsync`, pumps
the second Go Router transition twice, awaits the actual catalogue Future, and
asserts the final UI/no exceptions. The old test reproduced its timeout locally;
the first single-pump repair reproduced a missing-builder exception; the second
repair passed the actual targeted test. A full isolated Flutter test rerun is
pending. The Compose repair explicitly supplies the existing bundle/manifest,
copies their runtime data and validation schemas, and uses `/app` as working
directory. Production API/data remain the previously verified release bytes.

Local isolated game client: `dart format --output=none --set-exit-if-changed .`
passed (20 files, zero changes); `flutter test` passed all 83 tests, including
the actual route/drawer roundtrip, after the second-pump correction. Executed
under granted 2 GiB lease `lease-bdf4f6f7dd764cdf8f8e7fcdd542d9d1`, renewed by
owned guard PID25700, then released after every test process returned. Remote
Compose integration and release Web compilation still require the next CI run.
