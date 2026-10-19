# Helm and Deployment revision reconciliation

The first actual publication invocation stopped at its Helm-history guard,
before image construction, database backup, or upgrade. The initial inventory
had called the Deployment annotation `deployment.kubernetes.io/revision=62`
the release revision. Fresh actual `helm history` instead showed Helm revision
64 deployed since 2026-10-16; revision 62 was superseded. These are independent
counters.

Both current containers still used the exact pinned `dc230d8…` image and the
`quiz-2026.10.15-country483-3c22818` build. PVC identity was unchanged. Fresh
inventory is preserved in `preflight-current.txt`; the first inventory and
failed invocation remain in `preflight.txt` and `publication-guard-reject.log`.

The controller now pins Helm revision **64** for history and rollback and
Deployment revision **62** separately. Preflight validates both and the PVC.
Free space is a measured positive value in inventory; the existing live
capacity formula remains the actual publication gate. Ten local tests passed,
including rejection of confusing the Deployment counter for the Helm revision.

Only the owned initial staging directory was removed after checking its exact
resolved parent, four expected entries, matching build metadata, unchanged live
Helm revision 64, and absence of any Docker image for the new build. No live
deployment or database was changed by the failed attempt.
