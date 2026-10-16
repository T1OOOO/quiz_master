# DISK_HEADROOM_20261016 independent proposal review

Task: `task-5ddd3dd27d464ae0ab1e76f20de8bbd0`

Reviewed proposal: `proposal.json` SHA-256 `edef4994d488f4c2894d7a3c6cde9b86f2be396155bf7998704adfe96f9f8b70`.

The calculation is internally consistent. At 19,175,731,200 available bytes out of 102,417,174,528, the stated 18.723% is correct to three decimals. Strictly exceeding 20% needs 20,483,434,906 available bytes, so the minimum reclaim is 1,307,703,706 bytes. Adding the stated 1 GiB reserve and 64 MiB growth allowance produces a planning target of 2,448,554,394 bytes. The 28 selected observed directory estimates total 2,231,140,352 bytes, therefore fall short by 217,414,042 bytes. The later 18.700% health sidecar is observational only and does not repair the frozen calculation.

The exact candidate set is confined to named October 02–14 release directories. It excludes both known rollback directories (`quiz-2026.10.14-library-09b19cc`, `quiz-2026.10.14-reader-17be4ce`), all October 15 and later releases, current/rollback packages, backups, secrets, PVC, frozen inputs, loaded images, and unrelated resources. The selection is still only directory-level `du` evidence: it is not a file-tree fingerprint, a verified reclaim amount, copy proof, or deletion allowlist. The proposal correctly sets `planning_target_met_by_estimate` to false and does not establish any cause for global disk growth.

Historical controllers cannot authorize this proposal. `ARCHIVE_OFFLOAD_20261015` covers exactly eight already-copied regular image `.tar` files and rejects directories, symlinks, altered metadata, and unbound execution. `COUNTRY483_REMOTE_20261015/capacity/worker` is a separate backup-alias plan pinned to its own historical source and current63 assumptions; it cannot be repointed to this current64 directory-tree proposal. Both require exact reviewed inputs and genuine different-provider review before any remote mutation.

Before any separate operational request, the shortfall needs a newly reviewed capacity source; fresh file-level no-follow tree fingerprints and protected-resource proof; private external copy, whole-payload verification, and isolated restore; current64 preflight with project lock/quiescence; fail-closed directory-tree source/tests; and post-operation proof of the strict floor, reserve, growth bound, and unchanged protected/runtime/feedback/image state. None exists here.

Verdict: `accepted_for_proposal_only`. This accepts the document as an honest non-executable research proposal that reports its own shortfall. It does not approve its source or inputs, copying, unlinking, cleanup, remote execution, release, or publication.
