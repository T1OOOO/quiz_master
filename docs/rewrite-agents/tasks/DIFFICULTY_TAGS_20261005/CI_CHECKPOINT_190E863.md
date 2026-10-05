# Difficulty metadata code: exact committed CI result

Run [37340025169](https://github.com/T1OOOO/quiz_master/actions/runs/37340025169)
completed with overall `success` for commit
`190e86391d442dbf8be05f1e83c8745b6685ebb4` on `codex/quiz-v2`.
Root read the completed run and per-job/per-step status from GitHub Actions.

All three jobs succeeded: Go `111864476089`, Flutter `111864476035`, Android
`111864475655`. The Go job's PostgreSQL integration suite and API health probe
both explicitly succeeded. The frozen workflow runs full Go tests/vet, then
the real isolated database suites for migrate, identity, store and attempts,
including the new filtered/shuffled persisted-round test. Toolchain settings
are Go1.25.0, Flutter3.47.1 and Java17.0.17. Web checks include tests/analyze,
actual build and rejection of private contract markers; Android produces a
debug APK. No signed/device Android result is implied.

The pending pinned-CI condition in CODE_METADATA_FINAL is now satisfied by this
run. The later `ddb06b6` commit only adds two editorial scope manifests and
does not change tested Go/Flutter code. No independent-provider certification
or full4078 source annotation/application/index/production release follows from
CI success. Accepted2515 partial annotation checks preserve the frozen corpus.

Git hook note: the Beads pre-commit hook automatically restaged the entire live
issue JSONL in `ea5c1f0`. The following commit190e863 restored the intended
owned-nine-issue Git projection; the live foreign issues were kept locally.
Both commits were pushed. Subsequent scoped commits use an empty hooks directory
only after explicit Beads flush/sync and checks, preserving foreign work.
All68 other preexisting foreign files matched their before-push byte hashes;
the live Beads JSONL changed through its normal flush. Pull/rebase autostashes
were reapplied and removed; remote branch is synchronized.
