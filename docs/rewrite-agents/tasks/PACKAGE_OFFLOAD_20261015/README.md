# Finite package offload — Beads quiz_master-7sw

This is a one-time capacity repair, not a release or a global cleanup policy.
The exact plan contains 35 regular compressed static packages (1,583,875,913
bytes) under `/opt/quiz-master/releases`, dated October 2–14. Each selected
file must have a complete, SHA256-verified off-server copy before removal.

Current Helm 60, rollback 59, protected 58 and the failed 17be package are
excluded. Eleven protected package/image-archive/database hashes are checked
before and after. No database, extracted stage, Docker image/cache, K3s image
or durable image archive is removed. Other projects are outside the scope.

`offload.py` validates the complete exact list before the first unlink and
rechecks each file's identity, size, modification time and SHA256 immediately
before unlinking. No recursive deletion or directory walk is used. The remote
script holds the existing Quiz Master deployment lock and checks Helm, both
container images, PVC, readiness, node health and all 29 open feedback rows
before and after. Capacity repair can start below 20%; it reports the actual
ratio. The release's existing 20% guard remains mandatory.

`execute.py` requires the genuine different-provider acceptance callback for
task-f23e797ad2fd45938696186c1ea09354, pinned to `approval-inputs.json`, and
revalidates all approved source bytes and all 35 local copies before SSH.
Execution stdout, stderr and actual exit are retained even on failure; partial
execution must be inspected rather than blindly retried. The nine fixture
tests cover wrong paths, protected files, identity/content changes, duplicate
entries and missing or unrelated approval. Fixtures delete only their own
temporary files.

Restore map: `copy-receipt.json` records each exact ignored local path, remote
destination, byte length and SHA256. To restore a removed archive, first verify
its retained local hash, ensure that the remote destination is absent, copy it
to a new temporary file in the same release directory, verify the remote hash,
then rename without overwriting an existing destination. Do not copy database
or configuration files from an old package into the live application.

Preparation uses the saved inventory and standard SSH/SCP. One read-only hash
inventory attempt rejected an atime change after reading a file; the corrected
inventory compares device/inode/size/mtime, which define this plan. No file was
removed in either inventory attempt. Python 3.12.3 was observed on the target.

Off-server archive bytes remain ignored; only the exact plan, checksums,
receipts, tests, reviewed finite source and execution evidence belong in Git.
Actual removal and recovered capacity require the subsequent execution record.

## Recorded execution

The genuine Opus source callback accepted manifest
`8801c72629a53a98c4d5a037aa1f29a2369911ec4df40ab47d9a042ca6eed53c`.
The bound executor then exited 0. Its log records exactly 35 removals and all
eleven protected hashes verified again afterwards. A fresh read-only SSH call
also exited 0: all 35 files were absent; protected hashes, Helm 60, both current
images, PVC, readiness and the 29 open feedback rows were unchanged.

Available bytes rose from 20,000,559,104 to 21,583,872,000 during execution.
The observed increase is 1,583,312,896 bytes; it differs from the selected logical
file sizes because of allocation and concurrent disk activity. The later
readback measured 21,561,487,360 available of 102,417,174,528 total. The mandatory
20% release guard passes; the additional planned 1.5 GB buffer does not. That
extra buffer was an estimate, not a replacement for the existing release gates.
This recovery does not itself authorize or certify a Reader291 publication.
Independent outcome review is tracked by task-b0d4c842bb5a4a398c5bcfdedd8a012d.
Its genuine Opus callback is now ACCEPTED in `outcome-review.json` (CLI exit 0).
That acceptance covers the recorded recovery and unchanged production only.
