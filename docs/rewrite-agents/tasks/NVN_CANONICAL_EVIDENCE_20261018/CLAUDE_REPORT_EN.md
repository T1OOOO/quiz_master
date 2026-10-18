# Independent Review — NVN_CANONICAL_EVIDENCE_20261018

**Verdict: ACCEPT.** Requirements compliance PASS, code quality PASS, `error_count = 0`, four non-blocking advisories. Recorded on `task-d6fc7bef25a04407b57330354e7c464e`. Session IDLE. No files edited, nothing regenerated, no children.

## Input integrity

| Check | Result |
|---|---|
| `review-inputs.json` raw SHA256 | `e0b721c8…829c` ✓ matches the frozen pin |
| 74 listed files rehashed | all match; only Root-owned packet docs are extra |
| 79 `scope.json` frozen pins rehashed | all unchanged |
| git status of old packets | zero modifications in `NVN_RELEASE_20261016`, `NVN_FOOTER_20261016`, `COUNTRY483_RELEASE_20261015` |
| Old source/test/input pins | `3942ba48` / `66ea3ab8` / `931b441a` confirmed on disk |

## Reproduced, not taken on trust

- `verify_historical.py` → exit 0, `PASS_HISTORICAL_EVIDENCE_ONLY`, 17 pins / 103 runtime / 148 compiled.
- `unittest discover` → 12 tests, exit 0 (3.075 s here).
- Both compiled trees walked independently: 74 + 74 = 148.

**I did not accept because tests pass.** I structurally diffed old vs new `runtime-proof.json` and `release-inputs.json`. The only deltas are path rebinding `C:\ap\quiz_master` → canonical `E:`, the two manifest digest updates (`7827d915`→`be19804c`, `23bbf70f`→`1f51ed6d`), and an added `sha256_semantics` key. No screenshot dropped, no command count, exit, identity field or schema weakened. 58 evidence copies are byte-identical to the old packet; exactly 3 metadata files regenerated; `migration-map.json` has 117 rows (17 + 103 + 1, four proof/runtime overlaps collapsed), 114 `unchanged_bytes` with `old == new` hash, 3 `canonical_binding_metadata`, no renamed basenames. Captured receipts still carry their original C-drive command strings, and historical 29 OPEN / 23.856% is untouched.

## Guards are live, not vacuous

`C:/ap/quiz_master` **is** a real junction to `E:\Projects\quiz_master` on this host, so I bound a byte-identical, correct-hash alias of `NVN_FOOTER/production-build.json` through it. Refused by the new binder (`canonical evidence path required`) **and** by the original pinned `bound()`; the canonical E-drive equivalent is accepted. An aliased proof inside full `validate_inputs` is refused, as is a non-canonical `..` path. Critically, `historical()` never resolves the stale `entry['path']` at all — it rebinds by relative key, so no untrusted alias is resolved-then-trusted on the verify path.

`validate_manifest` enforces exact dict equality against the destination-mapped 103-entry closure, so omission, addition and same-count replacement all fail. The four lifecycle reads (`close`, `identity-capture`, `exact-daemon-cleanup`, `fixture-cleanup`) now route through `member_read`, which requires manifest membership before reading — this closes the prior Claude review's advisory. The `fixture-source` normalized-text vs raw-byte correction is disclosed and old bytes are unchanged.

## No packaging reachable

`main()` requires `len(sys.argv) == 1`, refuses `-O`, has no argparse, and `verify_historical.py` contains no write/mkdir/subprocess/shutil. `base.prepare`/`base.verify_package` do get exec'd into the isolated namespace by the reused `implementation()`, but no code path reaches them. `migrate_evidence.py` is gated by `migration destination must not exist` before `mkdir()` — verified it exits non-zero with `release-inputs.json` unchanged.

## Advisories (none blocking)

1. `evidence/runtime-proof.json` is anchored only by digest plus the inherited semantic `require`s. Nothing machine-checks "new == old modulo path rebinding" — I verified it by hand. A short structural assertion in `validate_mapping` would make that reproducible.
2. `migrate_evidence.py:41` calls `Path(value['path']).resolve()` before validating — the one place resolution precedes the raw-path guard. Bounded (known-membership + declared sha, generator-only, output strictly re-checked) and off the verify path, but it deserves an explicit comment.
3. `verify()` reports `compiled_files=148` and `historical_feedback_count=29` as literals rather than derived values. Both are enforced elsewhere (74×2 in `verify_builds`, 29 in `verify_baseline`), so not fabricated — just opaque to a reader.
4. Root metadata nit: `review-inputs.json` `unittest_reported_seconds: 3.301` contradicts the worker's own `tests.txt` ("Ran 12 tests in 4.577s") and `tests.json` elapsed 4.801.

## Scope held

Nothing here certifies current capacity (live 15.413% **fails** strict >20%), 43 OPEN feedback, candidate, deployment, Android, whole-bank facts, or any fresh browser/runtime execution. No source acceptance, archive, publication or release readiness is approved. The `require`/`sha`/`read` duplication in the new module is bootstrap-necessary (needed before the old module loads); `checked_file` overlaps `bound` but is strictly stronger and runs pre-import. I found no unnecessary abstraction and no genuine unsafe boundary.