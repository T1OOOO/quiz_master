# Cache-policy package controller handoff

`prepare_next_package.py` is a new, owned copy of the reviewed Next7 package
controller. It retains the immutable V8 archive input and its checksum/template
guards, while pins the current Helm47 baseline image to
`docker.io/library/quiz-master@sha256:fa00bc8e559ec5a02ed62903f7ed91c00540f11de0a16b0cddc5b15717f5317f`.

For every accepted frozen Git commit, the controller reads
`next/infra/production/nginx.conf` with `git show`, requires SHA-256
`e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc`, and
writes those exact bytes to staged `nginx.conf` before checksums and archive
creation. It rejects a missing path, a changed source hash, a staged byte
mismatch, or a staged Dockerfile without
`COPY nginx.conf /etc/nginx/nginx.conf`.

The generated cutover script checks the staged file hash and, after local image
build but before image import, Helm lint/template/server dry-run, or Helm
mutation, checks `/etc/nginx/nginx.conf` inside the built image. Package output
records `nginx_config_sha256` in `package-preparation.json`.

The controller prepares only. Existing compiler outputs can be used solely as
Root's packaging-regression fixtures; they do not prove a freshly built release
artifact. A real next full release still needs fresh artifacts and the remaining
release, review, rollback, image, Helm, and browser gates. This handoff makes no
deployment or publication claim.
