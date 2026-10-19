# Actual retained-image resume: runtime evidence

The `resume-prepare` controller completed with exit0 on2026-10-19. It resumed the exact existing Docker engine image ID09cc and did not rebuild/retag the Docker candidate. It has not published Helm70.

Full local transcript SHA256: `d6c91c4c68e22ee81db384457eedba51ca80eed577edb179b851125b102ab355`.

Actual cloned-database grader output:

```json
{
  "visible_banks": 105,
  "visible_slots": 4520,
  "aliases": 56,
  "private_pooled_banks": 23,
  "new_questions_graded": 38,
  "eligible_started": 57,
  "short_bands_rejected": 363,
  "article_refs": 241,
  "archival_fallback_quizzes": 11
}
```

Nginx configuration test passed. All manifest/tree/API/source closure/backup restoration checks in the independently accepted controller completed before PREPARED. The baseline/current rollout is69/67; the next public rollout requires independent exactreceipt acceptance.

Controller tail (server dry run performs no configuration mutation):

```text
docker.io/library/quiz-master@sha256:09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee
==> Linting /opt/quiz-master/releases/quiz-2026.10.19-minimum20-7f8344d6/chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
Warning: resource networkpolicies/quiz-isolation is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
networkpolicy.networking.k8s.io/quiz-isolation configured (server dry run)
Warning: resource persistentvolumeclaims/quiz-data is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
persistentvolumeclaim/quiz-data configured (server dry run)
Warning: resource roles/traefik-ingress-reader is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
role.rbac.authorization.k8s.io/traefik-ingress-reader configured (server dry run)
Warning: resource rolebindings/traefik-ingress-reader is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
rolebinding.rbac.authorization.k8s.io/traefik-ingress-reader configured (server dry run)
Warning: resource services/quiz-master is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
service/quiz-master configured (server dry run)
Warning: resource deployments/quiz-master is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
deployment.apps/quiz-master configured (server dry run)
Warning: resource ingresses/quiz-master is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
ingress.networking.k8s.io/quiz-master configured (server dry run)
Warning: resource middlewares/quiz-rate-limit is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
middleware.traefik.io/quiz-rate-limit configured (server dry run)
PREPARED receipt=/opt/quiz-master/releases/quiz-2026.10.19-minimum20-7f8344d6/prepared-receipt.json image=quiz-master:quiz-2026.10.19-minimum20-7f8344d6@sha256:09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee
```

Image naming note: `new-docker-config-id.txt` is a historical filename. On this engine the actual `.Id` is index09cc; canonical CRI status and manifest are separately captured in prepared-image-evidence.json. Exported underlying image config is92a9a966fb7a5f478b273d9b2e8c4df47ef719fa66c6dcca6ba57df01448d130.
