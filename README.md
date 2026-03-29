# quiz_master

`quiz_master` runs as a split backend:

- `server` is the public gateway for quiz, auth, and websocket flows
- `auth` owns users, tokens, quota, leaderboard, and internal auth APIs
- `storage` owns quiz persistence, reports, file sync, and internal storage APIs

## Structure

- `cmd/server`, `cmd/auth`, `cmd/storage` are the real backend binaries
- `cmd/api` is a legacy alias that still starts the server binary
- `internal/server` is the public gateway that talks to `auth` and `storage`
- `internal/authapi` and `internal/storageapi` define internal HTTP contracts
- `internal/authclient` and `internal/storageclient` are inter-service clients
- `internal/authdb` and `internal/storage/db` own DB bootstrap and versioned migrations
- `internal/realtime` owns websocket transport, while room state is persisted through `storage`

## Runtime Defaults

- Server: `http://localhost:8090`
- Flutter web: `http://localhost:8091`
- Auth: `http://localhost:8092`
- Storage: `http://localhost:8093`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`
- Alertmanager: `http://localhost:9093`
- Loki: `http://localhost:3100`
- Tempo: `http://localhost:3200`

## Local Run

1. Copy `.env.example` to `.env`.
2. Adjust secrets and origins.
3. Run `go test ./...`.
4. Start services in this order: `storage`, `auth`, `server`.

Direct Go runs:

```bash
go run ./cmd/storage
go run ./cmd/auth
go run ./cmd/server
```

Helper scripts:

- `powershell -File .\scripts\run-storage.ps1`
- `powershell -File .\scripts\run-auth.ps1`
- `powershell -File .\scripts\run-server.ps1`
- `powershell -File .\scripts\run-servers.ps1`
- `powershell -File .\scripts\run-flutter.ps1`
- `powershell -File .\scripts\run-dev.ps1`
- `bash ./scripts/run-storage.sh`
- `bash ./scripts/run-auth.sh`
- `bash ./scripts/run-server.sh`
- `bash ./scripts/run-servers.sh`
- `bash ./scripts/run-flutter.sh`
- `bash ./scripts/run-dev.sh`

Stop scripts:

- `powershell -File .\scripts\stop-storage.ps1`
- `powershell -File .\scripts\stop-auth.ps1`
- `powershell -File .\scripts\stop-server.ps1`
- `powershell -File .\scripts\stop-dev.ps1`
- `bash ./scripts/stop-storage.sh`
- `bash ./scripts/stop-auth.sh`
- `bash ./scripts/stop-server.sh`
- `bash ./scripts/stop-dev.sh`

## Persistence Modes

`auth` and `storage` each support two modes:

- `sqlite`: simple single-node mode using `AUTH_DB_PATH` and `STORAGE_DB_PATH`
- `postgres`: recommended production mode using `AUTH_DB_DSN` and `STORAGE_DB_DSN`

SQLite is still supported, but for production it should be treated as limited mode with explicit backup discipline and no expectation of horizontal scale.

Versioned startup migrations are applied automatically on boot for both drivers.

## Database Maintenance

SQLite-oriented `dbtool`:

```bash
go run ./cmd/dbtool -action init
go run ./cmd/dbtool -action import-quizzes
go run ./cmd/dbtool -action import-quizzes -prune
```

`dbtool` remains mainly relevant for SQLite paths. In Postgres mode, startup migrations still run automatically, but file reset flows are not used.

Backup scripts:

- `powershell -File .\scripts\backup-db.ps1 -Service auth`
- `powershell -File .\scripts\backup-db.ps1 -Service storage`
- `bash ./scripts/backup-db.sh auth`
- `bash ./scripts/backup-db.sh storage`

Restore scripts:

- `powershell -File .\scripts\restore-db.ps1 -Service auth -Input .\.backup\auth-YYYYMMDD-HHMMSS.db`
- `powershell -File .\scripts\restore-db.ps1 -Service storage -Input .\.backup\storage-YYYYMMDD-HHMMSS.db`
- `bash ./scripts/restore-db.sh auth ./.backup/auth-YYYYMMDD-HHMMSS.db`
- `bash ./scripts/restore-db.sh storage ./.backup/storage-YYYYMMDD-HHMMSS.db`

