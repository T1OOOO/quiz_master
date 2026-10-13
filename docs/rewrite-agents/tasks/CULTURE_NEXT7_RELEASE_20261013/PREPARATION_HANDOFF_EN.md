# Next7 release-packet preparation handoff

`C:/ap/quiz_master/.run/culture_next7_release_packet_20261013/prepare_next7_package.py` is a finite package-preparation controller. It does not build Flutter, start a process, access SSH, copy data, inspect a browser, publish, or change Git state.

Run it only after the source integration commit is frozen and the two fresh Flutter Web outputs have passed their own gates. Use the exact full commit SHA and the actual output paths:

```powershell
python .run/culture_next7_release_packet_20261013/prepare_next7_package.py `
  --repo C:/ap/quiz_master `
  --frozen-commit <40-lowercase-hex-integration-commit> `
  --production-web <fresh-production-web-output> `
  --qa-web <fresh-qa-web-output> `
  --output-root <new-empty-release-output-root> `
  --prior-archive C:/ap/quiz_master/.run/culture_next6_release_20261013/v8/quiz-2026.10.13-culture-328f2f8-v8.tar.gz
```

The two Flutter builds must have been made from `next/apps/quiz_app` using `QM_API_BASE_URL=https://quiz.kotopedia.org` for production and `QM_API_BASE_URL=http://127.0.0.1:18089` for QA. Both embedded catalog and Reader assets at `web-output/assets/assets/` must exactly equal the frozen source. QA is checked but never packaged.

The controller reads every changed content input with `git show <frozen-commit>:<path>` rather than trusting mutable workspace files. It verifies the immutable V8 archive SHA-256, safely copies only regular members, preserves V8’s older runtime repairs, replaces only the Cinema/Music People legacy and canonical triplets plus the catalog/Reader payload, and writes the 14-field `web/version.json` after the Flutter compiler output is copied. It records the frozen catalog and Reader byte hashes, and requires 131 packs, 4,044 questions, 242 accepted Reader articles, and 28 People questions in each pack.

It independently reconstructs the private canonical input from each of the eight runtime bundles and derives 140 staging revisions after changing only the staging source URI. It records 55 legacy New Year copy-only questions, giving 195 grading rows for the copied-data rehearsal. It replaces the three active JavaScript guards in `cutover.sh`, replaces both full source-commit guards with the frozen commit, updates the cutover metadata guards to 4,044 questions and 242 articles, checks the current production image baseline `sha256:ea742…07a804`, preserves the known PVC UID, preserves the API rollback hash `26e165…6f01`, updates the release values/build ID, and updates the rehearsal’s People Reader assertion to 28.

All generated scripts and checksum data use LF bytes. The controller creates a deterministic gzip/tar package and reopens it to verify every regular member’s path and SHA-256 against the stage. `package-preparation.json` is evidence of package preparation only.

Remaining release gates are owned by the lead: independent package review, Linux copied-database rehearsal and rollback, image build/import, Helm lint/template/server dry-run, isolated browser evidence, authorized atomic publication, and public verification. No release is implied by this handoff.

Static guard smoke check only: the controller was run against copies of V8 `cutover.sh`, `rehearse.py`, and `release-values.yaml` with synthetic values. It confirmed exactly three replacement JavaScript guards, two replacement full-commit guards, 4,044/242 embedded metadata guards, the expected image/PVC values, the People Reader count of 28, and release-values updates. This is not package execution or a release gate.
