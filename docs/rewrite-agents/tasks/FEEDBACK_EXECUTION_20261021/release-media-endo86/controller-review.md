# Independent review

Actual conversation 1fa8e20a-d6d4-4742-98e4-96014220f1a6

**ACCEPT**

### Independent Rebase Review Summary (Baseline 84 → 85 / Prospective Frontend 86)

1. **Pinned Baseline 85 Lineage & Digests (`release_executor.py`)**:
   - `BASE_REVISION = "85"` and `BASE_DEPLOYMENT_REVISION = "83"` match Live 85 `helm_revision` and `deployment_revision`.
   - `BASE_BUILD_ID = "quiz-2026.10.21-feedback-d0dff40a"` and `BASE_IMAGE` match Live 85 `build_id` and `image`.
   - `BASE_OCI_INDEX_DIGEST` (`sha256:093122f1...`), `BASE_OCI_MANIFEST_DIGEST` (`sha256:52c135f3...`), and `BASE_DOCKER_CONFIG_DIGEST` (`sha256:62984511...`) are distinct 64-hex digests matching the verified Live 85 image index, platform manifest, and config.
   - `BASE_INPUT_SHA256 = "44ae28a10eac1c2be311461d8b2f32d8e59bf2bc9f6dc9a8e338848d12b42608"` matches `publish-restore-evidence.json` (`input_sha256`).
   - `API_SHA256` (`e2884077...`), `PVC_UID` (`7fc2428f-...`), and `EXT4_RESERVED_BLOCKS` (`1271337`) remain unchanged.

2. **Version Contract & Asset Allowlist (`prepare_package.py`, `release_executor.py`)**:
   - `quizipedia_facts` is consistently updated from `13828` to `13830` (+2 facts from the added country association) in both `prepare_package.py` and `release_executor.py` (`collect_inputs`), while all other contract invariants (`packs=105`, `questions=4520`, `quizipedia_sections=15`, `question_articles=305`, `question_article_references=241`, `frontend_only=True`, `195` content-addressed flags) are preserved.
   - The 44-entry allowlist (3 updated JSON files + 41 new PNG assets, bringing total files from 826 to 867 with zero deletions) contains exact `path`, 64-hex `sha256`, and positive `bytes` specifications.

3. **Guard Tests (`test_inherited_guards.py`, `test_release_executor.py`)**:
   - All baseline constants, rollback targets (`helm rollback quiz-master 85`), target revision checks (`= "86"`), OCI manifest prefix checks (`sha256:52c1`), and replay rejection guards (`84`/`82` rejected by `85` controller) are updated in lockstep without removing or weakening any negative guard assertions.
