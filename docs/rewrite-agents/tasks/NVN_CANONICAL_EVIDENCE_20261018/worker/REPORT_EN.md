# Canonical historical NVN evidence verifier

DONE, ready for exact-source independent review. This is a non-generating historical verifier. It creates no source acceptance, release package, archive, candidate or publication. Current 43 OPEN feedback and failing live disk gate remain separate from historical 29 OPEN/capacity receipts.

Owned implementation: verify_historical.py, migrate_evidence.py and test_historical.py, this worker's reports/receipts, and the evidence/ copies. No old frozen, product or foreign WIP file was edited. Hub task task-d6fc7bef25a04407b57330354e7c464e, run-33e904d71dd0472ebe0fdedeb902cd54, actual implementer session-a3b79d5718734eb48ac2845a48ae6ebc / codex gpt-6.1-sol. Root owns integration and the different-provider review gate.

## Fixed reuse and evidence migration

The new verifier imports the exact old prepare_nvn.py SHA 3942ba48a8cc18de23c18586490697d98f75a589216c40958c5fa2c43bd701e8 in a separate namespace. It pins the old test/source/input bytes and checks pinned producer/dependency files before import. The old validator and house functions perform the complete input, source-acceptance-history, recorded baseline, build, runtime and prior archive safety checks. No archive-producing function is called. The successor CLI accepts no arguments; --prepare and --verify are unavailable, and optimized Python is refused.

The old bound() implementation is reused unchanged. Incoming evidence paths must also be absolute and already canonical. Only its expected-location argument is translated through the fixed old evidence root to the new evidence root. Incoming raw paths are never rewritten or accepted via an alias allowlist. Old C-drive alias entries still fail. Symlink/junction, escaping-path, single-link and digest guards remain active.

The isolated old ROOT is retargeted to evidence/. The old footer root, product pins, compiled trees, original fixture binary/data/server targets and prior archive remain canonical E-drive references. The QA runtime receipts and baseline files needed by ROOT-relative reads are byte-identical copies. Raw command paths inside captures remain original historical facts.

The new migration-map.json has exactly 117 old/new rows: 58 moved unchanged-byte files, three regenerated binding-metadata files, and 56 unchanged-location files. It records explicit old/new raw byte hashes. The new release-inputs.json preserves exactly 17 logical proof names; runtime-evidence-inputs.json preserves exactly 103 logical closure members with explicit physical-name migration. Both 74-file compiled trees are validated unchanged. Root proof paths, nested runtime-proof paths and compiled-root metadata now name canonical E-drive locations. All old manifests remain immutable provenance.

The three regenerated metadata records are release-inputs.json, runtime-proof.json and runtime-evidence-inputs.json. The new input raw SHA is ff528319354792eb7521531931ad32918be665692e6154e929a7f47098008918; migration-map raw SHA is b675c6a606fcf379c5df7d4af630e3e95cc898dbd0c1589fecd11273d22cc313. These digests are pinned in the new controller. Exact mapping row coverage, kinds and original hashes are checked in addition to that digest.

The runtime validator is reused with four exact one-occurrence source-anchor changes: identity-capture.json, close.json, exact-daemon-cleanup.json and fixture-cleanup.json are now read through a strict manifest-member binder. The complete runtime map must equal the canonical migration of all original 103 path/hash pairs; extra, missing and same-count replacement members fail. No unseen lifecycle file can supply acceptance data outside that bound closure.

The copied fixture-source.json retains its original server.py.sha256 field, which describes normalized UTF-8 text, not raw bytes. The historical fixture-provenance-correction.json documents this. The correct raw server byte hash is bdd49469d9ee8d8445f51e2f20c08af344e685b2a9fadd26d85afcaa55cecdd0 and was already pinned in the old runtime manifest. The new mapping labels raw byte hashes explicitly; no old capture was rewritten to appear newly executed.

## Actual verification

Before editing, the exact old require()/bound() AST was executed against the first frozen raw pin. It raised the expected path/hash/identity ValueError at the C:/ap/quiz_master junction, with the original input digest still 931b441a658962db1cc799f79280c070131664f58ee3c043c82700c7da738eb9. The regression suite repeats raw rejection and canonical acceptance using the actual frozen function.

RED: the first new behavior test failed because the successor executable did not yet exist. A later mapping-coverage regression produced four real assertion failures (empty, missing, duplicate-extra and misclassified rows were not refused); exact row coverage/kind checking fixed that. Saved RED logs are included in this worker.

Final checks from E:/Projects/quiz_master:

- C:/Python314/python.exe -B -m unittest discover -s docs/rewrite-agents/tasks/NVN_CANONICAL_EVIDENCE_20261018/worker -p test_historical.py -v: 12 tests PASS, actual exit 0, 4.577 seconds reported by unittest. tests.json/txt record the command, collector elapsed time and raw log byte hash.
- C:/Python314/python.exe -B docs/rewrite-agents/tasks/NVN_CANONICAL_EVIDENCE_20261018/worker/verify_historical.py: actual exit 0, PASS_HISTORICAL_EVIDENCE_ONLY; 17 direct pins, 103 runtime files and 148 compiled files. historical-check.json/txt record the actual receipt.
- All 79 Root-frozen scope pins rehashed unchanged. preservation-check.json records the count and original input digest. The full historical check additionally rehashes all original 17/103 bindings and validates both complete 74-file trees, preserving the old source/input/runtime closure.

The negatives exercise actual Windows symlink, junction and hardlink files, wrong hash, outside-repository path, nested stale alias, missing lifecycle members, extra/missing/same-count closure substitution, false close/count/port/API outcomes, incomplete mapping, existing migration destination, unsupported preparation modes and optimized execution. There are no skipped cases. Tests create and clean up only named owned ignored scratch directories.

During regeneration, a tool-policy rejection stopped an attempted removal of the worker's generated evidence directory: the exact returned reason was `blocked by policy`. No deletion executed. The safer successful action verified the literal source and destination absolute paths, then used native PowerShell Move-Item -LiteralPath to preserve that first generated attempt under .run/heartbeat_20261018_0231/worker/evidence-attempt01. The final evidence was generated at a fresh destination. No policy bypass or old artifact change was attempted.

Not checked: Flutter/Go suites, new browser/runtime, live production, current capacity, Android, archive generation or candidate rehearsal. Matching historical evidence is not release readiness, feedback closure, or different-provider acceptance. After submission this worker is quiescent for exact-hash review; Root owns commits and push.
