Review complete and submitted. IDLE.

## Two verdicts

**Requirements compliance: PASS**
**Code quality: PASS** — 4 non-blocking findings, 0 blocking.

`task-2297f109bc014e68bbe0f88d7675f9d5` → **accept**, `error_count=0`, state ACCEPTED, reviewer my session (≠ assignee `session-a14b05e6`/codex). `task-dfaf1b322def4adfbc2f08a91082591b` **not reviewed** — no current manifest/certificate/collector run exists.

## What I verified myself (not taken on claim)

| Check | Result |
|---|---|
| `review-inputs.json` raw sha256 | `2239c0d5…9261` ✓ |
| 26 declared hashes | 26/26 match; re-hashed post-test 26/26 identical |
| Frozen packets (6) | `git status` empty — byte-identical |
| Foreign WIP | 178 = 157 mobile deletions + 21 others; −`.beads/issues.jsonl` = **177** ✓ |
| Focused tests | `14 OK exit 0`, 5.381s (Root: 5.956s) |
| `bash -n` collector | exit 0, empty output (`e3b0c442` = empty-file sha) ✓ |
| Collector embedded Python | `compile()` OK, **not executed**; zero mutating tokens; no raw rows/PII |
| Count provenance | 17 pins / 103 runtime / **74+74=148** compiled / historical 29 — all derived |
| Forbidden files | all 6 absent; no `nvn-5c5a5d9*` archive under `.run` |

Both CLI branches gate: `blocked-prepare.txt` and `blocked-verify.txt` are **byte-identical**, exit 1 at `prepare_canonical.py:184` before any path is touched. `-O` refused at `:183` via `require()`, not `assert`.

Notably, the controller *fixes* two latent weaknesses it inherited rather than inheriting them: `require_actual_acceptance` uses `!= 0` and country483's `verify_acceptance` uses `error_count == 0` — both accept `False`. `prepare_canonical.py:119,122` add `type(…) is int`, and the `exit_bool` subtest proves it.

## Findings (all non-blocking)

1. **`current-contract.json:2,7,8,9`** — `schema_version`/`source_commit`/`build_id`/`feedback_count` are never read. The operative 43 is hardcoded at `:172,:194`; manifest identity checks `n.SOURCE`/`n.BUILD` at `:142`. A file presented as "the fixed contract" can state what it doesn't bind. Held in check by `CONTRACT_SHA` being inside `source_bindings`. Fix: derive the literals from the contract plus one `require()` on build identity/schema.
2. **`current-baseline-readonly.sh:40-41`** — `node_ready`/`disk_pressure`/`blocking_taints`/`all_open`/`backup_integrity`/`mutation` are hardcoded booleans emitted *after* their asserts, so the verifier can't recompute them; only the disk gate is recomputed from raw integers. For `task-dfaf`: emit raw `conditions`/`taints`/`integrity_check`/open-count and recompute, following the disk gate's pattern.
3. **`:163-164,:219`** — `certificate['observed_at_utc']` and `record['archive']` indexed unguarded → `KeyError` not `ValueError`. Fails closed; message quality only.
4. **`:74-75`** — `adapted()` runs twice (also inside `verify()`); the instance used for `prepare` never passes `validate_inputs`, and `:192` swaps `verify_inputs` for pre-read pins. Equivalent in result, but a reader can't see that.

**RED evidence is mixed:** `red-initial.txt` is bootstrap-only ("can't open file" — the controller didn't exist yet), not behavioral. `red-stage-root.txt` *is* a genuine behavioral RED — the Windows junction stage root was accepted, `ValueError not raised`, 11 others passing — and `output_boundary(stage)` is the smallest correct fix.

I did not run `--prepare`/`--verify`, the collector, or `-O`; no files were edited, and the acceptance is scoped to changed-source/contract quality only — not release readiness. The 15.342% disk FAIL stands, so a passing current certificate remains impossible.