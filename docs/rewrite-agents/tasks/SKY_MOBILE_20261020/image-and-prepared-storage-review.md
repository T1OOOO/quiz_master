### Independent Review Decision Summary

- **1. Exact Prepared Release 75 Candidate Image (`quiz-2026.10.20-sky-388e5c0c`): ACCEPT**
- **2. Exact 3-Target Prepared Offload (`storage-offload-prepared-plan.json` / `storage_offload_prepared.py`): ACCEPT**

---

### 1. Exact Prepared Release 75 Candidate Image — **ACCEPT**

Verified from [`prepared-image-evidence.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/prepared-image-evidence.json#L1-L43):

- **Receipt & Source Binding**:
  - `receipt.build_id`: `"quiz-2026.10.20-sky-388e5c0c"`, `source_commit`: `"388e5c0c943902b803002471896721496251230f"`.
  - `receipt.image`: `"quiz-master:quiz-2026.10.20-sky-388e5c0c@sha256:c606cee83ba594c921eb80867dd4a5d356b63e09983e2ff50585aac2088b97de"`.
  - `receipt.input_sha256`: `"755223f8cb24fee4a8edc644178b0d31871868f8ac11b4c682f153b1fb03a487"`.
- **Typed OCI Descriptor Chain**:
  - `index_digest` (`docker_inspect_id`): `"sha256:c606cee83ba594c921eb80867dd4a5d356b63e09983e2ff50585aac2088b97de"`
  - `platform_digest` (amd64 manifest): `"sha256:9bb5af26900a2973a8e224bdea2ebf446830341ccbb2dd0a4ed86a857fdccd2d"`
  - `config_digest` (CRI config): `"sha256:6ba85466cc90f7673344a83584dc6c728cbffee8159c369c4dd752927ea0ab0f"`
- **Image Content & Closure Proofs**:
  - `api_sha256`: `"e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4"` (unchanged from Release 74).
  - `main_dart_js_sha256`: `"f1dd3c18753b1596f75716114bf22a09fbffb0edf20afa57609b3ce46fcb3d0a"`.
  - `full_web_files`: `574`, `staged_json_files`: `24`, `image_web_closure`: `{"files": 574, "all_web_bytes_match": true}`.
  - `quiz_source_closure`: `{"original_files": 165, "candidate_files": 165, "approved_existing_mutations": 0}`.
- **SQLite Backup/Rehearsal & Live Cluster State**:
  - `integrity`: `{"backup": "ok", "rehearsal": "ok"}`, `restored_copy_sha256_matches_backup_before_rehearsal`: `"c839041d647540b0c39bdd975194c29028d85e9322bcf4d981523dc740fdb1c9"`.
  - Live cluster untouched at `live_helm_revision`: `74`, `live_deployment_revision`: `72`, `pvc_unchanged`: `true`.
  - Node healthy (`"Ready": "True"`, `"DiskPressure": "False"`, `"MemoryPressure": "False"`, `"PIDPressure": "False"`) with `imagefs_available_percent`: `20.061155343025867` (`capacity_meets_20_percent`: `true`).

---

### 2. Exact 3-Target Prepared Offload — **ACCEPT**

Verified from [`storage-offload-prepared-plan.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage-offload-prepared-plan.json#L1-L43) and [`storage_offload_prepared.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py#L1-L261) against previously accepted [`storage_offload.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py#L1-L261):

- **Plan Hash & Exact 3 Stopped Outputs**:
  - `PLAN_SHA256` in [`storage_offload_prepared.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py#L15-L16) is pinned to `'fb8d487972a544faee4aceb602111438e6cd7cd98529d36635051db76b57c9f3'` for `storage-offload-prepared-plan.json` (`local_destination`: `"storage-offload-sky-prepared-20261020"`).
  - Targets are restricted to 3 unique paths under `/opt/quiz-master/releases/quiz-2026.10.20-sky-388e5c0c/` ([lines 31-34](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py#L31-L34)):
    1. `base-quizzes` (`dir`, `expected_bytes`: `4212887`, `sqlite`: `false`)
    2. `candidate-quizzes` (`dir`, `expected_bytes`: `4212887`, `sqlite`: `false`)
    3. `rehearsal-data` (`dir`, `expected_bytes`: `81985536`, `sqlite`: `true`)
  - Total byte accounting: `4212887 + 4212887 + 81985536 = 90411310` (`planned_total_bytes`: `90411310`). No separate `restore-proof.sqlite` target exists because it was integrity-checked, hashed (`restore-proof-sha256.txt`), and moved (`mv`) into `rehearsal-data/quiz.db` by the accepted controller.
- **Helper Diff & Safety Invariants**:
  - Compared to [`storage_offload.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py), [`storage_offload_prepared.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py) changes only `PLAN_PATH`, `PLAN_SHA256`, the target count (`3`), the approved release prefix (`/opt/quiz-master/releases/quiz-2026.10.20-sky-388e5c0c/`), and adds `BACKUPS/'quiz-2026.10.20-sky-388e5c0c.sqlite'` to the explicit retained backup integrity check tuple ([lines 119-120](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py#L119-L120)). Zero backup paths are deleted.
  - `candidate_receipt` in [`storage-offload-prepared-plan.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage-offload-prepared-plan.json#L14-L18) matches the exact 3-field receipt in `prepared-image-evidence.json`, and `baseline` pins live Helm `74`, Deployment `"72"`, rollback `73`, `quiz-2026.10.20-water-82fb9c57@sha256:cfe81210...`, and PVC `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`.
  - Remote `tree()` and local [`local_verify()`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload_prepared.py#L84-L93) inspect the 16-byte SQLite header on every file inside directory targets, ensuring `rehearsal-data/quiz.db` passes `pragma integrity_check == 'ok'` both remotely and after restricted local extraction (`safe_extract` with `filter='data'`, `fsync`, ACLs, `DEPLOY.lock`, active-reference checks, and `actual == E` re-verification before unlinking). All staged release inputs, closure/restore SHA proofs, `prepared-receipt.json`, runtime images, and server backups remain intact for `publish`.
