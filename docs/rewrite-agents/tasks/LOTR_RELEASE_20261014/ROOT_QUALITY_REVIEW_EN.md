# Root bounded review of the release validator

Correctness: actual v1/v2 independent reviews found and rejected missing library preservation and incomplete source byte enforcement. Final v3 compares all nine declared frozen source files, enforces actual135/4064/266 counts and prior135catalog/264Reader preservation, and checks all98 untouched public LOTR projections, exact repaired revisions and retained q95 option5. Root's15-test suite and inert main against actual baseline/archive/cache/pins exited0; exact commands are in root-validator-checks.json.

Readability and architecture: the validator exposes small functions for pins, build receipts, runtime projection, library preservation, cache append and safe archive inspection. It emits VALIDATED_NOT_PREPARED and has no package builder or live publisher. It remains a finite release-specific tool; later package/rehearsal/execution gates are separate responsibilities.

Security: every declared source asset resolves below the repository before its bytes are read and hashed. The archive is read for member inspection, never extracted. No shell, network, credentials, database, deployment or write path exists in the validator. Root pins and reviewer receipts are explicit trusted lead inputs; hash-format checks alone are not independent fact verification. Local browser receipts contain no session bearer tokens; production feedback stays open.

Performance: bounded local JSON/hash/archive work for the pinned47MB archive and135-pack metadata; no parallel build/network/DB work is hidden here. Actual final inert validation took roughly a second. No runtime product path changed in this checkpoint.

Limits: the validator approves no package, live Python bridge, copied database, restoration, rollback, execution script or deployment. Desktop narrow-viewport browser verification does not certify physical Android. Source validation here certifies the bounded two-question repair and preservation, not all4064 question facts. Historical v1/v2 reviews and Root pin failures remain in evidence. The final v3 independent review is separately recorded and must be accepted before this stable checkpoint is staged.
