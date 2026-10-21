# Независимая проверка локального Linux transport

Conversation 68d0567a-d9b9-40ca-a281-775e336579e9; официальный Antigravity CLI. Источник91fb76eca48bdaef94401f693284280375ed3b7647952862b2b3152de7cba0e0.

**Verdict: ACCEPT**

### Material Findings & Assessment

1. **Exact Base Pinning & Host Assertion Switch (`load_base`) — PASS**
   - Both the working module (`BASE_PATH`) and the backup-root copy (`FROZEN_BASE`) are SHA-256 verified against `9fc8086461f673e5720055cee6eeb0478494433d63e759a5f242539f97df0dc6` prior to dynamic execution.
   - `base.REMOTE` undergoes two exact, cardinality-checked (`count(...) == 1`) replacements:
     1. Replaces `assert socket.gethostname()=='racknerd-f0269d5'` at 0-indent with `assert os.environ.get('WSL_DISTRO_NAME')=='QuizArchiveVerify21'` and `assert 'microsoft-standard-WSL2' in os.uname().release`.
     2. Extends the JSON proof payload with `'wsl_distro':os.environ.get('WSL_DISTRO_NAME')` and `'kernel_release':os.uname().release`.
   - Monkey-patching `base.send_chunk` inside `verify()` (with restoration in `finally`) cleanly intercepts chunk dispatch inside `base.verify`'s `flush()` closure without altering any manifest, tar, or receipt logic.

2. **Unchanged Kernel Restore & Metadata/Hash Semantics — PASS**
   - All restoration and verification invariants from the frozen base verifier remain intact: `/dev/shm` `tmpfs` verification via real `findmnt`, `MemAvailable` and `/dev/shm` `statvfs` headroom assertions, GNU `tar` extraction with `--numeric-owner --same-owner --same-permissions --acls --xattrs --xattrs-include=* --delay-directory-restore`, symlink-parent traversal refusal, `lstat()` verification of `mode`, `uid`, `gid`, `mtime_ns`, non-followed `xattrs`, regular file `size` + `sha256`, symlink `target`, pre/post archive SHA-256 verification, and atomic `open('x')` + `os.fsync` receipt creation.

3. **Raw Binary EOF Transport (`local_send`) — PASS**
   - Invokes `['wsl.exe', '-d', 'QuizArchiveVerify21', '-u', 'root', '--', 'python3', '-c', base.REMOTE]` directly (`shell=False`).
   - Writes the newline-delimited JSON header followed by chunked binary streaming (`shutil.copyfileobj`), closes `child.stdin`, and sets `child.stdin = None` before `child.communicate(timeout=360)` (preventing `communicate()` from touching a closed pipe while delivering clean EOF to `tar` in the guest).
   - Exception path properly `kill()`s and `wait(timeout=15)`s the subprocess.

4. **Strict WSL Distro & Linux Kernel Boundaries — PASS**
   - Enforced both inside the guest before extraction (`WSL_DISTRO_NAME == 'QuizArchiveVerify21'`, `'microsoft-standard-WSL2' in os.uname().release`, `/dev/shm` `tmpfs`) and re-verified on the Windows host after parsing stdout alongside the independently recomputed `expected` projection SHA-256 and `entry_count`.

5. **Persisted Proof vs. CLI Claims & Gate Compatibility — PASS (with 1 downstream gate note)**
   - **Persisted receipt vs. CLI stdout**: `main()` strips `chunks` only from the terminal print summary; `base.verify()` writes the full `chunks` array into the immutable receipt file on disk, where every chunk records `transport: 'wsl2'`, `base_verifier_sha256`, `wsl_distro: 'QuizArchiveVerify21'`, `kernel_release`, `chunk_sha256`, `expected_sha256`, `restored_sha256`, `scratch_fstype: 'tmpfs'`, and `scratch_cleaned: True`.
   - **Downstream deletion-gate note (non-blocking for this adapter)**: Each persisted chunk's `hostname` field will reflect the local WSL2 hostname (`socket.gethostname()`) rather than `'racknerd-f0269d5'`, and the WSL2 provenance fields (`transport`, `wsl_distro`, `kernel_release`, `base_verifier_sha256`) are persisted per-chunk in `chunks[*]` while the top-level receipt header remains `'verifier': 'linux_chunk_restore'`. Ensure the independent 9-archive proof review / deletion gate checks `chunks[*]` for the WSL2 fields rather than asserting the remote VPS hostname.


Root повторно проверил реальный fixture:3/3записей;25локальных тестов прошли. Архивы девяти сборок эта проверка кода ещё не принимает.
