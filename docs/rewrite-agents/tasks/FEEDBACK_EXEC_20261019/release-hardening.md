# Release controller hardening

The executor now rejects a release unless the locked target node is Ready, has no
DiskPressure, is schedulable, has no blocking taint, and has at least 20% free
blocks on the k3s containerd filesystem. It records only selected kubelet
eviction and image-GC fields. These checks run after taking the deployment lock
and immediately before build, import, and upgrade.

The original 13.6% disk state blocked release. Independently reviewed historical
artifact offload and removal of 32 unused Quiz Master images raised availability
to 23.82%; after candidate preparation it measured 22.90%. All 8964 offloaded
files were verified against an ACL-protected archive before removing originals.
The current and two preceding releases/images/backups remain on the server.
Other projects were untouched.

The imported containerd manifest digest is used for both workload containers.
Immediately before the atomic upgrade, the executor repeats the guard and makes
a fresh `0600` SQLite backup with an integrity check. `rehearse.py` is archived
with the candidate; it uses a disposable guest practice attempt and a real HTTP
answer request, rejects missing snapshot revisions or caller-owned scores, and
does not print bearer tokens or database rows.

`--phase prepare` stops after import, digest rendering and server dry-run, then
writes a locked immutable receipt. `--phase publish` accepts only an exact local
copy of that receipt, uploads it as the reviewed receipt, repeats the target
guards and backup gate, and performs no rebuild or import. Each SSH execution
uses an explicit 600-second timeout.
