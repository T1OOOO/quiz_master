# Quiz preview operations

## 2026-10-02 — target verification and configuration preflight (Codex)

Status: **NOT DEPLOYED**. No quiz namespace, workload, PVC or certificate created.
The local release build was not launched: host reservation returned
`COMMIT_HEADROOM` (observed available Windows commit 3.11 GiB; a 2 GiB build
reservation plus 2 GiB safety headroom is required). Unrelated processes were
not stopped. No local Docker, PostgreSQL or GitHub Actions were used.

Verified with strict known-host SSH to `root@192.3.164.184`:

- Host `racknerd-f0269d5`, single ready k3s node; remote Helm and Docker installed.
- DNS `quiz.kotopedia.org` already resolves to this IP; no DNS changes made.
- Shared Traefik, Ready `letsencrypt` issuer and `local-path` storage exist.
- `quiz-master` namespace absent. Language Learner Helm revision remains 83,
  status deployed; `https://learn.kotopedia.org` returned HTTP 200.
- Neighboring project source, workloads, databases and credentials unchanged.

Only a chart archive was copied into the separate directory
`/opt/quiz-master/preflight/391b1c9`; no application image was built/imported.
The following remote commands completed successfully:

```sh
cd /opt/quiz-master/preflight/391b1c9
tar -xzf chart.tar.gz
helm lint --strict deploy/helm/quiz-master --namespace quiz-master --set image=quiz-master:preflight --set buildId=preflight
helm template quiz-master deploy/helm/quiz-master --namespace quiz-master --set image=quiz-master:preflight --set buildId=preflight > rendered.yaml
kubectl apply --dry-run=client --validate=false -n quiz-master -f rendered.yaml
```

Lint: one chart, zero failures. Client dry-run: NetworkPolicy, PVC, Service,
Deployment, Ingress and Middleware parsed. This is **not** API-server validation.
Negative check: rendering with `--namespace default` failed as required with
`This chart must be installed in the isolated quiz-master namespace`.

Self-review corrected executable mode for the Linux API and nginx header
inheritance. Independent-provider review: NOT_RUN (no additional agents).

Remaining before publication: fresh Go/Flutter release builds with the real HTTPS
API URL, version/hash stamp, pinned nginx digest, runtime image verification,
API-server dry-run, Helm install, TLS and guest/attempt smoke checks. Off-node
backup/restore and load testing are also NOT_RUN. Current content is one pack;
the full catalog/React parity is a separate unfinished work item.
