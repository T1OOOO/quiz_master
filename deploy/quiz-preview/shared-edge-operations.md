# Shared edge operations for Quiz Master

## 2026-10-02T09:49:00Z — Codex, owner-authorized quiz namespace enablement

Target verified: root@192.3.164.184, racknerd-f0269d5. Owner explicitly approved
extending and restarting shared Traefik. Existing edge revision 9 is the rollback
target. Language Learner app/DB/content/images and backup policy remain unchanged.

Preflight commands:

```sh
hostname
helm list -n ingress-system -o json
kubectl get clusterrole traefik-ingress-reader -o yaml
kubectl get rolebinding -n language-learner traefik-ingress-reader -o yaml
kubectl get role -n language-learner traefik-ingress-reader -o json
helm get values edge -n ingress-system -o json
kubectl get networkpolicy -n ingress-system -o yaml
/opt/ll/helm/verify-release.sh frontend-2026.10.01-1139-9ff1963f05 backend-2026.09.27-2141-1e61a39de4
```

Results: edge 9 deployed, Language Learner frontend/backend build IDs and JS hash
match; release checks pass including read-only Web root. No ingress-system egress
NetworkPolicy exists. The reader is a namespaced **Role**, not a ClusterRole
(correcting the earlier Quiz operations note). Only quiz-master gets its own Role
and RoleBinding; shared controller namespace scope remains an explicit allowlist.

Shared update and public verification are pending at this log checkpoint.

## 2026-10-02T09:53:05Z — scope validation, Codex

```sh
helm get values edge -n ingress-system -o yaml > /opt/quiz-master/edge-revision-9-values.yaml
helm get manifest edge -n ingress-system > /opt/quiz-master/edge-revision-9-manifest.yaml
helm lint --strict /opt/ll/helm/edge -n ingress-system -f /opt/quiz-master/edge-revision-9-values.yaml -f /opt/quiz-master/shared-edge-quiz-values.yaml
helm template edge /opt/ll/helm/edge -n ingress-system -f /opt/quiz-master/edge-revision-9-values.yaml -f /opt/quiz-master/shared-edge-quiz-values.yaml > /opt/quiz-master/edge-quiz-rendered.yaml
diff -u /opt/quiz-master/edge-revision-9-manifest.yaml /opt/quiz-master/edge-quiz-rendered.yaml
cd /opt/quiz-master/releases/quiz-2026.10.02-0857-ef419ae
helm lint --strict chart -n quiz-master -f release-values.yaml
helm template quiz-master chart -n quiz-master -f release-values.yaml > rendered.yaml
kubectl apply --dry-run=server -n quiz-master -f rendered.yaml
```

Both charts linted with zero failures; quiz server dry-run passed. Shared render
diff changes only the two provider namespace arguments (plus one blank line).
No image, port, certificate, existing route, existing RBAC or network policy changes.

## 2026-10-02T09:54:00Z — scoped RBAC deployed, Codex

```sh
helm upgrade edge /opt/ll/helm/edge -n ingress-system --reuse-values -f /opt/quiz-master/shared-edge-quiz-values.yaml --dry-run=server --hide-secret > /opt/quiz-master/edge-quiz-server-dry-run.txt
cd /opt/quiz-master/releases/quiz-2026.10.02-0857-ef419ae
flock -n /opt/quiz-master/DEPLOY.lock helm upgrade quiz-master chart -n quiz-master -f release-values.yaml --wait --timeout 180s
kubectl auth can-i --as=system:serviceaccount:ingress-system:traefik list ingresses.networking.k8s.io -n quiz-master
```

Shared Helm server dry-run exited zero. Quiz release revision 3 deployed; controller
can now read quiz routes (`yes`). No quiz image or pod-template change.

Next owner-approved shared mutation (rollback: `helm rollback edge 9 -n
ingress-system --wait --timeout 180s` if readiness/Language Learner checks fail):

```sh
flock -n /opt/ll/PROD.lock helm upgrade edge /opt/ll/helm/edge -n ingress-system --reuse-values -f /opt/quiz-master/shared-edge-quiz-values.yaml --atomic --wait --timeout 180s
```

## 2026-10-02T09:55:10Z — shared edge ready, Codex

The approved Helm upgrade exited zero: edge revision **10 deployed**, Traefik pod
1/1 Ready, zero restarts. Post-release commands:

```sh
kubectl get pods -n ingress-system
kubectl get certificate -n quiz-master
/opt/ll/helm/verify-release.sh frontend-2026.10.01-1139-9ff1963f05 backend-2026.09.27-2141-1e61a39de4
kubectl get challenges -n quiz-master -o custom-columns=NAME:.metadata.name,STATE:.status.state,REASON:.status.reason
```

Language Learner release verification passed: identical frontend/backend build
IDs and JS hash, read-only Web root intact. ACME challenge resource was cleared;
certificate readiness/public smoke are checked next. No app or DB restart/update.

## 2026-10-02T09:56:13Z — public acceptance, Codex

```sh
kubectl wait -n quiz-master --for=condition=Ready certificate/quiz-master-tls --timeout=120s
kubectl get certificate -n quiz-master
kubectl auth can-i --as=system:serviceaccount:ingress-system:traefik list secrets -n default
```

Certificate Ready True; controller still cannot list secrets in default namespace
(`no`, expected exit 1). Public TLS validated normally, without insecure flags.
`deploy/quiz-preview/smoke.ps1` against https://quiz.kotopedia.org exited zero:
correct build, 25 answers, finished, 25 history entries, 25 reveals, stable replay,
cross-owner 404 and early-reveal protection. Web GET 200 with Flutter bootstrap,
HSTS and nosniff headers. Public main.dart.js SHA256 matched its version stamp.
Edge 10/quiz 3 ready; Language Learner app release unchanged (83).
No local Docker, Postgres, Actions, rebuild or additional agents used.

Future edge upgrades must retain `shared-edge-quiz-values.yaml` (or reuse live
values); resetting to the original three-namespace defaults would hide quiz again.
Rollback remains edge revision 9; this would intentionally remove public quiz
routing without touching its SQLite volume. App parity, off-node backup/restore,
load testing and independent-provider review are not claimed by this release.

Final read-only live inventory:

```sh
helm list -n ingress-system -o json
helm list -n quiz-master -o json
kubectl get pods -n quiz-master
kubectl get certificate -n quiz-master
kubectl get deployment -n language-learner language-learner-server language-learner-frontend
```

Exit zero: edge 10 and quiz 3 deployed; quiz pod 2/2, zero restarts; certificate
Ready True; original Language Learner server/frontend both 1/1 Available.
