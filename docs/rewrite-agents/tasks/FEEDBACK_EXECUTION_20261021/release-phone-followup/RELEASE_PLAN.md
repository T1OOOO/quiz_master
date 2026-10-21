# Phone camera follow-up — release preparation only

This is a future frontend-only controller. It is not a package, image, remote
preparation receipt, or authorization to publish.

`baseline-pins.json` and the private controller bind the sole valid live
baseline to Helm 79, Deployment revision 77, build
`quiz-2026.10.21-feedback-0c536221`, and its OCI index, AMD64 manifest and
config digests. The API SHA-256 remains pinned. Helm 78 and its former image
are rejected; they cannot be used as an input or rollback target for this
follow-up.

When the source commit and immutable build id are frozen, create a new package
from that source and run the controller's local validation. It must prove all
of the following before any remote action is considered:

1. The candidate only changes web bytes. Its API equals the pinned API hash,
   all 165 quiz sources are byte-identical, no baseline web path is deleted,
   and every non-generated changed asset is in the exact approved allowlist.
2. The immutable package contains its full web manifest, current chart, private
   quiz closure, candidate source hash and future build id. The exact image
   identity, all 804 inherited web files, and candidate web closure are checked
   after build and durable image import.
3. A fresh remote preflight proves the pinned Helm 79/Deployment 77/image/PVC
   lineage, Ready node, no DiskPressure, and more than 20% available imagefs
   blocks after the ext4 reserve check. No capacity waiver is allowed.
4. A physical database backup is hashed and restored on a copied database.
   The copied-DB rehearsal keeps all feedback hashes unchanged, exercises the
   exact 165-source closure and preserves rollback to the Helm 79 image.
5. An independent review binds the frozen source/package/image/receipt hashes
   before one locked atomic Helm upgrade. Failure restores the physical backup,
   rolls back to Helm 79, verifies PVC identity and feedback conservation, and
   unmounts temporary storage.

The dynamic candidate build id and source are intentionally absent until root
freezes them. Running this controller with a baseline-79 mismatch or without a
reviewed preparation receipt must fail closed.
