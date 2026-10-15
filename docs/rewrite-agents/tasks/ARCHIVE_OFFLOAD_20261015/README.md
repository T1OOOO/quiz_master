# Eight historical image archives: guarded recovery

Reader291 candidate preparation passed, but the observed available space was only about 49 MB above the unchanged 20% release threshold, almost exactly the next SQLite backup size. Publication remains held while capacity is repaired.

This plan covers exactly eight regular Quiz Master `.tar` image archive files dated October 12, totalling 591,301,120 bytes. All eight were copied off-server and independently hashed locally before any proposed unlink. `copy-receipt.json` is the restore map; archive bytes stay in ignored `.run/actor291_release_20261015/archive-offload/offloaded/` and never enter Git.

This is a new scope, separate from the earlier 35-package recovery. It removes no loaded Docker or containerd images, snapshots, stages, databases, backups, services, configuration, or other projects. The source verifies every exact file's identity and SHA before any unlink and rechecks it immediately before unlink. Both modules refuse optimized Python; the shell unsets Python optimization and holds the existing deployment lock. Eleven local negative tests and inert shell/Python syntax checks pass.

The current, rollback, protected and failed-release archives remain, along with the new Reader291 candidate. Sixteen protected artifact hashes, current Helm60/PVC/29 OPEN feedback and the entire loaded Docker/containerd image inventories are checked before and after. `k3s-source-evidence.json` records the installed version and its official watcher source: removing an archive removes its cached file entry, rather than deleting its loaded images. Actual loaded image inventories remain a separate runtime guard.

The exact eight-file source manifest was accepted by an actual independent Opus review. Execution and a separate fresh readback both exited 0. Exactly eight planned archives are absent; all sixteen protected hashes and loaded inventories (201 containerd names and 47 Docker entries) are unchanged. Helm60, the PVC, all 29 OPEN feedback rows, HTTPS and node health remain intact.

The logical removed size is 591,301,120 bytes; the measured immediate available-space increase was 591,273,984 bytes, reflecting concurrent filesystem activity. The fresh readback observed 21,346,770,944 available bytes out of 102,417,174,528, about 863 MB above the unchanged 20% threshold. A same-size backup would leave about 814 MB above that threshold; publication must still pass its own fresh guards. Independent review of this actual outcome is included in the Reader291 exact execution gate. Reader291 is not yet published.

To recover one of these older versions later, copy the corresponding verified local archive back to its exact recorded remote path and verify its SHA. These historical archives will no longer be automatically imported after a future K3s restart unless restored. Current and rollback archives stay on the server.
