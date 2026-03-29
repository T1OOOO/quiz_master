# quiz_master

`quiz_master` now runs as a split backend:

- `server` is the public API gateway for quiz flows, auth flows, and websocket/realtime
- `auth` owns auth state, tokens, quota, leaderboard, and internal auth APIs
- `storage` owns quiz persistence, reports, quiz sync from files, and internal storage APIs

## Structure

- `cmd/server` quiz/server binary
- `cmd/auth` auth binary
- `cmd/storage` storage binary
- `cmd/api` legacy alias that currently starts the server binary
- `internal/server` public gateway service that talks to `auth` and `storage` over HTTP
- `internal/auth` auth domain, service, JWT manager, HTTP handlers and middleware
- `internal/authapi` internal HTTP contract owned by `auth`
- `internal/authclient` HTTP client used by `server`
- `internal/storage` DB bootstrap, migrations, repositories
- `internal/storageapi` internal HTTP contract owned by `storage`
- `internal/storageclient` HTTP client used by `server`
- `internal/quiz` quiz HTTP and service runtime module
- `internal/realtime` websocket room/hub logic

## Local Run

1. Copy `.env.example` to `.env` and adjust values if needed.
2. Run `go test ./...`.
3. Start the backend binaries you need:
   - `go run ./cmd/server`
   - `go run ./cmd/auth`
   - `go run ./cmd/storage`

Recommended startup order for local split mode:

1. `storage`
2. `auth`
3. `server`

Local development defaults are separated from other apps:

- Server: `http://localhost:8090`
- Flutter web dev server: `http://localhost:8091`
- Auth: `http://localhost:8092`
- Storage: `http://localhost:8093`
- Internal auth base URL for `server`: `http://localhost:8092`
- Internal storage base URL for `server`: `http://localhost:8093`
- Auth DB: `.data/auth.db` locally or `${AUTH_DB_PATH}` in containers
- Storage DB: `.data/storage.db` locally or `${STORAGE_DB_PATH}` in containers
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`
- Alertmanager: `http://localhost:9093`
- Loki: `http://localhost:3100`
- Tempo: `http://localhost:3200`

Development scripts:

- `powershell -File .\scripts\run-auth.ps1`
- `powershell -File .\scripts\run-storage.ps1`
- `powershell -File .\scripts\run-server.ps1`
- `powershell -File .\scripts\run-servers.ps1`
- `powershell -File .\scripts\run-flutter.ps1`
- `powershell -File .\scripts\db.ps1 -Action init`
- `powershell -File .\scripts\run-api.ps1 -InitDb`
- `powershell -File .\scripts\stop-api.ps1`
- `powershell -File .\scripts\run-client.ps1`
- `powershell -File .\scripts\run-client-web.ps1 -WebPort 8091`
- `powershell -File .\scripts\run-client-windows.ps1`
- `powershell -File .\scripts\run-dev.ps1`
- `powershell -File .\scripts\stop-dev.ps1`
- `powershell -File .\scripts\stop-auth.ps1`
- `powershell -File .\scripts\stop-storage.ps1`
- `powershell -File .\scripts\stop-server.ps1`
- `powershell -File .\scripts\stop-servers.ps1`
- `powershell -File .\scripts\stop-all.ps1`
- `bash ./scripts/run-auth.sh`
- `bash ./scripts/run-storage.sh`
- `bash ./scripts/run-server.sh`
- `bash ./scripts/run-servers.sh`
- `bash ./scripts/run-flutter.sh`
- `bash ./scripts/db.sh init`
- `bash ./scripts/run-api.sh`
- `bash ./scripts/stop-api.sh`
- `bash ./scripts/run-client.sh`
- `WEB_PORT=8091 bash ./scripts/run-client-web.sh`
- `bash ./scripts/run-client-windows.sh`
- `bash ./scripts/run-dev.sh`
- `bash ./scripts/stop-dev.sh`
- `bash ./scripts/stop-all.sh`

Quiz import and maintenance:

