# Eight historical image archives: source gate

Reader291 candidate preparation passed, but the observed available space was only about 49 MB above the unchanged 20% release threshold, almost exactly the next SQLite backup size. Publication remains held while capacity is repaired.

This plan covers exactly eight regular Quiz Master `.tar` image archive files dated October 12, totalling 591,301,120 bytes. All eight were copied off-server and independently hashed locally before any proposed unlink. `copy-receipt.json` is the restore map; archive bytes stay in ignored `.run/actor291_release_20261015/archive-offload/offloaded/` and never enter Git.

This is a new scope, separate from the earlier 35-package recovery. It removes no loaded Docker or containerd images, snapshots, stages, databases, backups, services, configuration, or other projects. The source verifies every exact file's identity and SHA before any unlink and rechecks it immediately before unlink. Both modules refuse optimized Python; the shell unsets Python optimization and holds the existing deployment lock. Eleven local negative tests and inert shell/Python syntax checks pass.

The current, rollback, protected and failed-release archives remain, along with the new Reader291 candidate. Sixteen protected artifact hashes, current Helm60/PVC/29 OPEN feedback and the entire loaded Docker/containerd image inventories are checked before and after. `k3s-source-evidence.json` records the installed version and its official watcher source: removing an archive removes its cached file entry, rather than deleting its loaded images. Actual loaded image inventories remain a separate runtime guard.

Independent different-provider acceptance of the exact eight-file source manifest is required before execution. This document claims no server removal, recovered space, or Reader291 publication.

To recover one of these older versions later, copy the corresponding verified local archive back to its exact recorded remote path and verify its SHA. These historical archives will no longer be automatically imported after a future K3s restart unless restored. Current and rollback archives stay on the server.
