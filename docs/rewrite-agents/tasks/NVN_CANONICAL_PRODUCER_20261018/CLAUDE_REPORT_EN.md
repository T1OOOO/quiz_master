# Independent review: changed canonical NVN producer (task-ee9fff0e84db45d1bec244612004c5a0)

**Requirements compliance: PASS. Code quality: PASS.** Verdict submitted as `accept`, `error_count` 0, with 4 non-blocking advisories. Session is IDLE.

## Scope and integrity

Read-only throughout. No edits, no SSH, no collector execution, no package/archive/prepare/verify operation, no build, no browser, no cleanup, no children, no publication. The only writes were the focused unittest's own disposable fixtures and my probe's `tempfile.TemporaryDirectory` under `.run/heartbeat_20261018_0327/worker/`, both self-cleaned; `git status` shows the packet wholly untracked with nothing modified.

Rehashed independently, **0 mismatches**:
- `review-inputs.json` raw bytes = `82791938e1b6c3ec…44908e` — matches the stated value.
- All **70 listed files**, including the 26-file `first-review/files/` snapshot.
- All **165 frozen pins** in `scope.json`.
- Current source `204dc9ac…890c`, tests `5bce7a1c…3421`, contract `54762bb7…1732`, collector `0670abe7…4404`, inventory `df86b068…a484`.
- The three historical contract pins verify against disk: verifier `9f6606f7…`, historical review-inputs `e0b721c8…` (74 entries — the report's "74-file" claim is accurate), historical acceptance `b6bc9697…`.

## Bindings

`current-contract.json` has `source_task` = task-ee9f and `current_input_task` = task-dfaf; `root_contract_raw_sha256` = `0793e4fc…` matches the updated `CONTRACT_EN.md`; `collector_raw_sha256` is pinned in both the contract and the source constant and triple-compared at `prepare_canonical.py:154`. Via the hub: **task-ee9f is SUBMITTED**, assignee `session-f9fa69…` (codex) — I am a different provider, so this is a valid independent gate; **task-dfaf is NEW, unassigned, with zero offers** — not reviewed, not accepted. task-2297 is ACCEPTED but its recorded result binds the *old* collector `abe99d84` and *old* contract `233f181d`, which confirms concretely that the first acceptance does not cover these bytes.

`diff` against the first-review snapshot is **exactly the seven described changes** — nothing smuggled in.

## Root's blocking finding: reproduced, then verified fixed

I did not take the earlier acceptance or the green suite at face value. I traced the chain first: `base` is the frozen COUNTRY483 module, whose `verify_acceptance` (`prepare_country483.py:98`) uses loose `args.get('error_count') == 0` — that is the real root cause, and `False == 0` is why the any-row precheck was insufficient. `require_actual_acceptance` only checks the claimed `actual_hub_state`, so it offers no protection.

The fix filters the copied proof's `actual_reviews` to integer-typed zero rows for the same task *before* handing it to the inherited validator (`type(...) is int` correctly excludes `bool`). I then ran Root's exact mixed row against the real `acceptance()` and the real inherited helper:

| Fixture | Result |
|---|---|
| **int0/rework + boolFalse/accept, same task** (Root's exact row) | REFUSED — `RuntimeError: actual task-bound independent acceptance is missing` |
| lone boolFalse/accept | REFUSED — `integer zero task-bound review required` |
| True/accept + int0/rework | REFUSED |
| int0/accept on a *wrong* task + int0/rework on the right one | REFUSED |
| int0/accept with `reviewer == assignee` | REFUSED |
| boolFalse/**rework** + int0/accept | ACCEPTED (correct — the accepted row carries genuine int 0) |
| genuine int0/accept | ACCEPTED (not over-rejecting) |

The refusal message matches Root's `root-mixed-callback-fixed.json` exactly, so the refusal is for the right reason: the filter removes the bool-accept row and the inherited validator then finds no accepted callback. Integer zero is now bound to the **same** accepted callback, and the inherited verdict/state/task/reviewer≠assignee checks all still fire. `red-mixed-callback.txt` is genuine behavioral RED ("not raised" against the pre-fix source), not a bootstrap artifact.

One point in the fix's favour that the report undersells: COUNTRY483's own `verify_inputs` acceptance reads and `prepare_nvn.py:207` are bypassed by the `base.verify_inputs = lambda: pins` override and only ever touch digest-pinned historical records, so the two `acceptance()` calls in `authorize()` are the **only** gate reached by new incoming files. The filter is therefore at the correct and complete chokepoint. Since COUNTRY483 is immutable under `LEGACY_SHA`, fixing it at the source would break every historical pin — filtering at the boundary is the right minimal fix, not a workaround.

## Suite and other boundaries

Executed the complete focused suite myself: **17/17 OK, exit 0, 7.395s** (Root 17/9.341s, native 17/8.197s — separate executions, consistent). Recorded refusal logs reference line numbers 203/204/232/254/258 that match the current bytes, so they were produced against these exact files.

Verified by inspection: strict positive-integer disk with `available*5 > total` and bool refused; UTC age 0..1800 inclusive; Helm 64 / two pinned images / one replica / named PVC / readiness 200 / feedback 43+digest / backup+independent-restore 0600/integrity identity; exact raw script/stdout/receipt/certificate/manifest bindings via `bind()`'s exact key-set and path check; raw canonical no-link/single-link paths; stage-root junction refusal before `rglob`; inherited 332-member/seven-delta/prepare-only controls. Contract schema/source/build/count are now read and validated and supply the operative 43 constants in both the current-baseline function and the shell preflight. The collector emits raw conditions/taints/unschedulable/open-count/both integrity results/modes, and the validator recomputes the derived flags with identity (`is`) comparisons that fail closed on a missing key. Collector inspected only — never run.

Confirmed absent: source/current acceptance files, current manifest/certificate/captures, any `.tar.gz`, any publication. Root's observed **15.342% disk still fails strict >20**, and this source-only review does not waive it. The two acceptance gates remain separate different-provider gates in both branches. The double historical load is explained by the short provenance comment at line 77 — and it is in fact mildly beneficial, since `verify()`'s pristine namespace is discarded rather than retargeted.

## Non-blocking advisories

1. **`acceptance()` ignores the `fixture_only` marker.** The test's synthetic `source-acceptance.json` binds the *real* `sources()` hash map, the *real* `CONTRACT_SHA` and the *real* source task — only its temp-dir location keeps it inert. A one-line refusal of any proof carrying `fixture_only` (or an exact key-set requirement) makes "synthetic fixtures are not acceptance" structural rather than positional. Cheapest real hardening available; the current-input gate is not similarly exposed, since it needs digests of files that do not exist.
2. **The mixed-callback regression asserts `assertRaises((ValueError, RuntimeError))`** — broad enough to pass if refusal ever came from an unrelated earlier guard. `assertRaisesRegex(RuntimeError, 'task-bound independent acceptance')` would pin the behaviour I verified by hand.
3. **`reviewer_provider` is self-declared** and whitelisted against a hard-coded `('claude','antigravity')` rather than checked against the actual assignee's provider; the inherited `reviewer != assignee` compares session IDs, which does not prove different providers. Today's intent holds because the assignee is codex. Worth tightening before the dfaf current-input gate.
4. **The loose `error_count == 0` remains in frozen COUNTRY483.** No live exposure now, but any successor reusing that helper without re-applying the filter re-inherits the bug — worth recording in `CONTRACT_EN.md`.

Minor, not worth a change: the filter does not itself check `call['action'] == 'review'` (the inherited validator does), and the collector reads `response.status` after its `with` block closes (works, since the attribute is cached). The fail-closed `KeyError` style stands as previously agreed; note only that `refused()` catches `(ValueError, RuntimeError, FileNotFoundError)`, so a missing-key case would surface as a test error rather than a pass — fail-closed either way.