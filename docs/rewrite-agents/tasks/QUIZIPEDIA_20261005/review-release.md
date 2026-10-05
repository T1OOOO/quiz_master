# Quizipedia release-package review

**Reviewer label:** `review-release-quizipedia-20261005`
**Reviewed source identity:** `486df89432076e514660fbd6c520e1ca4bae2699`
**CI evidence reviewed:** run `37309587847`, reported successful for Go,
Flutter Web, and Android jobs.

## Verdicts

**Requirements compliance: ACCEPT for the package and cutover plan.** The
package is bound to the exact source revision and CI run, preserves the prior
API/content baseline, supplies the Quizipedia target inventory, and creates a
runtime-only cutover guard for the expected deployed image. The release plan
keeps production cutover, browser validation, and rollback as future operator
steps; none is claimed complete here.

**Code quality: ACCEPT.** The packager fails closed on the CI file manifest,
preserves immutable baseline bytes, writes a package checksum manifest, and
the generated release script retains the preceding release procedure exactly
apart from the version pattern and expected baseline image digest. The single
allowed missing CI path is narrowly named and disclosed.

## Static evidence

- `package.json` identifies build
  `quiz-2026.10.05-quizipedia-486df89`, source
  `486df89432076e514660fbd6c520e1ca4bae2699`, CI run `37309587847`,
  catalog `126/3958`, Study `6/120`, targets `20/6/6/8`, API SHA-256
  `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`,
  main JavaScript SHA-256
  `408cd7c98e3b6b38bdf621ecc14cf535afabaa48f657504ca78a4f4abe1006f5`,
  and archive SHA-256
  `2f820588291349228990f758c5dba7e5756223ac73d8b2280b1fe3a06d5313db`
  (`40,941,495` bytes).
- The helper accepts a 40-character lower-hex commit only, checks each CI
  digest and exact relative path, rejects traversal, duplicate runtime paths,
  altered files, and any extra artifact file. It verified the 67 delivered
  files before adding the release-specific public `version.json` record.
- Its only absent-file exception is literal path `.last_build_id`; it retains
  the unavailable CI digest
  `76d07cc6ea9643fff27ff427e79d3e53beef506ae5f68561342a0616dd86cf18`
  in the package report. Local Flutter SDK source
  `packages/flutter_tools/lib/src/build_system/build_system.dart` lines
  805--829 uses that file as an output-directory build-ID and prior-output
  bookkeeping marker. It is not copied as a served Web runtime resource.
- The source and staged Quizipedia asset directories each enumerate the same
  ten filenames: catalog, manifest, README, endocrine image, and six landmark
  photos. The helper compares every source file byte-for-byte before staging.
- The packager retains `api`, `next`, `quizzes`, chart, Dockerfile, nginx, and
  backup helper from the prior immutable release after verifying their staged
  SHA-256 values. It additionally verifies the preserved public catalog hash
  and inventory before package creation.
- The release-script transformation is exact: normalizing the prior
  `release-lotr.sh` by replacing only the release-name regular expression and
  prior expected image digest produces `release-quizipedia.sh` byte-for-byte.
  The new script rejects an unexpected host, takes the deployment lock,
  checks the expected current image
  `sha256:26aa85ea13934a9ddd4dd03c7b882b5e6cedc568e871b5ed63c4b20eac285c3d`,
  validates `checksums.txt`, runs online backup plus independent restored-copy
  checks, builds without network/pulls, validates nginx, server-dry-runs Helm,
  and upgrades atomically with a 180-second wait.
- The release plan specifies post-cutover public version and JavaScript hash
  checks, Quizipedia asset hashes, catalog/Study counts, health, existing
  attempt replay, and the exact Helm-revision-23 rollback command. It also
  correctly says never to restore the backup over newer player writes merely
  for this Web-only rollback.

## Remaining execution gates

This result is static review, not publication acceptance. Before production
use, the operator must perform the plan's current-host/image/lock preflight,
execute the backup-and-restored-copy check, perform the atomic deployment,
and complete the public and browser checks under a browser lease. If a
post-upgrade public check fails after Helm reports success, execute the
documented rollback and verify the prior public version/image; the generated
script exits on that failure but does not itself invoke the rollback command.