- `go run ./cmd/dbtool -action init`
- `go run ./cmd/dbtool -action import-quizzes`
- `go run ./cmd/dbtool -action import-quizzes -prune`

The API startup sync now imports and updates quizzes without deleting missing DB records. Use `import-quizzes -prune` only for intentional cleanup.

The Flutter client now reads backend URLs from `--dart-define`:

- `SERVER_BASE_URL`, default `http://localhost:8090`
- `API_BASE_URL`, default `http://localhost:8090/api`
- `AUTH_API_BASE_URL`, default `API_BASE_URL`
- `QUIZ_API_BASE_URL`, default `API_BASE_URL`
- `WEB_PORT`, default `8091` for Flutter web dev runs

Default split endpoints:

- Server (`:8090`): `GET /healthz`, `GET /readyz`, `POST /api/register`, `POST /api/login`, `POST /api/refresh`, `POST /api/guest`, `GET /api/leaderboard`, `POST /api/submit`, `GET /api/quota`, `GET /api/quizzes`, `GET /api/quizzes/:id`, `POST /api/quizzes/:id/check`, `POST /api/report`, `GET /ws`
- Auth (`:8092`): `GET /healthz`, `GET /readyz`, `POST /api/register`, `POST /api/login`, `POST /api/refresh`, `POST /api/guest`, `GET /api/leaderboard`, `POST /api/submit`, `GET /api/quota`
- Storage (`:8093`): `GET /healthz`, `GET /readyz`, `GET /api/storage/stats`

Internal service endpoints:

- Storage internal API: `/internal/storage/...`
- Auth internal API: `/internal/auth/...`
- Internal service auth between services uses `X-Internal-Token`

Observability endpoints:

- Server metrics: `http://localhost:8090/metrics`
- Auth metrics: `http://localhost:8092/metrics`
- Storage metrics: `http://localhost:8093/metrics`

## Observability Stack

The local Docker stack now includes:

- `prometheus` for scraping `/metrics`
- `grafana` with provisioned dashboards
- `blackbox-exporter` for synthetic readiness checks
- `alertmanager` for Prometheus alerts
- `loki` + `promtail` for container logs
- `tempo` + `otel-collector` for distributed traces

Start everything:

```bash
docker compose up --build
```

Important default URLs:

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Alertmanager: `http://localhost:9093`

Provisioned Grafana dashboards:

- `Quiz Master Overview`
- `Quiz Master HTTP`
- `Quiz Master Logs And Traces`

Prometheus currently scrapes:

- `server:8090/metrics`
- `auth:8092/metrics`
- `storage:8093/metrics`
- synthetic probes for all three `/readyz` endpoints

Key environment variables for split runtime:

- `AUTH_DB_PATH`
- `AUTH_API_URL`
- `AUTH_API_TOKEN`
- `STORAGE_DB_PATH`
- `STORAGE_API_URL`
- `STORAGE_API_TOKEN`
- `OTEL_ENABLED`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `OTEL_SERVICE_NAME`

## Docker Compose

1. Create `.env` from `.env.example`.
2. Run `docker compose up --build`.
3. Check health with `curl http://localhost:8085/healthz`.

The current runtime keeps SQLite as the persistence layer, so Compose only starts the API container plus a persistent `./data` volume mount.

## Environment

- `PORT` HTTP port inside the container and local process
- `DB_PATH` SQLite database path
- `ENV` application environment label for logs/runtime
- `QUIZZES_DIR` source directory for quiz import sync
- `JWT_SECRET` signing key for access tokens
- `JWT_TTL` token TTL duration, e.g. `24h`
- `SHUTDOWN_TIMEOUT` graceful shutdown timeout, e.g. `10s`

## Adding Modules

New cross-cutting modules should be assembled in `internal/server/bootstrap.go`. Repository code belongs in `internal/storage`, auth-specific logic in `internal/auth`, and domain-specific quiz/realtime behavior should stay outside the bootstrap layer.
