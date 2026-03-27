# quiz_master

`quiz_master` now boots through a modular Go backend split into `server`, `auth`, `storage`, and the existing quiz/realtime domains.

## Structure

- `cmd/api` thin entrypoint that only loads config and starts the app
- `internal/server` composition root, Echo setup, route mounting, lifecycle
- `internal/auth` auth domain, service, JWT manager, HTTP handlers and middleware
- `internal/storage` DB bootstrap, migrations, repositories
- `internal/quiz` quiz HTTP and service runtime module
- `internal/service` legacy compatibility facade for quiz imports/tests
- `internal/realtime` websocket room/hub logic

## Local Run

1. Copy `.env.example` to `.env` and adjust values if needed.
2. Run `go test ./...`.
3. Start the API with `go run ./cmd/api`.

Local development defaults are separated from other apps:

- API: `http://localhost:8090`
- Flutter web dev server: `http://localhost:8091`

Development scripts:

- `powershell -File .\scripts\db.ps1 -Action init`
- `powershell -File .\scripts\run-api.ps1 -InitDb`
- `powershell -File .\scripts\stop-api.ps1`
- `powershell -File .\scripts\run-client.ps1`
- `powershell -File .\scripts\run-client-web.ps1 -WebPort 8091`
- `powershell -File .\scripts\run-client-windows.ps1`
- `powershell -File .\scripts\run-dev.ps1`
- `powershell -File .\scripts\stop-dev.ps1`
- `powershell -File .\scripts\stop-all.ps1`
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
- `WEB_PORT`, default `8091` for Flutter web dev runs

Default endpoints:

- `GET /healthz`
- `GET /readyz`
- `POST /api/register`
- `POST /api/login`
- `POST /api/guest`
- `GET /api/quizzes`
- `GET /api/quizzes/:id`
- `POST /api/quizzes/:id/check`
- `GET /ws`

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
