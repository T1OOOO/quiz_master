# Проверка идентичности базового образа

Antigravity / Gemini 4 Argon High, разговор `63c344dc-6bfe-4f90-9e30-6c61d8963624`.

Журнал SHA256: `c7027cc51f6fef7068038ff15ae019aa4773700abc130ab03d7ccf0f77af225a`.

**Verdict: `ACCEPT`**

### Bound Artifacts & Hashes
- **Corrected Executor (`release_executor.py`) SHA-256**: `f0ca5d1e4ae32c9aa48e4fc3c1783bc2c02a769a4ed4f578e16601cfe3ffeb49`
- **Target Build**: `quiz-2026.10.21-feedback-0c536221` (frozen application `0c536221`)
- **Staged Input Manifest (`release-inputs.json`) SHA-256**: `ca89b956a2512508487829d169bc2522fefb68932f3f0f00cb196a2de70dc384`
- **Baseline Image Identity Chain**:
  - OCI Index / Docker `.Id` & `.Descriptor.digest`: `sha256:088725db5d3cc0c03031d394094076bda15366c5951a67c47501b05e5cbd6a01`
  - OCI Manifest Digest: `sha256:342a2e4e4fe358267219a86100f6f760d70fdf8767e9ce017fe13a77aa62f23b`
  - OCI Config / CRI Image ID: `sha256:77435bd5b01c318c08fb2547ed945eac9b16c0fb44bf4bbb9a8c250f15f792d3`

---

### Independent Review Findings

1. **Exact Baseline Image Identity Chain (No Weakened Trust)**:
   - On the Docker OCI store host, `docker image inspect --format '{{.Id}}'` and `.Descriptor.digest` both resolve to the OCI index digest (`sha256:088725...`).
   - Rather than loosening the guard or trusting tags, [release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release/release_executor.py) now pins the complete cryptographic chain across both daemons:
     1. Docker `.Id` and `.Descriptor.digest` == `BASE_OCI_INDEX_DIGEST` (`sha256:088725...`).
     2. `k3s ctr -n k8s.io images ls` ref `docker.io/library/quiz-master:quiz-2026.10.20-lazy-2af0ab3f` == `BASE_OCI_INDEX_DIGEST`.
     3. `k3s ctr -n k8s.io content get <index>` contains `BASE_OCI_MANIFEST_DIGEST` (`sha256:342a2e...`).
     4. `k3s ctr -n k8s.io content get <manifest>` has `config.digest` == `BASE_DOCKER_CONFIG_DIGEST` (`sha256:77435b...`).
     5. `k3s crictl inspecti` for `@<index>` has `status.id` == `BASE_DOCKER_CONFIG_DIGEST` (`sha256:77435b...`).

2. **Shell Quoting Fix & Unit Test Coverage**:
   - Replacing `{...!r}` (which emitted nested single quotes inside a single-quoted `python3 -c '...'` bash argument and had its quotes stripped by the shell) with `{json.dumps(...)}` emits double-quoted JSON string literals that survive bash single-quoting intact.
   - `test_oci_identity_inline_python_survives_shell_quoting` in [test_release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release/test_release_executor.py) parses all 3 generated guard lines with `shlex.split` and compiles the extracted `-c` payload, preventing regression.
   - The previously accepted `findmnt -T` mount-target resolution fix (`7b30595c`) and its unit test remain intact.

3. **Exact-Stage Prepare Recovery Runner Safety**:
   - The prior `prepare` run aborted cleanly at the baseline Docker ID check before creating any container/image, DB backup, or stage checkpoints.
   - The private recovery runner verifies the exact executor hash (`f0ca5d1e...`), local package identity, and manifest hash (`ca89b956...`), then asserts via a read-only remote probe that `/opt/quiz-master/releases/quiz-2026.10.21-feedback-0c536221` is a root-owned `0700` non-symlink directory with matching `release-inputs.json` and zero generated artifacts/backups/candidate images.
   - It then executes the unmodified `remote_script(build, r.API_SHA256, 'prepare', input_manifest_sha256=digest)` with all host, lock, node, capacity, reserve (`1271337`), Helm 78 / Deployment 76, PVC, input checksum, build, backup, and rehearsal HTTP grading guards active, and stops after `prepare` so independent rehearsal review remains mandatory before `publish`.

Уточнение вызова: для стандартной фазы `prepare` приватный runner вызывает `remote_script(build, API_SHA256, "prepare")` без параметра `input_manifest_sha256`, который API функции допускает только для `resume-prepare`. Локальный и удалённый хэши подготовленного манифеста проверены отдельно; все проверки внутри стандартного скрипта сохраняются.
