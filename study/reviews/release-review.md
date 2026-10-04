# Independent release-script boundary review — 2026-10-04

Scope: read-only inspection of `deploy/quiz-preview/release-study.sh` and its
minimal deployment context (`Dockerfile`, Helm chart, `backup_sqlite.py`, nginx
configuration). No release command, Docker, Helm, Kubernetes, Git, source
compilation, or remote operation was executed. This report is not deployment or
publication approval.

## Verdict

**REQUEST CHANGES.** The release path is otherwise appropriately bounded:
build-ID/host checks, a non-blocking whole-operation lock, live baseline digest
guard, checksummed staged payload, online SQLite backup plus integrity/count and
independent restore proof, no-network Docker build/runtime validation, immutable
container digest registration, and namespace-scoped strict/template/server-dry
run plus atomic waited Helm upgrade are all present.

## Required finding

1. **`deploy/quiz-preview/release-study.sh:26` — post-deploy request does not
   verify the deployed release identity.**
   Trigger: the public endpoint remains routable but serves a cached/old
   `version.json`, or traffic reaches a different still-healthy workload. The
   final `curl -fsS https://quiz.kotopedia.org/version.json` only establishes
   HTTP success; it never compares the returned build ID or image digest with
   `$quiz_build` / `$quiz_digest`. Consequence: an atomic Helm success and
   reachable endpoint can still be reported as a successful cutover for the
   wrong version. Smallest correction: parse the response using an existing
   standard tool and require its declared build ID (and, if present, digest) to
   equal the values produced by this script; fail before declaring success.

## Direct review notes

- `set -euo pipefail`, the exact host check, restrictive build-name regex, and
  `flock -n` prevent accidental multi-writer and wrong-target execution.
- `backup_sqlite.py` opens the PVC database read-only, uses SQLite's online
  backup API, runs integrity checks, compares the three relevant table counts
  after an independent restore, and limits its destination to the backup root.
- The Dockerfile contains no build step; `docker build --network=none
  --pull=false` and the read-only `nginx -t` runtime check do not request a
  network. The Helm chart pins a supplied immutable image, uses one replica with
  Recreate, PVC preservation, non-root/read-only containers, probes, and the
  isolated namespace requirement.

## Reviewed hashes

- `deploy/quiz-preview/release-study.sh`:
  `749a2a92d3ff3ee32bfc9e2e022a5f322ed419bd17110bdbc0a5957a493db97d`
- `deploy/quiz-preview/backup_sqlite.py`:
  `54dde0fac9c13b34cc8c088b9cde66e75dba104d03f3a3cd257351c6dbcc456e`

No live host identity, current baseline digest, payload contents, backup result,
Helm rendering, rollout, browser endpoint, Android artifact, or publication was
verified by executing it here.

## Final added-lines re-review — 2026-10-04

**REQUEST CHANGES.** The added post-rollout deployment-image equality, public
`main.dart.js` SHA-256 comparison, and public-versus-packaged `version.json`
comparison all directly address the former reachability-only gap. However the
new JSON identity command still uses `assert`:

```sh
assert actual==expected and actual["buildId"]==sys.argv[1]
```

Trigger: invoke the script with `PYTHONOPTIMIZE=1` (or an optimized Python).
Python removes assertions, so a mismatched public `version.json` prints and the
release proceeds despite the intended guard. Smallest correction: replace that
assertion with an explicit conditional that raises `SystemExit` (nonzero) on
mismatch. This finding applies only to the newly added public-version check;
the digest and JavaScript checks are otherwise correctly fail-closed under
`set -euo pipefail`.

## Final one-line identity re-review — 2026-10-04

**APPROVE.** The new explicit predicate compares the complete public and
packaged JSON objects and `actual.get("buildId")` with the requested build,
then unconditionally calls `sys.exit("Public version mismatch")` on failure.
It is not an assertion and therefore remains fail-closed under Python `-O` or
`PYTHONOPTIMIZE`. The pre-existing digest and JavaScript checks continue to
cover the deployed image and public client asset. No release execution or
publication is claimed by this review.
