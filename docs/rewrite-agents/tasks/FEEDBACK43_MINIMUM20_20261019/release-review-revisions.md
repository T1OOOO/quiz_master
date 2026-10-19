**Verdict: REVISE**

### Reviewed Scope & Limits
- **Reviewed files (read-only via `view_file`)**:
  - [`release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py) (555 lines)
  - [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py) (87 lines)
  - [`test_release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/test_release_executor.py) (60 lines)
  - [`rehearse.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py) (295 lines) & [`test_rehearse.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/test_rehearse.py) (36 lines)
  - Compared against [`FEEDBACK43_BONES_20261019/release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/release_executor.py) (588 lines) for guard preservation.
- **Scope limit**: Static controller/packager/test review only. No runtime proof, live Linux candidate rehearsal, image build, or production publication is claimed.

---

### What Was Verified as Preserved / Fixed
- **Baseline 69 / Deployment 67 / PVC pins**: [`release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L20-L35) and [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py#L21-L25) pin `racknerd-f0269d5` (`192.3.164.184`), Helm revision `69`, deployment revision `67`, build `quiz-2026.10.19-bones-36e0b68c`, digest `sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a`, baseline API SHA `208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa`, and PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`.
- **Deep guards restored from `FEEDBACK43_BONES_20261019`**: `DEPLOY.lock` flock, `node_guard` (`Ready=True`, `DiskPressure=False`, schedulable, no `NoSchedule`/`NoExecute` taints, containerd imagefs $\ge 20\%$ free blocks before/after), `/opt` byte headroom calculation, `nginx -t` check, `nginx.conf` byte comparison, live vs rendered Helm manifest normalization diff (only `image` and `quiz-master/build-id` change), SQLite `.backup` + `restore-proof.sqlite` `pragma integrity_check`, disposable rehearsal DB bind-mount, canonical CRI `k3s ctr` + `crictl inspecti` verification before publish, `prepared-receipt.json` vs `reviewed-receipt.json` binding, `post_upgrade_err` ERR-trap rollback to revision `69`, and `feedback_reports` before/after row digest verification ([`release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L236-L452)).
- **Recent `prepare_package.py` fixes**: `go version -m` provenance check (`GOOS=linux`, `GOARCH=amd64`, `vcs.revision`, `vcs.modified=false`) at [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py#L26-L36), `js.read_bytes()` check at [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py#L50-L52), and `next/apps/quiz_app/assets/catalog.json` (105 packs / 4,520 questions) copy at [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py#L75-L78).

---

### Actionable Defects Requiring Revision

1. **`FileNotFoundError` on the 4 `BASELINE_ONLY` files when writing `quiz-closure.json` ([`prepare_package.py:83`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/prepare_package.py#L83))**
   - Line 60 properly intersects `set(base) & set(source_tree)` to skip `BASELINE_ONLY` (`Nature/analyze_granular.py`, `Nature/audit_balanced.py`, `Nature/fill_gaps.py`, `Nature/finalize_granular.py`), which exist only in `base_root` and not in `qroot` (`s/'quizzes'`).
   - However, line 83 computes:
     ```python
     'unchanged_source_lf_normalized': {rel: normalized(qroot/rel) for rel in sorted(set(base)-EXPECTED_MUTATED)}
     ```
     Because `set(base) - EXPECTED_MUTATED` still includes the 4 `BASELINE_ONLY` paths absent from `qroot`, `normalized(qroot/rel)` raises `FileNotFoundError` on `qroot / 'Nature/analyze_granular.py'`.
   - **Fix**: Filter out `BASELINE_ONLY` on line 83 (e.g., `for rel in sorted((set(base) & set(source_tree)) - EXPECTED_MUTATED)`), and record `baseline_only` separately if desired.

2. **`private/` tree (`private/quizzes` and 4 `private/study/drafts`) is omitted from local input validation, `release-inputs.json`, and remote checksum verification ([`release_executor.py:168-181`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L168-L181), [`release_executor.py:270-282`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L270-L282))**
   - `stage_package` ([`release_executor.py:476`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L476)) archives `private`, and `remote_script` ([`release_executor.py:362`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L362)) passes `--private-quizzes-root "$stage/private"` to `rehearse.py`, which reads `private/quizzes/...` and the 4 draft files under `private/study/drafts/feedback43-*.json` ([`rehearse.py:133, 193, 209, 214`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/rehearse.py#L133)).
   - However, [`collect_inputs`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L168-L181) never validates `package / "private"`:
     - It does not verify `hash_tree(package / "private/quizzes") == candidate` (`hash_tree(package / "quizzes")`).
     - It does not verify the 4 draft files exist under `package / "private/study/drafts"`.
     - It does not include `"private": hash_tree(package / "private")` in `manifest` (`release-inputs.json`), and [`remote_script`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L279) does not verify `'private': tree('private')` against `release-inputs.json`.
   - **Fix**: In `collect_inputs`, require `hash_tree(package / "private/quizzes") == candidate`, require the 4 draft files under `package / "private/study/drafts"`, bind `"private": hash_tree(package / "private")` in `manifest`, and verify `'private': tree('private')` in `remote_script` line 279.

3. **Container file/directory permission hazard under `umask 077` + Windows tar ([`release_executor.py:45-53`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L45-L53), [`release_executor.py:209-223`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L209-L223))**
   - `remote_stage_script` sets `umask 077` and runs `tar -xf - -C "$stage" --no-same-owner --no-same-permissions`. When `stage_package` creates the tar stream on Windows, POSIX execute bits on `api` are not guaranteed, and `--no-same-permissions` under `umask 077` strips group/other bits (`0600`/`0700`) on `$stage/api`, `$stage/quizzes`, and `$stage/web`.
   - `FRONTEND_DOCKERFILE` ([`release_executor.py:45-53`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L45-L53)) copies `api`, `quizzes/`, and `web/` directly into the image without ensuring `/app/api` is `0755` (`chmod 0755 /app/api`) or `/app/quizzes` and `/usr/share/nginx/html` have readable/traversable permissions (`chmod -R a+rX`).
   - **Fix**: Explicitly set `chmod 0755 /app/api` and `chmod -R u=rwX,go=rX /app/quizzes /usr/share/nginx/html` in `FRONTEND_DOCKERFILE` (or normalize modes in `$stage` after `tar -xf`).

4. **`collect_inputs` does not validate `catalog.json` content and `test_release_executor.py` uses invalid/empty fixtures ([`release_executor.py:170-180`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/release_executor.py#L170-L180), [`test_release_executor.py:11-26, 55-58`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/test_release_executor.py#L11-L26))**
   - `collect_inputs` only checks `(package / "catalog.json").is_file()` without verifying that `catalog.json` is a 105-pack / 4,520-question list (`min >= 20`).
   - In [`test_release_executor.py:11, 26`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/test_release_executor.py#L11), `private/quizzes` and `private/study/drafts` are empty directories and `catalog.json` is `'[]'`, and `test_prepare_builder_is_clean_api_and_private_tree_only` ([`test_release_executor.py:55-58`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/test_release_executor.py#L55-L58)) only searches source substrings instead of running `prepare_package` on a fixture with the 4 `BASELINE_ONLY` files.
   - **Fix**: Populate `private/quizzes` and `private/study/drafts` in `Minimum20ReleaseTest.setUp`, validate `catalog.json` in `collect_inputs`, and add a functional test exercising `prepare_package`'s closure construction (including the 4 `BASELINE_ONLY` files).
