# Quiz preview operations

## 2026-10-03 02:45 — overlay-only feedback, stable question layout

Revision 11: `quiz-2026.10.03-0245-6b5e2e6`. Removed dynamically inserted result/
continue controls from practice question layout. Both outcomes/explanations now
use the centered modal; correct-answer timer/pause lives only in that modal.
Single/text practice has no inactive continue footer. Multi-choice/legacy submit
controls remain fixed, not newly inserted after answering. Details, image/hashes,
backup proof and screenshots: `docs/rewrite-agents/reports/OVERLAY_ONLY_RU.md`.
46 Flutter tests, analyze, Web release, practice HTTPS smoke and phone/desktop
browser checks passed. Rollback to revision 10 retains the existing SQLite PVC.

## 2026-10-03 01:40 — cozy background and pausable auto advance

Revision 10: `quiz-2026.10.03-0125-6326777`. Background restored, warm parchment
panels, correct-answer auto advance after 3s with pause/resume; incorrect answers
use centered manual explanations. See `docs/rewrite-agents/reports/COZY_AUTO_ADVANCE_RU.md`
for exact image, hashes, SQLite backup/restore proof, 46 Flutter tests, Web build,
practice HTTPS smoke and desktop/phone screenshots. API/PVC/content unchanged;
Language Learner revision 85, shared edge revision 10 unchanged. Rollback to quiz
revision 9 retains SQLite PVC. Cold-start/editorial/full-parity gates remain open.

## 2026-10-03 — twenty-question rounds and immediate practice feedback

Current release: **revision 9**, `quiz-2026.10.03-0042-33f5cfc`, source commit
`33f5cfc09e2dc719ad5466bfbf61c4be9aba4133`, image
`docker.io/library/quiz-master@sha256:d6c33526a626387db4e2742a77cad662f5beb1a5510141faf7e8df4fbe29deae`.

API SHA256: `5c6558fc37e42f08fbf25d255f619d340bb42d3fb57f97f7d3a6c0b19379b1ba`.
Web JS SHA256: `00b0bd6c6963957301b39a900247b9c309219e382efe3c715d1e7ab005e36622`.
Public downloaded JS hash matches the local stamp. Package is isolated at
`/opt/quiz-master/releases/quiz-2026.10.03-0042-33f5cfc`.

- Revision 7 (`quiz-2026.10.02-2358-c3420d3`) introduced shuffled partitions
  <=20, seven generated category covers (261954 bytes total), compact question
  layout, locally served CanvasKit/Roboto, nginx JS/JSON/WASM gzip.
- Revision 8 deployed practice code successfully, but packing copied Flutter's
  generated version.json over the release identity. The public version check
  caught this. Revision 9 changes the immutable runtime image/stamp only, with
  identical API and JS binaries. Stamp **after** copying Flutter output.
- New additive SQLite table `practice_attempts`; marker and attempt start share
  one transaction. No DB restoration, destructive migration or manifest rewrite.
- Before final rollout, online backup and isolated restored-DB integrity/count
  checks PASS: `/opt/quiz-master/backups/quiz-2026.10.03-0042-33f5cfc.sqlite`
  plus `.restore-proof.sqlite`; participants=23, attempts=323, bundles=102.
  Earlier unique revision-7/8 backups/packages retained.
- Go server tests and vet PASS (GOMAXPROCS=2, -p1); 44 Flutter tests PASS;
  analyze no issues; Web release PASS (39.4s, no CDN/no pub/no WASM dry run).
- Remote runtime-only build used pinned nginx, `--network=none --pull=false`;
  nginx config test, k3s digest alias/import, strict Helm lint, API-server dry-run,
  locked atomic upgrade PASS. Pod 2/2, zero restarts; deployment 1/1; original PVC
  `pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf` retained. No local Docker/PG/Actions.
- `smoke.ps1` PASS: 101 selected catalogs/first rounds, all 3128 source questions
  counted, 20+5 partition without duplicates, negative round rejected, complete
  19-answer quiz, history/reveals/replay and foreign-owner 404.
- `practice-smoke.ps1` PASS: accepted answer feedback aligned to pinned revision,
  nonempty explanation/correctness/no-store, unanswered/future/foreign 404,
  unknown mode 400. Local SQLite test also proves correct/wrong scoring and
  no early ranked feedback. Flutter test proves feedback retry does not resubmit.
- Actual browser: full 20-answer practice round and finish, next round URL,
  correct/incorrect overlay, common drawer/home/back; errors empty. Visually
  checked `docs/rewrite-agents/reports/practice-*.png` at 390x640/1280x900.
- Language Learner remains revision **85**; JS hash unchanged before/after:
  `520c6508fc7c9457b684c2d3210ae15322bdc2e9d1faf35b319958f55fbe66c7`.
  Shared edge remains revision10. No neighboring files/credentials/DBs changed.

