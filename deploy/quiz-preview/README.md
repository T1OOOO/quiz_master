# Remote preview

Target: verified k3s node `192.3.164.184`, namespace **quiz-master**, release
**quiz-master**, URL **https://quiz.kotopedia.org**. No Language Learner workloads,
secrets, DBs or charts are reused; only the shared Traefik/issuer/storage provisioner.
Existing Language Learner source tree is read-only for this task.

Current status (2026-10-03): **https://quiz.kotopedia.org is live**, certificate
Ready; quiz Helm revision 9 and shared edge revision 10 deployed. The public HTTPS
101-pack/3128-question selection and 19-answer/history/reveal/ownership smoke passed. Owner approved the
shared ingress restart; Language Learner's before/after release verification passed.
Quiz's namespaced Role/RoleBinding grants Traefik only read access to its own
routes/TLS configuration. Other namespaces have no new grants.
Shared values are in `shared-edge-quiz-values.yaml`: include this override in future
edge upgrades, or use `--reuse-values`, to retain the quiz namespace allowlist.
Shared audit mirror: `/opt/ll/docs/ops/CHANGELOG.md` on the verified remote host.

The discovery catalog lists 101 packs / 3128 questions in seven categories;
all 101 are playable without entering a name. This is a rewrite preview, not React parity completion or a
production acceptance. SQLite has one writer, one replica and a Recreate rollout
(brief downtime). The API stays on loopback within the pod; nginx serves Web and
proxies `/v1` same-origin. No disabled browser security or local Docker is required.
PVC `quiz-data` survives Helm uninstall; never delete it as rollback.

Build the Linux/amd64 Go API with CGO_ENABLED=0, and Flutter Web release with
`--dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org`. Package `api`, `web`,
`next/contracts`, the private source `quizzes` directory, nginx.conf and Dockerfile
in an isolated staging directory. Private content must never be under `web`.
After copying all Flutter build output, stamp `web/version.json` with build ID,
commit and API/JS SHA256. Flutter itself generates a different version.json:
stamping before copying silently overwrites the release identity. Verify the
staged stamp and both actual file hashes before archiving. Build the runtime
image on the remote host using a digest-pinned nginx base; do not compile there.
Import the unique image tag into k3s containerd and register its repository@digest
alias before the Helm upgrade. No Actions/registry push required.

Release only through `deploy/helm/quiz-master`, with explicit `image` and `buildId`.
Run `helm lint --strict`, render, inspect scope and API-server dry-run before install.
Install with `helm upgrade --install quiz-master ... -n quiz-master --create-namespace
--wait --timeout 180s`. Record exact remote operations in `deploy/quiz-preview/OPERATIONS.md`.
Verify rollout, TLS, `/version.json`, `/health/ready`, `/v1/catalog`, a disposable
guest/attempt flow and continued Language Learner health. Do not print bearer tokens.
Run `pwsh -File deploy/quiz-preview/smoke.ps1` for all 101 packs and a completed 19-question quiz.
The check creates disposable guest/attempt records and prints no bearer tokens.

Rollback: `helm rollback quiz-master PREVIOUS_REVISION -n quiz-master --wait`.
On a failed first install stop only this Deployment; retain the PVC and inspect
events/logs. On-node online backup and independent restored-file integrity/count
checks passed before revision 6; off-node backup and load acceptance remain outstanding.
Before production use: isolated off-node SQLite backups with restore proof,
operational review and the remaining parity/security acceptance gates.
