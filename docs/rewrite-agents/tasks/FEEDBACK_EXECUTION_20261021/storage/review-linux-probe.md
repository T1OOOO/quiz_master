# Bounded Linux restore code review

Provider: Antigravity / gemini-4-argon-high; conversation ac586e18-b71c-4d01-8886-c268eebd27c1.
Scope: verifier code only, not any actual source-tree deletion. Earlier file-reference-only attempt had empty response and is not counted.

Verdict: **ACCEPT**

Findings: **None (0 P1, 0 P2).**

### Review Assessment

1. **Does repacking original `TarInfo` PAX + bytes into chunks undermine proof or safety?**
   - **No.** `copy.copy(info)` with `format=tarfile.PAX_FORMAT` preserves the parsed `pax_headers` dictionary (including sub-second `mtime` and `SCHILY.xattr.*` attributes) and streams the exact member bytes from the read-only source archive (`source.extractfile(info)`).
   - Crucially, the verification target (`wanted`) is never derived from the repacked chunk headers: both the remote verifier (`REMOTE`) and local `send_chunk()` validate the extracted kernel filesystem state (`lstat`, `listxattr`/`getxattr` with `follow_symlinks=False`, `readlink`, and streamed file SHA-256) directly against the source manifest entries (`manifest['entries']`). If chunk repacking dropped or altered any PAX header, metadata field, or byte, `assert row == wanted` and `restored_sha256 == expected_sha` would fail closed.
   - The source archive on `E:/Backups/quiz-master/server-20261021` is opened read-only (`'r:*'`) and re-hashed after verification (`digest(archive) == archive_sha`), ensuring the persistent backup remains untouched.

2. **Does full reconciliation actually cover all entries?**
   - **Yes.** Reconciliation establishes an exact bijection between `manifest['entries']` and the members of `archive`:
     - `len(rows) != manifest['entry_count']` rejects manifest path collisions or count mismatches.
     - Every member in `source.getmembers()` must resolve under `root.name` (`member_path`), exist in `rows` (`name not in rows`), and appear at most once (`name in seen`), preventing both untracked archive members and duplicate members overwriting earlier ones.
     - Post-loop checks `seen != set(rows)` and `sum(x['entry_count'] for x in chunks) != len(rows)` ensure no manifest entry was skipped and every chunk's verified count and `restored_sha256` fingerprint matched.

3. **Archive path, metadata, and temp cleanup handling:**
   - **Path & symlink safety:** `member_path()` rejects absolute paths, `..` traversal, unexpected root prefixes, hard links (`LNKTYPE`), special files (`FIFOTYPE`, `CHRTYPE`, etc.), and entries exceeding `MAX_FILE_BYTES` (512 MiB). `verify()` precomputes all symlink paths from the manifest (`links`) and rejects any archive member whose ancestor is a symlink (`any(parent.as_posix() in links for parent in PurePosixPath(name).parents)`).
   - **Metadata fidelity:** `mode`, `uid`, `gid`, `mtime_ns`, sorted base64-encoded `xattrs`, regular file `size` + `sha256`, and symlink `target` are verified per entry; directory `size` is properly excluded from `projection()` as non-portable across filesystems (`tmpfs` vs disk fs). GNU `tar` runs with `--numeric-owner --same-owner --same-permissions --acls --xattrs --xattrs-include=* --delay-directory-restore`.
   - **Bounded resource & temp cleanup:** Remote execution pins `socket.gethostname() == 'racknerd-f0269d5'`, confirms `/dev/shm` is `tmpfs`, checks `MemAvailable > 1 GiB + 2 * logical_bytes + len(expected) * 4096` and `/dev/shm` available bytes before creating `tempfile.mkdtemp(prefix='quiz-archive-verify21-', dir='/dev/shm')`, and unconditionally removes the scratch directory in `finally:` after asserting its parent and prefix. Local chunk staging uses `tempfile.TemporaryDirectory` under `DESTINATION`, unlinks each chunk after transfer, and writes the receipt exclusively (`open('x')` + `os.fsync`).
