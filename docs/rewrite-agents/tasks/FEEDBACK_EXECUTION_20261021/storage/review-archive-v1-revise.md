# Independent code review

Provider: Antigravity/gemini-4-argon-high. Conversation: 4a70cf94-db86-416e-a5df-721ae22885ac. Scope: code only; no deletion/capacity proof.

**Verdict: `REVISE`**

*(Scope note: Read-only inline code review only; no tools, files, or commands were executed. This review evaluates the orchestrator code gate only and is not source-deletion approval.)*

---

### P1 Findings (Blocking Destructive-Safety & False-Open Issues)

1. **`REMOTE_GUARD` misses bind mounts of release trees in `/proc/<pid>/mountinfo` (False-Open Reference Scan)**
   - **Location:** `REMOTE_GUARD` (`for line in open('/proc/'+pid+'/mountinfo', ...): fields=line.split(); if len(fields)>4 and hit(fields[4]): ...`)
   - **Issue:** In Linux `/proc/<pid>/mountinfo`, `fields[4]` is the **mount target** inside the process's mount namespace (e.g., `/app` or `/var/lib/kubelet/pods/...`), whereas `fields[3]` is the **mount root within the source filesystem** (e.g., `/opt/ll/releases/<release>` on `/dev/vda2`). If a container, pod, or namespaced service bind-mounts a release tree to another target path, `hit(fields[4])` is `False`, and any open `fd`/`cwd` inside that namespace resolves against the target mount path rather than `/opt/ll/releases/...`.
   - **Fix:** Check `hit(fields[3]) or hit(fields[4])` (decoding `\040` octal escapes if present), and also check `/proc/<pid>/exe` (`os.readlink(base+'/exe')`) and `/proc/<pid>/maps` so running binaries or `mmap`'d files whose file descriptors were closed after `execve`/`mmap` are detected.

2. **`verify()` does not verify manifest integrity, `root == path`, or `load_allowlist()`, and fails open when receipt args are `None` (False-Open Restore/Verify Gate)**
   - **Location:** `verify()` and `receipt_gate()`
   - **Issues:**
     - Unlike `archive()`, `verify()` trusts `doc["manifest_sha256"]` and `doc["entry_count"]` directly from disk without recomputing `sha_json({k: v for k, v in doc.items() if k != "manifest_sha256"})`, without checking `doc.get("entry_count") == len(doc.get("entries", []))`, without checking `doc.get("root") == path` or `doc.get("host") == HOST`, and without checking `path in load_allowlist()`.
     - `verify()` accepts `linux_receipt: pathlib.Path | None` and `independent_review: pathlib.Path | None`. If called with `(None, None)`, both `if linux_receipt and independent_review:` and `elif linux_receipt or independent_review:` evaluate to `False`, bypassing `receipt_gate()` completely.
     - `receipt_gate()` does not bind `"root": path` or `"host": HOST` in `required`.
   - **Fix:** Make `linux_receipt` and `independent_review` non-optional in `verify()`, enforce `path in load_allowlist()`, `doc.get("host") == HOST`, `doc.get("root") == path`, `doc.get("entry_count") == len(doc["entries"])`, and recompute `sha_json` of `doc` in `verify()` before calling `receipt_gate()`.

3. **`ARCHIVE_ROOT` is unused dead code — off-host archive location (`E:/Backups/quiz-master/server-20261021`) is never enforced (Wrong Scope)**
   - **Location:** `ARCHIVE_ROOT = pathlib.Path(r"E:/Backups/quiz-master/server-20261021")`, `archive()`, `verify()`, `main()`
   - **Issue:** `ARCHIVE_ROOT` is defined at line 28 and never referenced anywhere. `archive()`, `verify()`, and `delete` will accept an archive path in a scratch/local temp directory outside the user-approved off-host backup root `E:/Backups/quiz-master/server-20261021`.
   - **Fix:** Validate that `destination.resolve()` / `archive_path.resolve()` is a child of `ARCHIVE_ROOT.resolve()` in `archive()`, `verify()`, and `delete`.

