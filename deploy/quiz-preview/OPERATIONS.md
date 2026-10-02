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
