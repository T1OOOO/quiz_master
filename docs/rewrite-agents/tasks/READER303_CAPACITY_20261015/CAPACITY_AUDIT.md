# Reader303 capacity audit — 2026-10-15

## Scope and method

This is a fresh, read-only SSH inventory of quiz-owned archive paths. It performed no copy, deletion, chmod, backup creation, service action, deployment, controller run, or process/broker change. Commands used only `df`, `find`, `stat`, and `sha256sum` on the remote host.

## Fresh capacity measurement

At the audit time the root filesystem reported:

| Field | Bytes |
|---|---:|
| Total | 102,417,174,528 |
| Used | 76,964,569,088 |
| Available | 20,228,431,872 |
| Strict 20% threshold (`ceil(total / 5)`) | 20,483,434,906 |
| Deficit to strict threshold | 255,003,034 |

The host is therefore below the release gate. Nothing in this report waives that gate.

## Protected current62/Reader299 material observed and rehashed

Production identity remains Helm revision 62, image `docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4`, PVC `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, and unchanged full-29-open-feedback baseline per the accepted release path. The following current artifacts were freshly read and must not be touched:

| Path | Bytes | SHA-256 |
|---|---:|---|
| `/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9.tar.gz` | 60,973,734 | `01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d` |
| `/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar` | 87,443,456 | `96b931aa9555ee83090a609235b181c884fb4e197bb3fb8c0510aa42da24d438` |
| cutover backup `...reader299-9c670e9-cutover-20261015T122746Z.sqlite` | 49,364,992 | `6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21` |
| publish backup `...reader299-9c670e9-publish-20261015T124056Z.sqlite` | 49,364,992 | `6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21` |

The two current backups were mode `0600`; the package and image archive were observed as `0644` and `0600`, respectively. Current62 package, image archive, stage/rendered-values evidence, both current backups, Reader291 rollback material, protected recent releases/images/backups, and the feedback baseline remain outside any candidate set.

## Fresh cold package candidates

The previously documented Reader299 package-offload-v3 plan is stale as a selection source: its first expected file, `/opt/quiz-master/releases/quiz-2026.10.06-feedback-e0f89cf.recovery-20261015.tar.gz`, no longer exists. I did not reuse that old plan or execute its recipe.

The following live, old recovery archives are not named in the current protected-hashes manifest and were individually statted and fully rehashed. They are only **copy-first candidates**: no removal is safe until a new local cold copy is independently hash-verified and a new narrowly scoped execution/review packet accepts the exact live metadata.

| Path | Bytes | Device/inode | SHA-256 |
|---|---:|---|---|
| `/opt/quiz-master/releases/quiz-2026.10.12-culture-c15eefc.recovery-20261015.tar.gz` | 94,923,615 | 64770 / 398167 | `7979e969218d5d1fd1e9b721f803d6896195d76b36fd0df9b0faf2c02d9efb4c` |
| `/opt/quiz-master/releases/quiz-2026.10.04-lotr-e38bb24.recovery-20261015.tar.gz` | 82,267,466 | 64770 / 398625 | `51b6745e14fc02948d3c503ce3760b97869c6d20e241091c43ff1cbe12727d8f` |
| `/opt/quiz-master/releases/quiz-2026.10.04-study-3ebba4e.recovery-20261015.tar.gz` | 81,870,212 | 64770 / 398626 | `6806dd9b306071ed3a1281d209626d2bd5540f1e9d3508d6c7f1a6c9bba30c0b` |

Combined, these are 259,061,293 bytes. If, and only if, a separately approved copy-and-offload process later removed exactly these bytes without concurrent growth, free space would become 20,487,493,165 bytes—just 4,058,259 bytes above strict 20%. That is operationally too narrow for a release reserve.

## Recommendation and remaining gate

Do not execute offload from this report. Treat the three rows as the minimum known live candidate set that could cross the bare gate, but target at least 20% plus 512 MiB (21,020,305,818 available bytes). From the observed state that requires 791,873,946 reclaimed bytes; after the three candidate archives, another 532,812,653 bytes would still be required.

A future bounded capacity task must: (1) create new local cold copies, (2) rehash both endpoints and bind size/device/inode/mtime, (3) prove non-overlap with the complete current62/rollback protection set, (4) obtain independent review of the exact new plan, and only then consider a guarded remote removal. Fresh `df`, protected artifact hashes, image inventory, feedback baseline, backup integrity, and deployment identity must be rechecked immediately before and after any execution. No publication is ready from this audit.
