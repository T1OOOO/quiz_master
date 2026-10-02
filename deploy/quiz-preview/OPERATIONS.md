# Quiz preview operations

## 2026-10-02 — target verification and configuration preflight (Codex)

Preflight status at this checkpoint: **NOT DEPLOYED**. No quiz namespace, workload, PVC or certificate created.
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

## 2026-10-02 — release build and remote packaging

Host headroom recovered; sequential builds admitted by the shared coordinator.
Linux API and Flutter Web release exited zero (Flutter 119.1 seconds). Build ID
`quiz-2026.10.02-0857-ef419ae`; code commit `ef419ae`; API URL
`https://quiz.kotopedia.org`. Artifact hashes were checked against `web/version.json`:

- API SHA256 `8202291efad70ec1bdb732d716835ce6e245fba3b66948b3edece9ceac2719d7`.
- Web JS SHA256 `b0a37897be21fb6dfbc3f71710907da5d2f39f43480b979aaa7b380be9ec4f8c`.

Local build commands (root, then `next/apps/quiz_app`):

```sh
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOMAXPROCS=2 go build -p=1 -trimpath -o STAGING/api ./next/server/cmd/api
flutter build web --release --no-pub --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --pwa-strategy=none
```

25,812,118-byte isolated archive transferred by strict-host SSH/SCP into
`/opt/quiz-master/releases/quiz-2026.10.02-0857-ef419ae`. Remote packaging:

```sh
cd /opt/quiz-master/releases/quiz-2026.10.02-0857-ef419ae
tar -xzf release.tar.gz
docker pull nginx:stable-alpine
docker image inspect nginx:stable-alpine --format '{{index .RepoDigests 0}}' | xargs -I BASE docker build --network=none --build-arg NGINX_IMAGE=BASE -t quiz-master:quiz-2026.10.02-0857-ef419ae .
docker run --rm --network=none --read-only --tmpfs /tmp:size=64m --entrypoint nginx quiz-master:quiz-2026.10.02-0857-ef419ae -t
docker save quiz-master:quiz-2026.10.02-0857-ef419ae | k3s ctr -n k8s.io images import -
```

All exited zero; nginx configuration test passed. Base image resolved before build
to `nginx@sha256:0985e772fb9f729e6fa0980da05fca5d9c468e870eed43071545afa9d2e27d94`;
runtime OCI index `sha256:fc8983e1c147fe58143fcaa106744628af03cd6bc0a6bba4ce66ac9485f68f74`.
Both are pinned in tracked configuration. Flutter emitted deprecated PWA flag and
unused Cupertino-font warnings; it still built successfully. No Android build was
requested/performed in this Web preview.

## 2026-10-02T09:22:20Z — namespace deployment and smoke (Codex)

The digest reference was added to k3s and release values uploaded. Commands in
`/opt/quiz-master/releases/quiz-2026.10.02-0857-ef419ae`:

```sh
k3s ctr -n k8s.io images tag docker.io/library/quiz-master:quiz-2026.10.02-0857-ef419ae docker.io/library/quiz-master@sha256:fc8983e1c147fe58143fcaa106744628af03cd6bc0a6bba4ce66ac9485f68f74
helm lint --strict chart --namespace quiz-master -f release-values.yaml
helm template quiz-master chart --namespace quiz-master -f release-values.yaml > rendered.yaml
kubectl get namespace quiz-master >/dev/null 2>&1 || kubectl create namespace quiz-master
kubectl apply --dry-run=server -n quiz-master -f rendered.yaml
flock -n /opt/quiz-master/DEPLOY.lock helm upgrade --install quiz-master chart --namespace quiz-master --create-namespace -f release-values.yaml --wait --timeout 180s
```

