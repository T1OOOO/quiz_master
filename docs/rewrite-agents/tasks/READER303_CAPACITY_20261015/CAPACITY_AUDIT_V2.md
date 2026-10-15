# Reader303 capacity audit v2 — sufficient archive inventory

This follow-up preserves the original report. It is a read-only direct-file inventory of /opt/quiz-master/releases/*.tar.gz and /var/lib/rancher/k3s/agent/images/quiz*.tar; no copy, delete, chmod, backup, K3s/Docker/Helm action, or process change was performed.

## Raw evidence

Successful remote command and unmodified command output are retained as v2-raw-inventory-command.txt, v2-raw-inventory-output.txt, v2-raw-candidate-success-command.txt, and v2-raw-candidate-success-output.txt. The first candidate sweep failed before remote reading because of a local shell syntax error; that failed output remains separately as v2-raw-candidate-output.txt. The successful sweep fully statted and SHA-256 hashed every proposed candidate.

Fresh df from the raw inventory: 102,417,174,528 total bytes and 20,221,370,368 available bytes. It remains below the strict 20% threshold of 20,483,434,906 bytes by 262,064,538 bytes. du -sb observed releases 6,763,292,862 bytes, backups 8,992,661,504 bytes, and saved image archives 585,206,272 bytes.

## Direct protected set and non-overlap

The candidate set excludes all six direct protected package archives from the accepted prior19/current62 retention set: library09b19cc, reader17be4ce, reader06dfa0b, actorsd204f9b, reader291-3482af9, and current reader299-9c670e9. It also excludes all K3s image archives: their loaded-image/current-retention status has not been re-proven here and this task authorizes no image deletion. Current Helm/image/PVC/feedback facts are inherited protection inputs from Root's fresh-baseline record, not fresh live Kubernetes checks by this audit.

## Sufficient copy-first set

The attached v2-candidate-set.json lists **28** fully pinned direct release archives: 28 unique paths, zero protected-path overlap, and **1518083884 bytes** total. This exceeds the requested ~1.5 GB archive reserve but remains less than Root's stated 2 GB preparation reserve. The raw direct inventory found only 1,591,746,122 bytes across all 33 unprotected release archives; therefore no 2 GB release-archive-only set exists under this allowed inventory. Saved image archives were deliberately excluded.

Every candidate's dev, inode, size, mtime_ns, SHA-256, and root manifest.json/RepoTags result is in the JSON receipt. 	ar -tzf found no root manifest.json for all 28, so Docker RepoTags are unavailable; these are release-package archives, identified only by their direct quiz-owned release paths and names.

## Gate

This is not an offload approval. A subsequent task must create and independently rehash local cold copies for an exact selected subset, re-check all metadata/protection/non-overlap immediately before action, have independent review, and use a guarded removal process. No candidate is approved for deletion by this report.

