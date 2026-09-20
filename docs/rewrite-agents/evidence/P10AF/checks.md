# P10AF checks

Working directory: `C:\ap\quiz_master`.

| Command | Exit | Duration | Result |
|---|---:|---:|---|
| `go test -p=1 -count=1 ./next/server/internal/migrate ./next/server/internal/attempts ./next/server/internal/httpapi ./next/server/cmd/api` | 0 | 7.912 s | Invalidated focused packages passed. |
| `go test -p=1 -run '^$' -tags integration ./next/server/internal/migrate ./next/server/internal/attempts ./next/server/internal/httpapi ./next/server/internal/identity ./next/server/internal/store` | 0 | 5.277 s | All tagged packages compiled; no tagged test executed. |
| `go test -p=1 -count=1 ./...` | 0 | 59.110 s | Full Go suite passed once after final code changes. |
| `go vet -p=1 ./next/server/...` | 0 | 3.464 s | Server vet passed once. |
| `python -B next/contracts/quiz-contract/v1/check_contract.py` | 0 | 0.179 s | P04 content hash unchanged: `5cc3275eb90dc71d58a5dc5d42be0fece52b727ead2bdf6ad9e7727a30df5f4e`. |
| `python -B docs/rewrite-agents/evidence/P09/verify_content.py` | 0 | 0.151 s | Lightweight P08 verifier passed. |

P08 preserved hashes: canonical bundle `6c7754aa9b142d8657bac1bb65f0536d30364d262ef109315c4b9356ee512b95`; `bundle.json` `0bcb87fecd1e7ae46dd9e7f3d17623f8b97cb00b06333ad0394c914c793b6229`; `manifest.json` `93af5f22c9d4d570335a37aa6419d4b613e239d149293a6811f753d5e5f132d5`; `draft.json` `12e2691bbe5203bef962f2b5b2aebc42623f3ec96ae1daa739a922037b5cacef`.

Migration 0003 embedded/file checksum is `103eabd08d2a956069d86b68d160885d852a6d7d28babea075f4125af0274b19`.

Unavailable gate: `QM_TEST_DATABASE_URL` is unset and the approved P09 disposable PostgreSQL target was removed. No replacement database or container was created. Git/index commands were prohibited; the lead must relay scoped `git diff --check`.
