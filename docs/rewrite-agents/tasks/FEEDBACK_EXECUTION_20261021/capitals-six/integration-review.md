# Independent canonical packet review

Official Antigravity CLI, conversation e2a9eecf-0f00-4423-b2d8-234c80e0a137. Inline actual data, generator, replacement helper, root cross-artifact validator.

**Verdict: ACCEPT**

### Review Findings

1. **Data & Content Integrity (`ACTUAL20DATA` & `build_packet.ps1`)**
   - All 20 questions in `prep-capitals-1` (`capitals-oct3-001` through `capitals-oct3-020`) retain their original 4 options in indices `0..3` (80 retained options total) and append the exact 2 reviewed city distractors at indices `4..5` (40 additions total), yielding 6 unique options per question (`option_ids` `-opt-1` through `-opt-6`).
   - All 20 `correct_option_id` values remain unchanged (`old_correct_id_unchanged: true`), preserving existing attempt references, historical grading integrity, and `revision.number = 2` with updated revision hashes.
   - Only the 3 authorized questions (`capitals-oct3-009`, `capitals-oct3-015`, `capitals-oct3-018`) modify stems and explanations (clarifying Burundi's political capital Gitega, Bolivia's central executive/legislative institutions in La Paz vs. constitutional capital Sucre, and Sri Lanka's parliament seat in Sri Jayawardenepura Kotte vs. commercial center Colombo). All other 17 stems remain untouched.

2. **Source Provenance & Hash Bindings**
   - `build_packet.ps1` enforces pre-execution SHA-256 verification against the accepted v3 artifacts (`accepted-draft-v3.json`: `ec6aa50d...43e58f`, `final-review-v3.json`: `aa094cba...9ad619`, `source-evidence.md`: `57def723...f5fb7`) and checks the exact v3 review verdict and `artifact_binding.draft_sha256`.
   - `provenance.json` transparently records both the actual pre-integration canonical source raw hash (`2c08402c53021e198fce9fde9ae954c327cfd5c812e824cd3a2ba090f080b41b`) and the stale private-draft declared hash (`3c914f5d...89c318`), with `.gitattributes` CRLF/LF normalization keeping raw byte hashes reproducible.
   - Difficulty label shifts on `014`, `015`, and `018` (`medium` $\rightarrow$ `hard`, `difficulty_level: 7`) are accurately documented as mechanical `quizctl` derivation from existing legacy numeric difficulty `7`, not an unreviewed re-calibration.

3. **Grading Privacy & Exact Option/Manifest Mapping**
   - Cross-artifact verification confirms `bundle.json` public `quiz.questions` equals `draft.json` questions minus `grading` (with `quiz_id` attached), keeping answer keys and explanations strictly isolated under `bundle.private_grading[qid]`.
   - `manifest.json` maps all 6 options (`source_index` `0..5`) to their exact `canonical_id` values and updates `source_explanation` for the 3 clarified items.

4. **Replacement Safety & Snapshot Boundary**
   - `replace_canonical.ps1` validates pre-replacement canonical SHA-256 hashes against `snapshot.json`, verifies candidate SHA-256 hashes (`draft.json`: `68f61b50...832985`, `bundle.json`: `f6372d69...6af8ae`, `manifest.json`: `755692af...03ade1`), performs atomic `[System.IO.File]::Replace` with `.bak` backups, and re-verifies post-replacement hashes.
   - Scope is strictly bounded to local canonicalization of `next/content/prep-capitals-1` with Go content/quizctl/attempts/sqlite suites passing and no unapproved server import, publication, feedback mutation, or frozen web candidate (`0c536221`) side effects.


Scope clarification: answer keys are private_grading; explanations are retained in manifest source_explanation and reviewed through their intended reveal path. The review does not approve a server import. Root independently reran content/quizctl/attempts/sqlite Go suites with -count=1 and exact packet verifier: PASS.
