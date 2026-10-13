# quiz_master-74t: conditional cache regression

The published Flutter Web package normalizes archive mtimes to zero. Nginx's default ETag uses mtime and length, while Last-Modified uses mtime. Two different equal-length assets therefore share both validators. `Cache-Control: no-cache` requires revalidation but cannot correct a false 304.

The native mechanical helper copied the published configuration into `next/infra/production/nginx.conf`, preserving proxy routes, security headers and limits, and disabled ETag and If-Modified-Since handling in the server context. Root independently executed `check_cache_validators.py` using the existing immutable image on the authorized server. Two disposable Nginx containers used random loopback ports and synthetic JSON/JavaScript assets; the API and database were never started in these containers.

`regression.json` records actual results. For each equal-length, mtime-zero changed asset, the old configuration returned 304 for If-None-Match, If-Modified-Since and both headers. The corrected configuration returned 200 with the new bytes for all six requests. Both configurations passed Nginx syntax checks and preserved the five expected cache/security headers. Before/after checks confirmed the production image, deployment generation, readiness and PVC identity were unchanged. Owned containers and temporary directories were removed.

The first remote harness attempt failed before execution because its embedded Python string contained an unescaped newline. `harness-v1-error.txt` preserves that failure; the corrected harness then exited zero. This is not a claim that a production user already encountered stale bytes, or that the fix has been published.

Release scope is configuration only: reuse the verified application image as a hash-checked base, replace only Nginx configuration, prove all API/Web files remain identical, and retain the application build ID/source metadata. A distinct infrastructure image and Helm revision identify the hotfix. No question, article, database or Flutter source change is included. Independent configuration and exact execution review are required before publication.
