# Quizipedia production cutover packet

Validated source: `486df89432076e514660fbd6c520e1ca4bae2699`.
CI: https://github.com/T1OOOO/quiz_master/actions/runs/37309587847 — all three
jobs completed successfully. Flutter formatting, analyzer, all 83 tests,
production API URL Web build, private-marker scan and checksum/artifact steps
passed. Go unit/source integration tests, vet, serial PostgreSQL migration,
identity/store integration and live/ready health probes passed. Android debug
build and artifact checksum/upload passed; this is not a signed release or an
Android device-runtime claim.

Fresh production preflight: host `racknerd-f0269d5`, SSH `root@192.3.164.184`,
namespace/release `quiz-master`, Helm revision 23, deployment ready 1/1, pod
2/2 with zero restarts. PVC `quiz-data` is bound to
`pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf`.
Current immutable image:
`docker.io/library/quiz-master@sha256:26aa85ea13934a9ddd4dd03c7b882b5e6cedc568e871b5ed63c4b20eac285c3d`.
Public version remains `quiz-2026.10.04-lotr-e38bb24` at this checkpoint.

New package must use the exact CI Web artifact for the validated source. Every
CI checksum is checked, with no unlisted extra files. Add a public version
record identifying that artifact, the source revision and the four-module
20/6/6/8 target inventory. API, quizzes, accepted Study and canonical content,
chart, nginx and database/schema behavior retain the verified previous package
bytes. API SHA256 must stay
`47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`.
The pending difficulty/tag migration is excluded from this release.

Before cutover: check target host, expected current image and deployment lock;
validate complete package checksums; perform online SQLite backup and an
independent restored-copy integrity/count comparison; create a small partially
answered verification attempt for post-cutover replay. Build the runtime image
without network/pulls, check nginx configuration, import into k3s by digest,
lint/render Helm and server-dry-run the rendered resources. Upgrade atomically
with readiness wait and a 180-second timeout.

After cutover: verify public version, main JavaScript and all Quizipedia asset
hashes, normal catalog 126/3958 and Study 6/120, health and the existing attempt.
Browser screenshots/interactions require a granted browser resource lease.
If publication or smoke checks fail, run `helm rollback quiz-master 23 -n
quiz-master --wait --timeout 180s` and verify the previous public version and
image. This release does not rewrite the live database; do not restore its
backup over newer player writes for a Web-only rollback.

At this checkpoint CI is accepted; artifact packaging, browser verification,
backup/restore rehearsal and production cutover remain pending. A resource
queue is not permission to run them.