For Postgres backups and restores, `pg_dump` and `psql` must be installed on the operator host.

## Flutter

Flutter web reads backend URLs from `--dart-define`:

- `SERVER_BASE_URL`, default `http://localhost:8090`
- `API_BASE_URL`, default `http://localhost:8090/api`
- `AUTH_API_BASE_URL`, default `API_BASE_URL`
- `QUIZ_API_BASE_URL`, default `API_BASE_URL`
- `WEB_PORT`, default `8091`

## HTTP Surface

Public gateway endpoints on `server`:

- `GET /healthz`
- `GET /readyz`
- `GET /metrics`
- `POST /api/register`
- `POST /api/login`
- `POST /api/refresh`
- `POST /api/guest`
- `GET /api/leaderboard`
- `POST /api/submit`
- `GET /api/quota`
- `GET /api/quizzes`
- `GET /api/quizzes/:id`
- `POST /api/quizzes/:id/check`
- `POST /api/report`
- `GET /ws`

Realtime room state is no longer authoritative in `server` process memory. `server` keeps only live websocket connections and syncs room state through `storage`, which makes room lifecycle resilient across server restarts and workable for multi-instance deployments.

Internal service endpoints:

- `auth`: `/internal/auth/...`
- `storage`: `/internal/storage/...`
- internal service auth uses `X-Internal-Token`
- websocket auth requires a JWT in `Authorization: Bearer ...` or `?access_token=...`

## Security Baseline

Production mode requires:

- strong `JWT_SECRET`
- strong `AUTH_API_TOKEN`
- strong `STORAGE_API_TOKEN`
- explicit `CORS_ALLOWED_ORIGINS`
- explicit `WS_ALLOWED_ORIGINS`
- auth rate limiting via `AUTH_RATE_LIMIT_RPS` and `AUTH_RATE_LIMIT_BURST`

## Observability

Compose includes:

- `prometheus`
- `grafana`
- `blackbox-exporter`
- `alertmanager`
- `loki`
- `promtail`
- `tempo`
- `otel-collector`

Prometheus scrapes:

- `server:8090/metrics`
- `auth:8092/metrics`
- `storage:8093/metrics`
- synthetic probes for all three `/readyz` endpoints

Provisioned Grafana dashboards:

- `Quiz Master Overview`
- `Quiz Master HTTP`
- `Quiz Master Logs And Traces`

## Docker Compose

SQLite mode:

```bash
docker compose up --build
```

Postgres mode:

```bash
docker compose -f docker-compose.yml -f docker-compose.postgres.yml up --build
```

Smoke check after startup:

```bash
bash ./scripts/smoke.sh
```

```powershell
powershell -File .\scripts\smoke.ps1
```

## Important Environment Variables

- `ENV`
- `JWT_SECRET`
- `AUTH_API_TOKEN`
- `STORAGE_API_TOKEN`
- `CORS_ALLOWED_ORIGINS`
- `WS_ALLOWED_ORIGINS`
- `AUTH_RATE_LIMIT_RPS`
- `AUTH_RATE_LIMIT_BURST`
- `AUTH_DB_DRIVER`
- `AUTH_DB_DSN`
- `AUTH_DB_PATH`
- `STORAGE_DB_DRIVER`
- `STORAGE_DB_DSN`
- `STORAGE_DB_PATH`
- `AUTH_API_URL`
- `STORAGE_API_URL`
- `OTEL_ENABLED`
- `OTEL_EXPORTER_OTLP_ENDPOINT`

More production-specific notes live in `deploy/PRODUCTION.md`.

## Adding Modules

Cross-cutting assembly belongs in `internal/server/bootstrap.go`. Repository code belongs in `internal/storage`, auth-specific logic in `internal/auth`, and domain-specific quiz/realtime behavior should stay outside bootstrap layers.
