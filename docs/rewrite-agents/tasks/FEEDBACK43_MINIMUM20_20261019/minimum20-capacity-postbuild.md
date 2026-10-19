# Minimum20: capacity after image build

This is a read-only SSH inventory taken after the release-70 rehearsal stopped at the node-capacity guard. It does not authorize cleanup or publication.

The candidate image index is `sha256:09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee`; it has **not** been imported into CRI and Helm remains revision 69 / Deployment revision 67. The previous immutable baseline is retained.

The SSH `df` sample saw 20,994,117,632 free bytes of 102,417,174,528 (20.498%). That differs from the reported post-rehearsal node-guard value of 19.9620439%; neither value creates the requested roughly 1 GB protected headroom for CRI import and publication. Re-run the live guard under the deployment lock before any continuation.

`quiz-2026.10.19-minimum20-7f8344d6` is 290,901,356 bytes. Its candidate rehearsal copies total 173,498,726 bytes: `base.api`, `new.api`, the two quiz snapshots, `restore-proof.sqlite`, and `rehearsal-data`. They were only identified for a separate review; this report retains the complete current stage.

Other large old project stages are country483 (284,034,774 bytes), reader303 (196,116,173 bytes), feedback-849e6705 (477,323,113 bytes), and mobile-2e28262c (177,512,137 bytes). Their receipts, active references, backups and offload destinations were not verified here, so none is a deletion candidate yet.

Buildx v0.37.0 reports 6.698 GB reclaimable. Its prune interface has filters and aggregate space targets but no exact cache-ID deletion. It also marks recently used records reclaimable. A build-cache prune would therefore be broad, not a safe scoped recovery operation, and was not run.

See `minimum20-capacity-postbuild.json` for the exact paths, component sizes and read-only evidence. No server mutation was performed.
