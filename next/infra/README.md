# Quiz v2 local stack (Windows)

This is a disposable rewrite-only API and PostgreSQL stack. It does not use the legacy Compose files, `start.sh`, `web/`, `./data`, or any production target.

From `C:\ap\quiz_master`, choose a collision-safe, unique project name and a random localhost port:

```powershell
$project = "qm-v2-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
$env:QM_API_PORT = '0'
docker compose --project-name $project -f next/infra/compose.yml up --build --wait
$port = (docker compose --project-name $project -f next/infra/compose.yml port api 8080).Split(':')[-1]
Invoke-WebRequest "http://127.0.0.1:$port/health/live" -UseBasicParsing
Invoke-WebRequest "http://127.0.0.1:$port/health/ready" -UseBasicParsing
docker compose --project-name $project -f next/infra/compose.yml logs --no-color
docker compose --project-name $project -f next/infra/compose.yml down --volumes --remove-orphans
```

The Compose project scopes its `postgres_data` volume and `quiz_v2` network. `QM_API_PORT=0` lets Docker select a free loopback port; set a specific unused local port only when needed. The environment values in `compose.yml` are non-secret development examples. Do not reuse them outside this disposable local stack.

For a bounded, self-cleaning validation run, use `./next/infra/validate.ps1`. It captures the exact project identity, renders configuration, checks immutable refs, builds, waits for both health checks, probes liveness/readiness, collects logs, and tears down only its own project and volume.