Rollback to verified pre-practice code:
`helm rollback quiz-master 7 -n quiz-master --wait --timeout 180s`.
Keep the PVC and additive table; do not restore a backup over live answers.
No Android or independent-provider acceptance. All 3128 original explanations
are displayed, but editorial improvement of 497 short candidates is pending
`quiz_master-dhu`; three source-backed proposals are draft-only. A cold browser
sample still showed CanvasKit WASM 8.170s, JS 4.779s: gzip is a payload reduction,
not proof that all first-load latency is resolved.

## 2026-10-02 — discovery catalog update (18:01 Europe/Istanbul)

User requested updating the public site after source migration stage 1.
Deployed only `quiz-master`, Helm revision **4**, build
`quiz-2026.10.02-1759-585c4e2`, image
`docker.io/library/quiz-master@sha256:2136d278b30428be730e88da9bee1e40856e314c5c6c33c6f4dbc9c73e8cb2c2`.

- Fresh Flutter production build: PASS, 67.2s, `--no-pub --release
  --no-wasm-dry-run --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org
  --pwa-strategy=none --output build/production-catalog`.
- Web JS SHA256: `9ddf4b6b215a163a248e4fa3f1a3491ab1bc14c21aaba29c674545d1348353be`.
- Reused the previous verified API binary (source `ef419ae`), SHA256
  `8202291efad70ec1bdb732d716835ce6e245fba3b66948b3edece9ceac2719d7`.
  API runtime/contracts/private content unchanged; no DB migration or restoration.
- Isolated package: `/opt/quiz-master/releases/quiz-2026.10.02-1759-585c4e2`.
  Existing pinned nginx base; remote build `--network=none`, nginx config check,
  containerd import, Helm strict lint, template and server dry run: PASS.
  Upgrade used the existing lock plus `--atomic --wait --timeout 180s`.
- Public version/readiness/TLS PASS; pod 2/2; original SQLite PVC UID retained.
  Catalog metadata has 101 packs / 3128 questions; SHA256 matches the source
  asset: `5fec3a317415d95a181e177b596f9a492b2d6965d0fb6126bcc71a0135591001`.
- `pwsh -NoProfile -File deploy/quiz-preview/smoke.ps1`: PASS, 25 answers,
  finished/history/reveals all 25, replay stable, cross-owner history 404.
  This check creates disposable guest/attempt records in the existing SQLite DB.
- Live browser screenshot visually checked:
  `docs/rewrite-agents/reports/deployed-catalog-585c4e2.png`. Shows categories,
  search, total counts and the explicit single-playable-pack migration notice.
  Full UI interaction suite and independent agent review NOT_RUN this update.
- Shared edge stays revision 10; Language Learner stays revision 83 and its
  public frontend build/bundle hash matches preflight. No shared restart.

Rollback: `helm rollback quiz-master 3 -n quiz-master --wait --timeout 180s`.
Keep both release packages and the SQLite PVC. This is stage 1 discovery, not
the completed React-to-Flutter migration. Multi-pack play remains `quiz_master-i0r`.

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

## 2026-10-02 23:33 Europe/Istanbul — source collection and direct play, revision 6

Release `quiz-2026.10.02-2327-5121fbd`, source commit
`5121fbdcd2a67baf91df5bc2818a3d50b27a5d27`.
Runtime image `docker.io/library/quiz-master@sha256:44abc6c8c0f16cd416877e07b3e3f11438066cf6ac7c945df81780b67a2ad601`.
Actual pod API SHA256 `1ff63d17749776f308f43c2894a644e568000cfd882ac7cacd2223f1c4f1b322`;
public JS SHA256 `520a090cd563878051e9d73f5259d917081cca51501aa20742ba21c775ab6287`.
Both match public version.json. Runtime package remains at
`/opt/quiz-master/releases/quiz-2026.10.02-2327-5121fbd` on the verified node.

Sequential local Go/Flutter builds; remote runtime-only Docker build with
network=none/pull=false; nginx config check; docker save/containerd import and
explicit image digest alias. Helm lint with namespace, rendered server dry-run,
then flock-protected atomic upgrade, wait/timeout 180s. Revision 6: Deployment 1/1,
pod 2/2, zero restarts; existing PVC unchanged; certificate Ready True.
Revision 5 initially lacked the digest alias and hit ImagePullBackOff; registered
the imported digest alias and replaced only that failed quiz pod. Revision 6
included the alias before upgrade and completed normally. No SQLite deletion.

Preflight backup `/opt/quiz-master/backups/quiz-2026.10.02-2327-5121fbd.sqlite`
and separate `.restore-proof.sqlite`: integrity_check=ok, matching counts
13 participants / 110 attempts / 102 immutable bundles, private mode 0600.
These are on-node recovery checks, not off-node disaster-recovery acceptance.
Rollback revision 6 to 5 retains the PVC and needs no DB restore.

