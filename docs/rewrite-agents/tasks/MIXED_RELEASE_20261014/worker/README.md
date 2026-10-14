# Mixed release prepare controller

This version preserves the immutable ScreenSong52 archive and its baseline API, replaces only the independently built target API, repairs LOTR93/95, and adds the reviewed20-question `pub-connections-20261014` pack. Root owns execution, Git and publication. The producer only writes a new local stage/archive; it does not run Docker, SSH, rehearsal, Helm or cutover.

Root supplies `qm-mixed-release-pins/v1`. Copy the historical LOTR pin shape into a new Root-owned file, replace all stale source/build/assets/Web/browser proofs, remove ambiguous `api_sha256`, and add:

- `baseline_api_sha256`: `26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01`.
- `target_api_sha256`: `f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850`.
- `target_api`, `target_api_build`, `target_api_inspection`, `mixed_runtime_bundle`, `mixed_source_review`: each an absolute `path` and exact `sha256` pair.
- `frozen_commit`: final exact40-character integrated source; `build_id`: `quiz-2026.10.14-mixed-` plus its first7characters. The controller binds these dynamically after validating their format. Root need not modify Python source to refresh final identity.
- `source_assets`: exactly the historical9paths plus mixed raw `quizzes/Preparation/pub_connections_20261014.json` and `next/content/pub-connections-20261014/{draft,manifest,bundle}.json`. All must match frozen Git and disk bytes.
- `package_controller_review` and `package_controller_source_sha256`: actual accepted different-provider review and the exact5files listed in `CONTROLLER_FILES`. Review schema remains `qm-lotr-package-controller-review/v1`; scope must explicitly say prepare-only, no execution or publication. Recompute review after any worker-file modification.

Actual target ELF must be22988817bytes with the target SHA; build receipt must record successful Linux/amd64/CGO0 build, `-trimpath`, `-buildvcs=false`, and API-code checkpoint `9d842dfd641a2f288aef5f539c88d701b2d6c86c`. The actual inspection receipt and final frozen Git diff must show exactly `next/server/cmd/quizctl/catalog_test.go`, `next/server/internal/content/import_identity_test.go` and `next/server/internal/sqlite/collection_test.go` changed in server source. These three exact noncompiled test paths are allowed; arbitrary test paths and production changes are rejected. No embedded VCS claim is invented.

Run from `C:/ap/quiz_master` after independent source review:

```powershell
python -B docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker/prepare_lotr_package.py --pins NEW_ROOT_PINS.json --repo C:/ap/quiz_master --frozen-commit FINAL40CHARCOMMIT --production-web PRODUCTION_WEB --qa-web QA_WEB --prior-archive C:/ap/quiz_master/.run/screen_song_package_20261014/package-v1/quiz-2026.10.14-screen-song-6866608.tar.gz --output-root NEW_NONEXISTENT_ROOT
```

The stage contains136packs/4084questions/266Reader objects, retaining all135baseline catalog rows and264Reader objects, with145exact playable Reader bindings. Runtime cache grows12to14entries and canonical staging revisions160to280. API is executable in the archive and included in checksums. Unsafe archive aliases, traversal, symlinks and Windows drive paths are rejected. Existing output roots are rejected; retain failed stages for inspection.

The patched `cutover.sh` remains prepare-only. It preserves live baseline image/PVC guards, copied-DB backup/restore/rollback, nonce paths, target image hashes, exact digest values flow and server dry-run, and invokes `verify_candidate_runtime.py` before importing the image. The verifier runs the immutable resolved candidate image's real `/app/api` using `/app/quizzes`, a loopback port and an isolated SQLite backup copy. It compares unmodified DTOs, checks all pack counts, all147Reader refs (145playable plus exactly2known noncatalog country refs), LOTR98baseline objects and repaired revisions/options, mixed20public objects, and server grades100LOTR plus20mixed answers. Reveals are fetched after finish only. Receipt has aggregate evidence and no private keys/tokens/reveal payloads. Cleanup inspects the exact nonce-owned container and scratch path, verifies the source backup hash and checks port release. Root must inspect actual runtime receipt and independently review actual execution before publication.

Pure verification, from this worker directory: `python -B -m unittest discover -v`. Controlled fixtures and assertions are boundary evidence only. This worker did not execute the producer, image, remote commands, browser or publication; full Go/Flutter checks and all actual release gates remain Root-owned.

Public DTO equality retains optional `difficulty_level`, `context_tag_ids` and `media` fields only when present, and rejects private/unsupported extras. For the actual SQLite backend, unfinished practice reveals return404: `Reveals` delegates to finished-only `GetHistory`, whose missing finished row yields `ErrForbidden`, mapped to HTTP404. The gate requires that exact pre-finish status and fetches reveals only after finish.
