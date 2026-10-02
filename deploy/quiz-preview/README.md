# Remote preview

Target: verified k3s node `192.3.164.184`, namespace **quiz-master**, release
**quiz-master**, URL **https://quiz.kotopedia.org**. No Language Learner workloads,
secrets, DBs or charts are reused; only the shared Traefik/issuer/storage provisioner.
Existing Language Learner source tree is read-only for this task.

This is the current single-pack rewrite preview, not React parity completion or a
production acceptance. SQLite has one writer, one replica and a Recreate rollout
(brief downtime). The API stays on loopback within the pod; nginx serves Web and
proxies `/v1` same-origin. No disabled browser security or local Docker is required.
PVC `quiz-data` survives Helm uninstall; never delete it as rollback.

Build the Linux/amd64 Go API with CGO_ENABLED=0, and Flutter Web release with
`--dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org`. Package `api`, `web`,
`next/contracts`, the selected private `next/content` pack, nginx.conf and Dockerfile
in an isolated staging directory. Private content must never be under `web`.
Stamp `web/version.json` with build ID, commit and API/JS SHA256. Build the runtime
image on the remote host using a digest-pinned nginx base; do not compile there.
Import the unique image tag into k3s containerd. No Actions/registry push required.

Release only through `deploy/helm/quiz-master`, with explicit `image` and `buildId`.
Run `helm lint --strict`, render, inspect scope and API-server dry-run before install.
Install with `helm upgrade --install quiz-master ... -n quiz-master --create-namespace
--wait --timeout 180s`. Record exact remote operations in `deploy/quiz-preview/OPERATIONS.md`.
Verify rollout, TLS, `/version.json`, `/health/ready`, `/v1/catalog`, a disposable
guest/attempt flow and continued Language Learner health. Do not print bearer tokens.

Rollback: `helm rollback quiz-master PREVIOUS_REVISION -n quiz-master --wait`.
On a failed first install stop only this Deployment; retain the PVC and inspect
events/logs. No backup/restore acceptance or load-test is claimed by this preview.
Before production use: isolated off-node SQLite backups with restore proof,
operational review and the remaining parity/security acceptance gates.