Public smoke exit 0: all 101 selected catalogs and attempt starts, 3128 questions;
nondefault cheese quiz finished with 19 answers/history/reveals; idempotent replay
PASS; foreign owner 404. Browser search, direct no-name launch, shareable selected
URL and answer/continue to question 2/19 verified. Desktop/phone screenshots in
`docs/rewrite-agents/reports/source101-*.png`; browser errors empty.
Language Learner revision 85 and JS SHA256
`520c6508fc7c9457b684c2d3210ae15322bdc2e9d1faf35b319958f55fbe66c7`
unchanged from its completed deployment; edge remains revision 10.
No local Docker/Postgres, Actions, extra agents or messages to the neighboring chat.

## 2026-10-04 — reviewed study library, revision19

Release `quiz-2026.10.04-study-5536e77` from pushed commit `5536e777139018bae2b244bfe7a586e73f5d5543`. Four independently accepted introductory articles/80 local unranked questions/four illustrated heroes integrated at `#/study`. Full release/backup/browser/hash evidence is in `study/reviews/release-evidence.md`.

Sequential local Flutter gates: 69 tests PASS, analyze clean, release web build PASS. Remote unchanged API binary reused and verified against running pod; runtime-only image build without pull/network. Lock held from baseline check through backup, import, strict Helm lint/server dry-run/atomic upgrade/public identity and JS hash checks. Namespace/release quiz-master only, image digest `6fd3e6d90203198b5a03975d9b3b6387821b504ae20a1bf63212ac8afd044b59`.

Revision19 ready: Deployment1/1, pod2/2 zero restarts, original PVC unchanged, certificate Ready True. SQLite online backup and restore proof integrity/counts match (54 participants/457 attempts/118 bundles). Rollback target18 preserves PVC; no DB restore performed. Every public selected catalog matches API (118 packs/3878 questions); study catalog4/80; existing practice feedback/ownership smoke PASS. Actual public article/practice/explanation native clicks and desktop/phone screenshots checked. Language Learner revision85/frontend stamp/hash and edge revision10 remain unchanged; no neighbor writes. No local Docker/Postgres or Actions.

## 2026-10-04 — production study wave2, revision20

User explicitly requested production publication. Released pushed source `3ebba4e6908ae314d966f6d53a5e11bc65486950` as `quiz-2026.10.04-study-3ebba4e` on verified `racknerd-f0269d5` / `192.3.164.184`, namespace/release `quiz-master`. Six accepted illustrated chapters/120 study questions; ranked catalog remains118/3878. Image `docker.io/library/quiz-master@sha256:5bc19e3f7f05176a68bdd56e3426ef45e030fd982a2d86105b72edcde40fc71b`.

Fresh Flutter69 tests/analyzer/release build passed. Runtime-only release used `bash release-study.sh quiz-2026.10.04-study-3ebba4e` from `/opt/quiz-master/releases/quiz-2026.10.04-study-3ebba4e`; output retained in `release.log`. Checksums, unchanged API hash, online backup/independent restoration, nginx test, containerd import/digest alias, strict Helm lint/server dry-run and lock-protected atomic upgrade passed. Preflight SQLite backup additionally downloaded and restored locally, integrity/counts56/458/119 match. Deployment1/1, pod2/2 zero restarts, original PVC retained, TLS Ready True.

Public stamp/JS/catalog/new hero hashes match packaged files. Full API smoke passed all118 catalog/attempt starts, completed19-question quiz/history/reveals/idempotent replay/foreign-owner404 and20+5 partition. Practice feedback boundary/no-store/invalid-mode checks passed. Actual public Flutter desktop/phone library/article/practice/incorrect-answer feedback verified. Exact evidence and rollback revision19: `study/reviews/wave2-production.md`. Observed edge11 and Language Learner85/frontend stamp unchanged across this release. Owned browsers/server closed; no neighbor writes.

## 2026-10-04 — mobile question layout, revision21

Published pushed source `e7a7617f78b8d6d2fe96e2369ea87287e30b0106` as `quiz-2026.10.04-mobile-e7a7617`. Image `docker.io/library/quiz-master@sha256:19b8134c9d85614c056d4b1f3d181ac504d8e0ec124e4bdf3d80d8e4c8275dbb`; public JS `d2d48f232230a9153f27aac5ef4fdcadeea736b0785f30d8fd3a173df89592c1`. Compact quiz title/round row and phone cards fix clipped six-choice questions. Independent review approved;72 Flutter tests/analyze/release build passed. Public360×640/390×736 and desktop screenshots, sixth-choice submission/explanation/Continue passed; browser errors empty.

Runtime-only, checksum/baseline/DEPLOY.lock/backup protected atomic release; existing API and catalog118/3878, study6/120 retained. Deployment1/1, pod2/2 zero restarts, original PVC, TLS Ready. Online and off-node restored backup integrity/counts61/581/119 match. Rollback revision20 preserves current PVC. Language Learner85 and edge11 unchanged. Exact evidence: `docs/rewrite-agents/reports/MOBILE_QUESTION_LAYOUT_2026-10-04.md`.
