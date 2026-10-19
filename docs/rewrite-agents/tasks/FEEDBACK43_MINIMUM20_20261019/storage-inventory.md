# Read-only storage inventory — 2026-10-19

The SSH inventory made no remote change. It found the deployed build `quiz-2026.10.19-bones-36e0b68c` at Helm 69 / Deployment 67; Helm 68 remains in history. Both containers use digest `54a3455a…d54a`; the PVC UID is unchanged. The node is Ready and has no DiskPressure, while imageFS is **19.624%** free (20,098,121,728 of 102,417,174,528 bytes). This is below the 20% release guard, so no image build or publish may start.

`/opt/quiz-master/releases`, `/opt/quiz-master/backups` and imageFS are all `/dev/vda2`. Thus only bytes actually removed from this same filesystem could restore capacity. The known own candidates total **693,916,428 bytes** if every item below survives the future copy-and-review gate: old 5df/8954 inputs (200,261,576), seven 36 rehearsal copies (218,801,052), three older same-project SQLite backups (174,440,448), and 36 input copies (100,413,352). This reaches only **20.301%**, below the requested 1.5 GB recovery by **806,083,572 bytes** and below a 20.8% headroom target by **510,734,145 bytes**.

No additional clearly owned archive was found. The country483 and reader303 tarballs are intentionally excluded: their ownership was not established. Current 68/69 backups, all images, receipts, manifests, chart inputs, PVC data and feedback data are excluded.

A later, separately reviewed offload may copy only the enumerated candidates to `E:/Projects/quiz_master/.run/private` after creating a root-only destination. Before deleting anything remotely it must: repeat the live deploy/node/PVC/Helm/receipt checks under `DEPLOY.lock`; prove exact resolved paths, non-symlink trees and ownership; create a file-level SHA-256 manifest before and after copy; run `sqlite3 pragma integrity_check` on both remote and local copies for every SQLite file; verify the local manifest byte-for-byte; and recheck imageFS after removal. This task does not implement or execute that operation.

See `storage-inventory.json` for exact filenames, types and byte counts.
