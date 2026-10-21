# Independent code review

Provider: Antigravity/gemini-4-argon-high. Conversation: edc54041-8058-4303-a941-11d136022721. Scope: code only; no deletion/capacity proof.

Verdict: **REVISE**

This is a read-only code gate review of the inline script and tests. No cleanup, deletion, or capacity reclamation has been executed or proved.

### P1 Findings (Blocking Safety / Fail-Closed Defects)

1. **Manifest SHA-256 is never computed over the manifest content (`validate_manifest`, `digest`)**
   - `digest(v)` is defined on line 10 (`hashlib.sha256(stable(v)).hexdigest()`) but is never called anywhere.
   - `validate_manifest(doc)` only checks the self-reported JSON field `doc.get('manifest_sha256') != MANIFEST_SHA`. Any modified manifest with altered paths, inodes, devices, or byte counts passes validation as long as `"manifest_sha256"` is set to `MANIFEST_SHA` (which is why `CacheCleanupTest` passes synthetic rows with `'manifest_sha256': c.MANIFEST_SHA`).
   - **Required fix**: Compute the canonical SHA-256 over the manifest payload (e.g. `digest({k: v for k, v in doc.items() if k != 'manifest_sha256'})` or over raw manifest bytes, matching how `MANIFEST_SHA` was produced) and fail closed on mismatch. Also enforce that none of the 36 `cache_children` overlap the 9 archive roots if listed in `archive_prerequisite`.

2. **`builder-prune` mode has no active-build guard and no root filesystem mount check (`REMOTE_BUILDER`)**
   - Requirement: *"Shouldnotpruneanycurrentlyactivebuild-ownedcache"* and *"pinnedhost/dev/ext4"*.
   - `REMOTE_BUILDER` checks only `socket.gethostname()` before running `docker builder prune --all --force --filter until=1h`. An active build frequently depends on base or intermediate BuildKit cache layers created/used more than 1 hour ago, so `--filter until=1h` alone does not protect an in-flight build.
   - `REMOTE_BUILDER` does not verify `/` is `/dev/vda2` (`ext4`) via `findmnt`, does not run the parent-project `/proc` / container / K8s reference checks, and does not check `/proc` for active build processes (`docker build`, `buildx`, `buildctl`, `flutter`, `dart`).
   - **Required fix**: In `REMOTE_BUILDER` (or via a shared preflight), verify `/` is `/dev/vda2` (`ext4`), run the parent-project active-reference checks, and scan `/proc` to fail closed if any Docker/BuildKit/Flutter/Dart build process is active before executing `docker builder prune`.

3. **Bind-mount sources on `/dev/vda2` are missed in `/proc/<pid>/mountinfo` (`REMOTE_COMMON`)**
   - `REMOTE_COMMON` checks `if len((f:=line.split()))>4 and hit(f[4],root):`.
   - In Linux `/proc/<pid>/mountinfo`, `f[4]` is the mount point inside the process's mount namespace (e.g. `/app` or `/workspace`), whereas **`f[3]`** is the root path of the mount on the backing filesystem (`/dev/vda2`). If a container or process bind-mounts `/opt/ll/releases/<id>` or `/tmp/krug-<id>` onto `/app`, `f[3]` holds the project path and `f[4]` does not.
   - **Required fix**: Check both `hit(f[3], root)` and `hit(f[4], root)`, and also check `/proc/<pid>/environ` for `root.encode()` so processes referencing `FLUTTER_ROOT` or `PUB_CACHE` via environment variables are caught.

4. **Fresh-before-write / TOCTOU gap, post-execution receipt check, and missing parent/subtree guards (`REMOTE_COMMON`, `main`)**
   - **Post-execution receipt check**: `main()` checks `if a.receipt.exists(): raise SystemExit('receipt exists')` **after** `execute_cache(rows, True)` / `execute_builder(True)` has already deleted caches or pruned builder cache on the remote host. Verify `not a.receipt.exists()` and `a.receipt.parent.is_dir()` **before** any remote call.
   - **Fresh-before-write TOCTOU**: `REMOTE_COMMON` checks `os.lstat(p)` once at the start, then runs slow `/proc`, `docker inspect`, `crictl inspect`, and `kubectl get pods` scans, and then deletes `r['path']` without re-verifying `os.lstat(r['path'])` (`st_dev`, `st_ino`, `S_ISDIR`, `realpath == p`) immediately before each `rmdir`/`rmtree`. This is especially risky for `/tmp/krug-*` under `/tmp`.
   - **Subtree & parent preservation (`deletiononlycachechildnotparent`)**: `os.scandir(p)` only inspects depth-1 children and does not walk the subtree (`os.walk(p, followlinks=False)`) to verify no nested submount (`st_dev != r['device']`) exists inside `p`. After deletion, `REMOTE_COMMON` checks that `r['path']` is gone, but never verifies that `os.path.dirname(r['path'])` and `project(r['path'])` still exist with unchanged `st_dev`/`st_ino`.

---

### P2 Findings (Defense-in-Depth & Test Coverage)

1. **Re-enforce path allowlist and excluded releases inside `REMOTE_COMMON`**:
   - Re-validate `TMP_RE` / `OPT_RE`, `EXCLUDED_RELEASES`, and `len(rows) == 36` inside `REMOTE_COMMON` so the remote payload is self-defending even if called outside `main()`.
2. **Batch `docker inspect` / `crictl inspect` and normalize image set comparison**:
   - Calling `docker inspect <id>` and `crictl inspect <id>` once per container in a loop widens the TOCTOU window and risks hitting the 180s SSH timeout; pass all IDs in one batch (`['docker', 'inspect', *ids]`) if `ids` is non-empty, and also check `crictl pods -q` (`crictl inspectp`).
   - In `REMOTE_BUILDER`, sort `docker_images` and compare canonicalized/sorted `crictl images -o json` image entries so non-semantic ordering changes do not trigger a false abort after pruning while still failing closed on any image ID/tag/digest change.
3. **Expand unit tests (`TEST`)**:
   - Add tests verifying that tampering with any row's `path`, `inode`, `device`, or `allocated_bytes` fails `validate_manifest` even when `doc['manifest_sha256'] == MANIFEST_SHA`, that an existing `--receipt` aborts before invoking `ssh_python`, and that `mountinfo` `f[3]` bind-mount sources are detected.
