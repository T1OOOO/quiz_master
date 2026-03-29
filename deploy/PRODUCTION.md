# Production Notes

## Recommended Modes

- Recommended production mode: `postgres` for both `auth` and `storage`
- Supported limited-production mode: `sqlite` for single-node deployments with small load and explicit backup discipline

`server` does not own persistent state. `auth` and `storage` do.
Realtime room state is also persisted through `storage`; `server` holds only transient websocket connections.

## Deployment Baseline

- Set `ENV=production`
- Set strong values for `JWT_SECRET`, `AUTH_API_TOKEN`, `STORAGE_API_TOKEN`, `GRAFANA_ADMIN_PASSWORD`
- Set explicit `CORS_ALLOWED_ORIGINS` and `WS_ALLOWED_ORIGINS`
- Put TLS and public ingress in front of `server`
- Expose `auth` and `storage` only on private network paths

## Compose Modes

SQLite mode:

```bash
docker compose up --build
```

Postgres mode:

```bash
docker compose -f docker-compose.yml -f docker-compose.postgres.yml up --build
```

## Backup And Restore

SQLite backup examples:

```powershell
powershell -File .\scripts\backup-db.ps1 -Service auth
powershell -File .\scripts\backup-db.ps1 -Service storage
```

```bash
bash ./scripts/backup-db.sh auth
bash ./scripts/backup-db.sh storage
```

Postgres backup examples:

```powershell
$env:AUTH_DB_DRIVER="postgres"
$env:AUTH_DB_DSN="postgres://user:pass@host:5432/quiz_master_auth?sslmode=disable"
powershell -File .\scripts\backup-db.ps1 -Service auth
```

```bash
AUTH_DB_DRIVER=postgres AUTH_DB_DSN=postgres://user:pass@host:5432/quiz_master_auth?sslmode=disable \
  bash ./scripts/backup-db.sh auth
```

Restore examples:

```powershell
powershell -File .\scripts\restore-db.ps1 -Service storage -Input .\.backup\storage-20260329-120000.db
```

```bash
bash ./scripts/restore-db.sh storage ./.backup/storage-20260329-120000.db
```

For Postgres restore, `psql` and `pg_dump` must be installed on the operator host.

## Smoke Verification

After deploy, run:

```powershell
powershell -File .\scripts\smoke.ps1
```

```bash
bash ./scripts/smoke.sh
```

This verifies `healthz`, `readyz`, `metrics`, and basic public HTTP endpoints on `server`, `auth`, and `storage`.
