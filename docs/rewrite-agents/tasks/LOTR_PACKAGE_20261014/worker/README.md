# LOTR immutable package producer

`prepare_lotr_package.py` is prepare-only. It reads the immutable ScreenSong52 archive, the frozen LOTR source/build pins, and a later independent review of these exact worker files. It creates a new local stage, deterministic archive, checksum manifest, expected staging revisions, and `package-preparation.json`. It never runs the staged cutover or rehearsal.

Before invocation, Root must copy `LOTR_RELEASE_20261014/root-validator-pins.json` to a new Root-owned package pin file and add:

```json
{
  "package_controller_review": {
    "path": "ABSOLUTE_PATH_TO_REVIEW_JSON",
    "sha256": "SHA256_OF_REVIEW_JSON"
  },
  "package_controller_source_sha256": {
    "prepare_lotr_package.py": "FINAL_SHA256",
    "test_prepare_lotr_package.py": "FINAL_SHA256",
    "README.md": "FINAL_SHA256"
  }
}
```

The review JSON must use schema `qm-lotr-package-controller-review/v1`, record a successful accepted Hub review from a provider different from the OpenAI author, repeat the exact three source hashes in `reviewed_worker_sha256`, and bound its scope to `prepare-only`, `no execution`, and no publication. Missing or changed evidence fails before output creation.

Root invocation after independent source review:

```powershell
python -B docs/rewrite-agents/tasks/LOTR_PACKAGE_20261014/worker/prepare_lotr_package.py `
  --pins ABSOLUTE_NEW_PACKAGE_PINS.json `
  --repo C:\ap\quiz_master `
  --frozen-commit 9194f61face75d03862003942ef55fae34aeec72 `
  --production-web C:\ap\quiz_master\.run\lotr_build_20261014\production-web `
  --qa-web C:\ap\quiz_master\.run\lotr_build_20261014\qa-web `
  --prior-archive C:\ap\quiz_master\.run\screen_song_package_20261014\package-v1\quiz-2026.10.14-screen-song-6866608.tar.gz `
  --output-root ABSOLUTE_NEW_EMPTY_PATH_THAT_DOES_NOT_EXIST
```

The output root must not exist. A failed attempt is retained for inspection; rerun with another new path. Root owns copied-DB rehearsal, rollback, image/Helm/server/browser gates, publication, and post-publication verification.
