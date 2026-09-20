# P05 review fix round 1 — RED evidence

Executed from `C:\ap\quiz_master` before the timeout/startup implementation:

`go test ./next/server/internal/config ./next/server/internal/store ./next/server/cmd/api` exited `1` in `3.3s`.

- `config.Config` lacked `DatabaseStartupTimeout`, `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, and `IdleTimeout`.
- `cmd/api` lacked `newServer`, so no testable configured HTTP timeout construction existed.
- The new store transaction tests passed immediately because the pre-existing deferred transaction behavior already performed one rollback on panic/callback error, one commit on success, preserved commit errors, and did not roll back after commit failure. They are retained as regression coverage; no artificial production regression was introduced.
