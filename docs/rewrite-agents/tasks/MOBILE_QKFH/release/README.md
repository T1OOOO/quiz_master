# MOBILE_QKFH frontend-only release executor

`release_executor.py` is a prepared production controller. Its default mode is
a local `--plan`; it cannot reach a remote host unless an operator passes both
`--execute` and `--acknowledge-production`. Execute mode creates a fresh private
release directory over SSH, streams only `web/`, `chart/`, the input manifest,
and generated Dockerfile, then runs the guarded remote transaction. Root owns
execution and records actual results in the parent task directory.

The controller accepts only `racknerd-f0269d5` or its pinned `192.3.164.184`
address, still verifies the remote hostname, and requires an explicit existing
SSH identity file for execution. It binds Helm release `quiz-master` in namespace
`quiz-master`, Helm revision `64` and separate Deployment revision `62`, immutable base image
`dc230d8…`, the retained `quiz-data` PVC UID, and its expected SQLite path. It
refuses overwritten release folders or backups, takes `/opt/quiz-master/DEPLOY.lock`,
checks source package/chart/version checksums, uses an exact Dockerfile that
copies only `web/` to `/usr/share/nginx/html`, verifies `/app/api` and nginx
configuration are byte-identical to the base image, then uses the baseline local
Docker tag `quiz-master:quiz-2026.10.15-country483-3c22818` and an immutable
local release tag. Docker image IDs and containerd manifest digests are verified
as separate values.

The remote sequence uses an SQLite `.backup`, integrity check and restore proof;
hashes the `feedback_reports` table without emitting rows; applies a bounded capacity
formula; renders/lints the unchanged chart; upgrades with
`--reuse-values --atomic --wait`; rolls back to Helm revision 64 on failure; then
records and verifies public `/version.json`, `main.dart.js`, `/health/ready`,
and `/health/live`. It makes no API, data, schema or chart change.

Run the local negative guards from this folder:

```powershell
python test_negative_guards.py
```

Root owns the clean Flutter web
build with `QM_API_BASE_URL=https://quiz.kotopedia.org`, package construction,
the independent AGY review, any eventual remote transfer, and publication.