4. **`REMOTE_DELETE` / `REMOTE_GUARD` lack remote-side allowlist and `realpath` enforcement before `shutil.rmtree(path)` (Wrong Scope / Defense-in-Depth)**
   - **Location:** `REMOTE_GUARD`, `REMOTE_DELETE`
   - **Issue:** `REMOTE_DELETE` runs as `root` on `racknerd-f0269d5` and executes `shutil.rmtree(path)` using `request['path']` from stdin without checking `path in PINNED_PATHS` or `os.path.realpath(path) == path` on the remote host (unlike `REMOTE_INVENTORY`, `REMOTE_GUARD` only checks `os.path.islink(path)`, which does not catch an ancestor symlink swap on `/opt/ll` or `/opt/ll/releases`). Additionally, `REMOTE_DELETE` concatenates `REMOTE_GUARD` + delete print statements, emitting two separate JSON lines to stdout, and `main()` ignores `REMOTE_DELETE`'s stdout.
   - **Fix:** Embed the exact 9-path tuple in `REMOTE_GUARD` / `REMOTE_DELETE`, enforce `path in PINNED_PATHS` and `os.path.realpath(path) == path` and `stat.S_ISDIR(s.st_mode)` inside the remote payload before `shutil.rmtree(path)`, and also scan `/opt/ll` symlinks and `/etc/systemd/system` unit files for references to `path`.

---

### P2 Findings (Metadata, Post-Tar Consistency & Test Adequacy)

5. **`archive()` does not verify tar path set against manifest, re-check post-tar source manifest, or clean up partial archive on failure**
   - **Location:** `archive()`
   - **Issues:**
     - `count, _ = safe_tar_members(destination, base)` ignores `_` (`names`) and does not check `count == doc["entry_count"]` or `set(names) == expected_paths`.
     - `archive()` checks `fresh` *before* streaming `tar`, but does not re-check source manifest SHA *after* `tar` completes to guarantee no file mutated while `tar` was reading.
     - If `subprocess.run` fails mid-stream inside `with destination.open("xb") as output:`, a partial `.tar.gz` file is left at `destination`.
   - **Fix:** Stream to `destination.with_suffix(destination.suffix + ".part")`, verify `set(names) == expected_paths`, re-verify post-tar inventory SHA (or require it before finalizing), and atomically `os.replace` to `destination` (unlinking `.part` on exception).

6. **`safe_tar_members()` allows hardlink/unknown tar member types and does not normalize PAX directory trailing slashes**
   - **Location:** `safe_tar_members()`
   - **Issues:**
     - Only checks `if member.isdev() or member.isfifo():`, which lets `member.islnk()` (tar hardlink type `LNKTYPE`) or unknown tar header types pass instead of enforcing `if not (member.isreg() or member.isdir() or member.issym()):`.
     - When GNU `tar --format=pax` emits a PAX `path` extended header for a long directory path (>100 bytes), Python's `tarfile` applies the PAX `path` override *after* `frombuf()` strips trailing `/`, leaving a trailing `/` on `member.name` (`tree/long_dir/`) that will mismatch `expected_paths` in `verify()`.
   - **Fix:** Reject any member where `not (member.isreg() or member.isdir() or member.issym())`, reject raw `member.name` with trailing `/` on non-directories, and normalize directory member names via `.rstrip("/")` after rejecting empty/root escapes.

7. **`TEST` coverage is insufficient for destructive-safety gates**
   - **Location:** `ArchiveSafetyTest`
   - **Issue:** The 3 unit tests only cover `../` traversal, a 2-member prefix check, and a single `archive_sha256` mismatch in `receipt_gate`.
   - **Fix:** Add unit tests covering:
     1. `verify()` rejecting a tampered manifest whose body differs from `manifest_sha256`, or whose `root` != `path`, or where `path` is outside `PINNED_PATHS`.
     2. `verify()` rejecting missing receipts (`None`) and `receipt_gate()` rejecting a tampered `receipt.json` when `review.json`'s `restore_receipt_sha256` no longer matches `sha_file(receipt_path)`.
     3. `safe_tar_members()` rejecting `/abs/path`, sibling prefix escapes (`tree2/file`), hardlink/device/FIFO members, and `verify()` rejecting extra/missing tar members relative to `doc["entries"]`.
     4. `load_allowlist()` rejecting any deviation from `PINNED_PATHS` and `ARCHIVE_ROOT` enforcement rejecting paths outside `E:/Backups/quiz-master/server-20261021`.
