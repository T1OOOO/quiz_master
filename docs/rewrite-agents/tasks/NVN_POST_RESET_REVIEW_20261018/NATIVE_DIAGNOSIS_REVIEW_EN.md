# Native review of the NVN path-identity diagnosis

What this review does: It checks why the frozen NVN input verifier fails after the workspace moved to E:/Projects/quiz_master. It reviews the current diagnosis, not a package, source acceptance, or deployment.

Requirements compliance: ACCEPT the diagnosis `FAIL_CURRENT_PATH_IDENTITY_NOT_BYTE_DRIFT`. Current frozen verifier/input acceptance remains BLOCKED. Code quality: the junction check is a deliberate fail-closed identity guard; this diagnosis provides no reason to weaken it. No implementation was changed or approved.

Reviewer: codex / gpt-6.1-sol, actual session session-4bba394f54044ade95cb217ecf020f7e. Accepted task task-0927758c3a9f45d0974599e4514296fb, run-f2b5fb82744c4e38b27193444a963fad. Skills applied: qm-review, agent-hub-coordination and systematic-debugging. This native review does not count as different-provider acceptance.

## Confirmed finding

The first direct proof reaches `prepare_nvn.py:204`, which calls `bound(entry, REPO/relative)`. At lines 103-109, `bound()` checks both resolved containment/equality and the absence of symlinks or junctions in the original path and every ancestor. Resolving a path successfully does not satisfy the separate raw-path ancestry check.

The frozen entry names C:\ap\quiz_master\docs\rewrite-agents\tasks\NVN_FOOTER_20261016\production-build.json. Its resolved path is the expected E:\Projects\quiz_master file, but C:\ap\quiz_master is now a Junction. The `all(not p.is_symlink() and not p.is_junction() ...)` condition is false. The error text groups path/hash/identity checks together, so the text alone would not prove byte drift.

I independently checked all 17 direct entries. Every entry has exactly that junction ancestor, no symlink ancestor, matching resolved expected path, containment within the actual E-drive repository, a regular file, link count 1, and its expected SHA-256. Thus the junction condition alone explains this observed direct-input rejection. It is not evidence that all later verifier gates pass.

For a bounded reproduction, I parsed the unchanged worker source, extracted only its exact `require()` and `bound()` function ASTs, and executed those with the actual Path, repository root and SHA function. The first frozen raw entry raised `ValueError: evidence path/hash/identity differs`. An in-memory entry using the canonical E-drive path passed the same function. This comparison created no manifest, changed no pin, invoked no package method and did not certify the old manifest. I did not execute the full verifier or test suite.

## Independent byte checks and saved failures

- release-inputs.json SHA-256 remains 931b441a658962db1cc799f79280c070131664f58ee3c043c82700c7da738eb9.
- prepare_nvn.py SHA-256 remains 3942ba48a8cc18de23c18586490697d98f75a589216c40958c5fa2c43bd701e8; test_nvn.py remains 66ea3ab8e973f706499a4fc827726b446a3671367b76efd0402e2a39ec1bbd69. Both match source-map.json.
- Rehashed all 17 direct pins, all 103 entries of runtime-evidence-inputs.json, and all 74 production plus 74 QA compiled-file pins. No pinned-file hash mismatch occurred. This is a pinned-byte check, not new runtime or archive verification.
- verify-inputs-failure.txt records the direct verifier exception at the same `bound()` call. source-tests-current.json records actual exit 1; source-tests-current.txt reports 16 tests, 15 passing and one ERROR in `test_actual_frozen_inputs_and_runtime_pass_without_archiving`, caused by that same rejection. Those are Root's saved executions, not executions I performed.
- Historical successful receipts cannot turn these current failures into PASS. The diagnosis and HANDOFF_EN.md correctly distinguish that history and do not claim a newly accepted source, archive or publication.

## Smallest adequate future migration

Track the separate change under quiz_master-wztw. Keep the old worker, source map, manifests, receipts and hashes immutable. Do not remove the junction test, allow all resolved aliases, patch old pins in place, or manufacture source acceptance for this frozen worker.

Create one successor version of the controller/input set using the actual canonical E-drive workspace. Rebind evidence paths through explicit repository-relative expected names, with canonical E-drive paths in the new entries. Inspect all nested paths consumed by `bound()`, including runtime-proof.json evidence entries: changing only the 17 outer manifest paths leaves later old C-drive entries subject to the same rejection. Any new proof copy needs its own hash and corresponding new manifest binding. Keep original command/receipt bytes as historical records; do not globally replace C: strings in captured history.

Preserve strict checks on the new raw paths and ancestors before trusting them: exact expected location, repository containment, no symlinks/junctions, regular file, single link, and exact bytes. Carry the old frozen input SHA as provenance, while pinning the new successor input digest and controller source hashes separately. This does not require a general alias compatibility mode.

A minimal regression should show the frozen C-drive junction entry is still refused, the new canonical equivalent passes, and an unexpected link, escaping path or wrong hash remains refused. Then rerun the actual non-generating verifier and focused suite on the complete successor set and obtain fresh independent acceptance. A first-pin diagnostic pass is insufficient.

Path migration alone does not refresh the release baseline. The inherited code fixes historical 29-feedback inputs and historical capacity; the current packet reports 43 OPEN and disk below the strict greater-than-20% floor. Fresh authoritative baseline/capacity evidence and any needed explicitly reviewed successor contract remain separate requirements before preparation. This review neither validates the live server nor authorizes an archive, candidate, deployment or feedback closure.

Not checked: full verifier/test execution, archive contents, current runtime/screenshots, live production, Git or Beads state. No source, old manifest or product file was edited; only this report was written. Risk: accepting matching bytes as a substitute for the failed path-identity guard would incorrectly certify a currently rejected input set.
