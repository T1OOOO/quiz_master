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
