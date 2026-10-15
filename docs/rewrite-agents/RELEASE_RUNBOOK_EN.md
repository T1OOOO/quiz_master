# Current Flutter production release

The client is `next/apps/quiz_app`; the API is `next/server`. The current
deployment uses the existing `quiz-master` Kubernetes namespace and its SQLite
PVC. Legacy split-service/Expo/systemd deployment instructions in the repository
are not the production path. `scripts/deploy_server.sh` is a legacy script;
`Taskfile.yml` does not provide a current production deployment target.

There is no supported shared deployment command yet. Do not substitute a generic
Helm command or replay a historical release script. The release-specific
controllers bind the exact source, baseline revision/image, archive, generated
assets, values, backup and acceptance. A new release needs new pins and an
independent review of that exact executable packet. This is tracked in Beads
`quiz_master-7sw` and `quiz_master-qqx`.

## Reuse the verified boundaries

The [Reader 59 release evidence](tasks/READER_PUBLIC_RELEASE_20261015/STATUS_EN.md)
contains a real successful preparation, copied-database rehearsal, immutable image
verification, publication and compiled Flutter browser verification. Its
[preparation controller](tasks/READER_PUBLIC_RELEASE_20261015/worker/prepare_reader638_remote.py)
and [package producer](tasks/READER_PUBLIC_RELEASE_20261015/worker/prepare_reader638_release.py)
are reference implementations, not commands for the next release. Their baseline
58 checks deliberately reject the currently published revision 59. Keep historical
reviewed helper bytes intact; create the next finite release controller from the
proven boundaries and review its changed scope.

1. Check the actual target host, namespace, baseline Helm revision, both container
   images and PVC identity before uploading or changing anything. Read feedback
   securely and preserve real reports; test success alone does not resolve them.
2. Require node `Ready=True`, `DiskPressure=False`, no blocking `NoSchedule` or
   `NoExecute` taint, no cordon, HTTPS readiness 200 and at least 20% available disk
   on the actual k3s filesystem: `f_bavail * 5 >= f_blocks`. A flat 4 GB check is
   insufficient. Inspect the live kubelet eviction/GC configuration and expected
   package/image growth; passing a threshold once does not reserve disk space.
3. Repeat the guard inside the exclusive deployment lock and immediately before
   image build, image import and publication. Preserve all other projects'
   resources. Never run broad image pruning; remove only positively identified
   unused Quiz Master artifacts after retaining required rollback material.
4. Freeze and verify source/assets/API/bootstrap checksums. Exercise backup
   restoration and migration/rollback on a copied database, with answer integrity
   and row reconciliation. Verify the exact candidate image through real HTTP
   grading and article revision bindings. Keep failed attempts and their logs.
5. Import the exact verified image, pin both containers by digest and verify
   rendered values/manifests with Helm lint and server dry-run. Require a real
   different-provider acceptance bound to the packet, script, executor, archive
   and image. The project permits direct finite work without resource-queue
   waiting; independent review, exclusive ownership and these gates still apply.
6. Immediately before the single guarded atomic upgrade, create a fresh 0600
   SQLite backup with integrity/restore proof and repeat the node/disk/readiness
   guard. Allow SSH to outlast the upgrade **and** its automatic rollback. The
   Reader 59 executor uses 600 s around Helm's 180 s wait; retain partial output and
   an explicit exit/timeout receipt even when SSH fails.
7. Verify actual published revision, both images, source/version, JS and Reader
   digests, HTTPS, PVC and feedback preservation. Exercise the compiled mobile
   browser, inspect screenshots, close owned resources and obtain independent
   outcome review. State device and accessibility limits. Commit/push owned stable
   work with `[skip ci]`; never invoke GitHub Actions.

## Observed baseline, not future pins

On 2026-10-15 the successful published baseline was Helm 59, build
`quiz-2026.10.15-reader-06dfa0b`, with 279 articles and 29 unchanged OPEN feedback
reports. A later read-only kubelet `configz` inspection reported hard eviction at
5% available for both `imagefs` and `nodefs`, minimum reclaim 10%, and image GC
high/low thresholds 85/80%. The 20% release guard remains conservative. Inspect the
live values again rather than assuming historical incident thresholds still apply.
The [inspection receipt](tasks/RELEASE_PREFLIGHT_7SW_20261015/kubelet.json) retains
only those configuration fields, not credentials or full host configuration.
