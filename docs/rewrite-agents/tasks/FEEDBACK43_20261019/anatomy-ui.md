# FEEDBACK43 — anatomy UI

## Scope

Extended the organ-atlas model and reader without changing the reviewed atlas
JSON or its asset manifest.

## Result

- `name_la`, `bone_count`, and `diagram_group` are optional and validated when
  present. `bone_count` must be a positive integer; diagram groups are limited
  to `skeleton`, `brain`, and `organs`.
- Added `bone_group` and `brain_region` kinds. Russian filters label them
  `Кости` and `Отдел мозга`.
- The Russian reader searches a supplied Latin name, but continues to use the
  Russian primary title. The Latin name is in a collapsed detail section.
- A bone group shows `Костей в группе: N`. It is one group card, rather than a
  claim that the atlas supplies 206 separate cards.
- Map targets remain limited to the existing illustrated-anchor list. A new
  group with no real anchor receives the existing sourced-card fallback rather
  than an invented point.

## Verification

- RED: `flutter test test/feedback43_anatomy_test.dart` failed because
  `OrganStructure` had no `nameLa`, `boneCount`, or `diagramGroup` fields.
- GREEN: `flutter test test/feedback43_anatomy_test.dart` — 2 passed.
- Regression: `flutter test test/organ_atlas_test.dart` — 4 passed.
- Static analysis: `flutter analyze lib/organ_atlas_models.dart
  lib/organ_atlas.dart test/feedback43_anatomy_test.dart` — no issues.

No browser, full build, asset-manifest edit, JSON edit, commit, or release was
performed in this bounded UI task.
