# P10AF RED/GREEN

All commands ran sequentially from `C:\ap\quiz_master` with `-p=1`.

- RED: `go test -p=1 -count=1 ./next/server/internal/migrate ./next/server/internal/attempts ./next/server/internal/httpapi` exited 1. Migration tests observed only versions 1–2 and no 0003; attempts failed to compile because the validated manifest had no exact-byte digest; the HTTP test showed an unauthenticated reveal 401 without `Cache-Control: no-store`.
- GREEN: after migration 0003 registration, exact validated-byte manifest hashing/persistence, and authentication no-store handling, the same focused packages exited 0 in 9.398 seconds.
- RED: `go test -p=1 -count=1 ./next/server/internal/httpapi` exited 1 because a wrong-method reveal response returned 405 without `no-store`.
- GREEN: after wrapping the complete reveal path before method/auth routing, the same package exited 0 in 4.716 seconds.

The tagged tests additionally encode explanation-only restart rejection, legacy `NULL -> hash` adoption, second-adoption/update/delete rejection, new-null-hash insert rejection, and raw reveal-element schema validation. They compile, but their database behavior could not execute because the approved PostgreSQL target remains unavailable.
