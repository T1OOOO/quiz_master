# Extra offload candidate: four inactive Quiz Master release stages

This plan is **preparation only**. `storage_offload_extra.py` defaults to `--plan`; it has not copied, offloaded, deleted, pruned, built, imported an image or changed Helm.

The plan SHA-256 is `9b33c948dda966c0b2aed932fe56c20fb5b9837ee2864586f59ff35f17c9dcaf`. It names 21 literal components totalling 1,127,768,030 bytes, above the 1 GB planning goal:

- `quiz-2026.10.19-feedback-849e6705`: 477,187,564 bytes
- `quiz-2026.10.19-mobile-2e28262c`: 177,432,266 bytes
- `quiz-2026.10.15-country483-3c22818`: 280,515,080 bytes
- `quiz-2026.10.15-reader303-14b7da4`: 192,633,120 bytes

The literal paths contain only copied API/web/quiz material, failed rehearsal material, rehearsal data and restore-proof SQLite files. Receipts, charts, manifests, release input records, feedback evidence, images, Helm state, PVC data and the current minimum20 stage are excluded.

Read-only SSH evidence found zero symlinks in all four selected stage roots and no Docker, CRI, pod or process reference to their roots at sampling time. The remote `/opt/quiz-master` folder is not a Git checkout. Subsequent native local Git and remote `web/version.json` checks matched all four full source commits to this Quiz Master repository. The 849 stage also has matching prepared/reviewed receipts; Hub messages 58641 and 57994 record prior publications at Helm66 and65. See `extra-stage-provenance.json`. The prior rejected mobile cleanup concerned a local `.run/` candidate, which is explicitly excluded; this plan concerns separate remote copied inputs.

`--stage` requires a different-provider ACCEPT receipt with this exact plan hash. It acquires `DEPLOY.lock`, rechecks live 69/67/PVC/image/rollback/health guards and every literal source path, streams a tar to restricted local storage `storage-offload-extra-20261019`, validates all files and nested SQLite databases, fsyncs archive and snapshot, and leaves remote data intact. `--apply` is separate; it repeats the same guards and exact manifest under the lock before unlinking only the 21 reviewed literals. The helper uses UTF-8 byte ordering for Windows/POSIX manifest parity.

No application of this plan is authorized by this report.
