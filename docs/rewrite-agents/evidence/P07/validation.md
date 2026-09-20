# P07 local validation evidence

All commands used `C:\ap\quiz_master` and only disposable resources beginning with `qm-p07-`.

| Command | Exit | Duration | Result |
|---|---:|---:|---|
| `./next/infra/validate.ps1` | 0 | 21.787s | Pin scan, `docker compose config`, API build, isolated API/PostgreSQL startup, both health probes, logs, and exact teardown passed. |
| `go test -count=1 -tags integration ./next/server/internal/migrate ./next/server/internal/identity ./next/server/internal/store` | 0 | under 30s | Passed against project `qm-p07-int-58ba6250a02c`; its API and PostgreSQL resources were removed afterward. |
| `go test ./...` | 0 | 26.2s | Full Go suite passed. |
| `go vet ./next/server/...` | 0 | 2.5s | Passed. |
| `flutter pub get`; `dart format --output=none --set-exit-if-changed .`; `flutter analyze`; `flutter test` | 0 | fresh commands: 5.8s, 0.08s, 9.0s, 12.3s | Dependencies resolved without lock editing; formatter changed 0 files; analyzer had no issues; fresh test run passed 20 tests. |
| `flutter build web` | not re-claimed | initial bounded run exceeded this tool session's 30s observation window | P06 already records its successful 77.2s Web build. P07 records the existing `main.dart.js` SHA-256 (`262A0B01CB2140031E08988EEE986755E15D0EB443F72B132FA2D243E0F0A64C`) but does not present a second fresh build-success claim. |
| `rg -n -i 'correct_answer|private|answer_key|token_digest|session_token|bearer' build/web` | 1 (no matches) | under 1s | Private-marker scan found no matches. |
| Python YAML parse plus immutable-ref scan | 0 | 0.8s | Revised `quiz-v2-ci.yml` parsed (`YAML_OK`); the Dockerfile frontend/base images, Compose image, and all workflow `uses:` values passed (`PINS_OK`). |
| fixed-string private-marker probes | 0 | 1.5s | Each P06 marker (`private_grading`, `accepted_variants`, `correct_option_id`, `correct_option_ids`, `published_bundle`, and quoted `draft`) returned `rg` exit 1 only. The CI loop treats 1 as clean and propagates any other scanner error. |

The revised Web artifact step creates `build/web/SHA256SUMS.txt` from every regular file in the uploaded directory (sorted in the C locale, excluding the manifest itself). It no longer hashes only `main.dart.js`.

The final successful local validation project was `qm-p07-4be89b57c81e` (23.440s). Compose rendered its network as `qm-p07-4be89b57c81e_quiz_v2` and volume as `qm-p07-4be89b57c81e_postgres_data`; teardown exited 0 and its post-teardown volume-label query returned only the header (`DRIVER    VOLUME NAME`). The built API image ID was `sha256:ea0946fb6c4d937977ba3466113005fc5fa7ccb271c11b200f11a8a79fdefbd0`.

Registry metadata resolved the linux/amd64 manifests for the Go builder and runtime, and PostgreSQL 17. The immutable index pins used in the checked-in files are recorded in the report.
