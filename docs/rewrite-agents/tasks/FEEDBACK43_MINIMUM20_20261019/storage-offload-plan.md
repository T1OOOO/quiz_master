# Storage offload plan — review candidate only

This package is a reversible capacity-recovery proposal for the exact 30 paths in [storage-offload-plan.json](storage-offload-plan.json). It does not authorize or perform a copy, deletion, image cleanup, deployment, database mutation, process action or publish.

The latest read-only inventory found the live node at 19.624% imageFS, below the normal 20% release gate. A recovery operation may run below that threshold, but the helper never builds or publishes an image and must restore capacity before a later release preflight. The complete literal candidate set is 1,408,275,024 bytes: the prior own inputs, seven current-stage rehearsal copies, three older feedback backups, two verified legacy Quiz Master archives, and twelve old Country483/Reader303 rehearsal backups. The plan retains the current books and bones backups, all images, Helm 68/69, the PVC, receipts, charts, manifests and feedback data.

[storage_offload.py](storage_offload.py) is fail-closed. Its default `--plan` mode is local-only. Its future `--stage` action requires a non-OpenAI `ACCEPT` review receipt bound to the exact plan SHA, acquires the remote deployment lock for a fresh snapshot, checks host/deployment/image/PVC/Helm/node/current receipts, rejects symlinks and active Docker/CRI/pod references, calculates SHA-256 entries and SQLite integrity, and downloads one tar stream into a new ACL-restricted `.run/private/storage-offload-20261019` directory. It then verifies every extracted file and SQLite database before writing a local snapshot manifest.

The separate future `--apply` action requires the same independent receipt and a verified staged snapshot. Under `DEPLOY.lock`, it repeats the live guard and exact snapshot comparison before unlinking only the literal allowlist. Any changed remote byte, missing local archive, wrong hash, symlink, SQLite failure or state change stops it. The local archive and extraction are never removed by the helper.

The Country483 and Reader303 archives are classified as same-project legacy material using read-only Hub task evidence and exact root-owned archive names. Their ownership remains reviewable rather than inferred from unrelated disk files. No other October archives are eligible.

No `--stage` or `--apply` command was run for this task.