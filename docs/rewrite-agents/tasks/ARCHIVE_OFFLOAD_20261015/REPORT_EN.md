# Historical image-archive offload controller

This source-only controller permits a future, separately authorized unlink of exactly eight copied Quiz Master image archive files under `/var/lib/rancher/k3s/agent/images`. The intended plan is limited to regular `.tar` files dated 2026-10-12 and totals 591,301,120 bytes. It never invokes an image-store delete, image prune, K3s service operation, database operation, or recursive removal.

The selection accepts only lowercase `quiz-2026.10.02` through `2026.10.13` names with a seven-hex suffix and `.tar` extension. It protects the latest Reader291 candidate (`3482af9`), current Actor283 (`d204f9b`), Reader rollback (`06dfa0b`), Library rollback (`09b19cc`), and failed Reader (`17be4ce`) archives.

Before any unlink, every planned entry is checked for its exact logical path, regular-file type, non-symlink status, device/inode/size/mtime identity, and SHA-256. The whole batch is verified before the first unlink, then each entry is rechecked immediately before unlink. Traversal, duplicates, protected names, altered metadata, symlinks, directories, wildcards, and `.tar.gz` paths fail closed. Both source modules reject `python -O` before their logic runs.

`execute.py` cannot begin a remote command until it finds the genuine different-provider acceptance callback for `task-979f715e9ad542dd8d85e351c2074c0f`, binds it to the exact approval-input hashes, confirms no prior execution logs, validates the exact 8-entry/591301120-byte plan and receipt, and rehashes every local copy in `.run/actor291_release_20261015/archive-offload/offloaded`. This worker creates no source-review receipt and performs no remote operation.

This report is controller documentation only. Root owns the plan, copied-archive receipt, shell, manifests, execution evidence, independent review, and all release decisions.

Local verification: `python -m unittest -v test_offload.py` exited 0, reporting `Ran 11 tests in 0.452s` and `OK`. The fixture-only removal output names a temporary `/var/lib/rancher/k3s/agent/images/...tar` path; it is not a server action. `python -m py_compile offload.py execute.py test_offload.py` also exited 0. The optimized-Python regression invokes both modules with `python -O` and confirms each fails before its logic.

Source hashes for review:

- `offload.py` — `4b9cabce1ad588da6c1751ca6d73ec4fbb2ba65e7fe380d11b951f64664534f5`
- `test_offload.py` — `5d79a006ca122c10d60407c521ff0a05b5bc236ba8013daa71715f4a20e25cc3`
- `execute.py` — `a61e7bd99c256385717291ba02c4588ee3ba77f629d9dbc89804e15deb25c38f`
