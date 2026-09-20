# P05 isolated PostgreSQL integration evidence

Executed from `C:\ap\quiz_master` on 2026-09-20.

- Image: `postgres:17`, `sha256:f4c66b820c6f974249089d3d16d86a3698eae11e8746eb6644b2271031e91232`.
- Container: `qm-p05-a710da6d2d46` (`302dcad83a2526b0d87a99dabd29a5215df73b0a46c7d4e98dfd3398caf6d93f`); database and connection credentials are redacted. The host port was random.
- Volume: `qm-p05-a710da6d2d46-data` only.
- Command: `go test -count=1 -v -tags integration ./next/server/internal/migrate ./next/server/internal/identity ./next/server/internal/store`; exit `0`, duration `1.23s` (package-reported elapsed time).
- Passed named integration cases: migration application/checksum drift; guest/session create/authenticate/unknown/revoke/expiry/unique digest; transaction commit and rollback. The observed public schema objects were `participants`, `schema_migrations`, `sessions`, and test-only `tx_probe`.

No raw session credential was stored in this evidence.

## Review fix round 1 rerun

- Container: `qm-p05-b3024229bc9e` (`f08d11d654bd39a0082ccf2fd8eae00d42ba8d234eae4202710769b0071ccca9`); PostgreSQL 17 image unchanged; connection information redacted.
- Volume: `qm-p05-b3024229bc9e-data` only.
- Commands: `go test ./...` exit `0` (22.3s combined verification); `go vet ./next/server/...` exit `0`; `go test -count=1 -tags integration ./next/server/internal/migrate ./next/server/internal/identity ./next/server/internal/store` exit `0` (package elapsed `1.82s`).
- This container and its exact volume are removed after the final scoped whitespace check.
