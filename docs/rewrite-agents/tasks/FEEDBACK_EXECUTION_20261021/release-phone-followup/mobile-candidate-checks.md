# Frozen 7c1552a2 mobile candidate checks

Actual served package: `package-7c1552a2-final`, build `quiz-2026.10.21-feedback-7c1552a2`, input SHA `0e0521f240d29334cb4041b9b9a0db89767ffcc535f2614bf60e29ed9578a481`.

Owned headless Chromium, Android Pixel 5 user agent, mobile viewport 393×851 and 361×738, DPR 2.75, five touch points/coarse pointer. Real raw two-contact pinch and one-contact pan dispatched. Physical Android was not tested.

- Cold home: 17 resources, no domain JSON, originals, aggregate photos or Bravura. Only home card previews and application runtime/fonts.
- Country Layers opens the wrapping list directly; Flags + Capitals selected simultaneously. Expanded map manually pinched/panned, collapsed, then resized to361; visible geographic focus preserved. Names remain visible; capitals represented as dots.
- Country practice: six choices for Croatian capital; wrong Avarua selected, explicit correct Zagreb, no automatic advancement. Expanded all-choice panel provides the actual capital/country association for all six. Manual Next remains available.
- Organs: six choices, sublingual question, wrong submandibular choice. Correct and selected-wrong icons/text plus two result summaries; manual Next. After-check panel expands six organ descriptions. No such panel before answering.
- Constellation picker: actual recognizable miniatures (Andromeda/Ursa Major/Libra/Aquarius), not collapsed dots. Orion main scheme readable at361.
- History: continuous horizontal date axis; long early dates aligned, events reachable by horizontal swipe. Existing period buttons wrap at361.
- Photo catalog: initially exactly four thumbnail requests, no original; selecting Colosseum fetches its original only. Important remaining defect: catalog decodes at96px despite512px files, visibly blurry at high DPR. This is explicitly pending a separate code correction, not treated as resolved by this package.

Screenshots retained privately; SHA-256:

```json
{
  "country-layers": "5114faeceb41cd8f348e5bde2e0a0ee6afd4dae7958ffa8ff8d9250596817bde",
  "country-combined": "e59b5747b66b95290a0efdeed6af18d3848ab57cb89c953e2f14894f24d29739",
  "country-expanded-stable": "7cee5c6342bb5080fa05f5c44768fcd7d34a912c1f0e381ca24ebf9389e9b38c",
  "country-collapsed": "5a3e00ad16937dc833fc4652c498a529f0930363225892390f3af377b88d7d56",
  "country-resized": "d45dbcf794ea9291c4f3613c77c8155f248178c27b76a294a357cb0b05529d1a",
  "constellation-chooser": "382dcadd2b705b4cafe5422ea54a22d936ee1a788811db31211a7d2e9dcb019b",
  "organ-question": "fc4944b44eaf56080a2b8f2a87202d81aea36e0a10fd6cbb24974e6ff4001112",
  "organ-feedback-scrolled": "cc573549575cadf27238b6ccd9a626866801d1baeb5d78381ce10d67fd3dde89",
  "organ-all-choices-stable": "81ed0dafba725454c2ac2d8c0c76c81e9845034eddcc852b7461d579f067ab9e",
  "country-practice-stable": "489bf20198d575fa9d99c5854a32b5cbdf8a662fba73c135cf7dcdbdceda4afe",
  "country-checked-scrolled": "c6a6f1330c25cb2aba0e811872e7b2e14b1c703caed560b24605b76aa21fa65c",
  "country-other-answers": "3095299a8d5878ed5414e1cbe78135bdb21989743806596e3d32f9cf84467cd9",
  "timeline": "36969b97d23f82001a9cb2c4baa4d0047b00b0d9a7f31b34b29c1176c56cacd5",
  "photo-catalog": "a2cb741c25209a441cd8f2bce5841503a8b8e8a78980d8dbe8c2ebb70035709d",
  "photo-selected": "98f0670c46efe2837668372ecc5d676e7dda79de3bd7a1e30392382279c2d295"
}
```