Namespace creation, lint and server dry-run passed. First install timed out:
API configuration rejected `sqlite:/data/quiz.db` because Go URL parsing sets
Path, not the opaque path required by this application's explicit SQLite mode.
No application code changed: chart corrected to `sqlite:../data/quiz.db` with
working directory `/app`, resolving to the existing `/data` PVC. Uploaded the
corrected template, reran lint/render/server dry-run, then:

```sh
flock -n /opt/quiz-master/DEPLOY.lock helm upgrade --install quiz-master chart --namespace quiz-master -f release-values.yaml --wait --timeout 180s
kubectl get pods,pvc -n quiz-master
kubectl get deployment quiz-master -n quiz-master
helm list -n quiz-master
kubectl get certificate -n quiz-master
```

Revision **2 deployed**; Deployment 1/1 available, pod 2/2 ready, zero restarts;
1 GiB PVC Bound. The API and nginx are non-root and read-only except their mounts.
Temporary SSH tunnel to `kubectl port-forward --address=127.0.0.1 -n quiz-master
service/quiz-master 18082:80` allowed a full API smoke. The first smoke wrongly
expected PostgreSQL's early-reveal 400; inspected SQLite's existing GetHistory
guard and corrected the harness expectation to its 404. A subsequent test was
interrupted by prematurely closing the test tunnel; no application defect claimed.
Final runnable check:

```powershell
./deploy/quiz-preview/smoke.ps1 -BaseUrl http://127.0.0.1:18082
```

Exit zero: correct build/version, readiness 200, 25 accepted answers, finished
attempt, 25 history entries and reveals, stable replay receipt, cross-owner 404.
Only disposable test participants/attempts were created; no bearer tokens logged.
Tunnel closed after completion; remote port 18082 confirmed unbound.

**Public ingress/TLS: BLOCKED awaiting owner confirmation.** Live shared Traefik
revision 9 has both providers restricted to ingress-system/language-learner/
monitoring, and Recreate update strategy. Its service account cannot list our
Ingress or Middleware (`kubectl auth can-i --as=system:serviceaccount:ingress-system:traefik
list ingresses.networking.k8s.io -n quiz-master` and the equivalent middleware
check both returned no). Existing namespace bindings use the
`traefik-ingress-reader` ClusterRole. Required next step: add quiz-master to both
provider namespace lists through the canonical edge Helm chart, and add a scoped
RoleBinding in quiz-master. Do not broaden to all namespaces. This shared restart
may briefly interrupt Language Learner; permission requested before mutation.
Keep the edge previous revision for rollback, preserve all existing values, run
its verify-release script before/after, and record shared changes in its required
operations log. No edge change or neighbor source edit has been made.

Certificate still Pending: HTTP-01 self-check receives 404 because Traefik ignores
the namespace. This is not a DNS or secret problem. Language Learner continued
to return HTTPS 200; app release remains revision 83. Final public HTTPS smoke,
certificate acceptance, browser review, independent review, backup/restore and
load acceptance remain NOT_RUN. Issue `quiz_master-eel` stays in progress.

## 2026-10-02T09:56:13Z — owner-approved public routing completed

See `shared-edge-operations.md` for exact commands and outcomes (mirrored to the
remote `/opt/ll/docs/ops/CHANGELOG.md`). Owner approved the shared Recreate restart.
Added a namespaced Role/RoleBinding in the quiz chart, then extended both shared
provider allowlists through the existing edge Helm release, preserving all other
live values. Diff showed only two namespace arguments; no existing route/image/
certificate changes. Quiz revision 3 and edge revision 10 deployed. Certificate
Ready True, HTTPS Web 200, correct release/JS hash. Public smoke exited zero with
25 answers/history/reveals, idempotent replay and foreign-owner 404.
Language Learner's full release verification passed before and after, with original
frontend/backend IDs and JS hash. Its app/DB/content were not updated. Other
namespace Secret access still denied to Traefik. Temporary tunnel is not needed.
Deployment issue can be closed; React parity/full catalog, off-node backup/restore,
load testing and independent-provider review remain separate unfinished gates.
