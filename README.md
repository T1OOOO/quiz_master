# quiz_master

`quiz_master` now boots through a modular Go backend split into `server`, `auth`, `storage`, and the existing quiz/realtime domains.

## Structure

- `cmd/api` thin entrypoint that only loads config and starts the app
- `internal/server` composition root, Echo setup, route mounting, lifecycle
- `internal/auth` auth domain, service, JWT manager, HTTP handlers and middleware
- `internal/storage` DB bootstrap, migrations, repositories
- `internal/service` existing quiz business logic wired through repository interfaces
- `internal/realtime` websocket room/hub logic

## Local Run

1. Copy `.env.example` to `.env` and adjust values if needed.
2. Run `go test ./...`.
3. Start the API with `go run ./cmd/api`.

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
