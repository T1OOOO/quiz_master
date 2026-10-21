# Независимая проверка нового снимка архива

Проверяющий: Antigravity / Gemini 4 Argon High.

Разговор: `886b854f-98e9-4f5d-97b0-0b6d7aef823b`.

Хэш журнала: `268deeaa71377f0d3db8c59ede6e7469a78e51172dcb3f8ad57516b74225d7fe`.

Это проверка кода; фактические архивы и удаление требуют отдельных квитанций.

**VERDICT: ACCEPT**

### Concrete Review Findings

1. **Subset Validation (`validate_subset`)**:
   - Rejects duplicate paths in both `old_rows` and `current_rows`, requires `.` to remain present as a directory, and enforces `set(current) <= set(old)` so any added path fails closed (`ValueError('new source entries require ordinary rearchive')`).
   - Enforces full dict equality (`new != before`) for all retained non-directory entries (`file`, `symlink`, or any entry whose `type` changed), preventing silent acceptance of modified file bytes (`sha256`/`size`), symlink targets, timestamps, modes, ownership, or extended attributes.
   - For retained directories (`new.get('type') == 'dir'` and `before.get('type') == 'dir'`), permits changes only to `mtime_ns` and `size` while requiring all other attributes (`mode`, `uid`, `gid`, xattrs, etc.) to match identically.

2. **Source Binding & Controller Pinning (`controller`, `reconcile`)**:
   - Verifies `archive_orchestrator-v2.py` against pinned SHA-256 `dde03ca072f5765ef9b91a1f81ea5fd085054fe51a8eb5bd928614373d4a3304` before loading.
   - Enforces `a.persistent(...)` on all input and output paths, validates both manifests against the fixed allowlist and canonical `manifest_sha256` for the same `root`, and requires `old['source_identity'] == current['source_identity']`.
   - Re-verifies the original archive and its Linux restore/review evidence (`a.verify(...)`), captures `original_sha` before repack, and re-verifies `a.sha_file(original_archive) == original_sha` afterward.
   - Brackets the repack with live remote `a.inventory(...)` snapshots (`pre-source.json` and `post-source.json`) plus `a.fresh_guard(root, fresh)`, ensuring the live source matches `current['manifest_sha256']` before and after transformation.

3. **Metadata & Nanosecond Timestamp Preservation (`pax_time`, `repack_tar`)**:
   - Streams retained file payloads and deep-copies original `TarInfo` headers (`uid`, `gid`, `uname`, `gname`, `mode`, `linkname`, and `pax_headers` including `SCHILY.xattr.*` / ACLs) into a `tarfile.PAX_FORMAT` archive.
   - Formats directory `mtime_ns` via integer `divmod(abs(ns), 1000000000)` in `pax_time`, avoiding float64 precision loss in `info.pax_headers['mtime']`.

4. **Path Handling & Member Verification**:
   - `repack_tar` rejects absolute paths, `..` traversal segments, members outside `basename`, non-`file`/`dir`/`symlink` special members, type mismatches against `current_rows`, duplicate retained members, and incomplete retained sets (`seen != set(current)`).
   - `reconcile` additionally runs the controller's `a.safe_tar_members(part, PurePosixPath(root).name)` and checks exact set and length equality against `expected` before publishing `output`.

5. **Original Preservation, Fail-Closed Output, and Deletion Non-Authorization**:
   - Forces output into `BACKUP / 'generation2/archives' / '<basename>.tar.gz'` and refuses execution if `output`, `.part`, or `.repack-receipt.json` already exists (`'xb'` / `'x'`).
   - Fsyncs `.part` before `os.replace(part, output)` and fsyncs `.repack-receipt.json`.
   - Leaves original archives and live server roots untouched (`original_archive_retained: True`, `original_source_deleted: False`, `linux_restore_still_required: True`) and does not satisfy `receipt_gate` (`verifier: "linux_chunk_restore"` + independent review receipt are still required prior to any deletion).

