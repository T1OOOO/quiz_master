# Controller delivery (not a release receipt)

Prepared a bounded, inert LOTR controller and synthetic negative-guard tests.
No package, build, Flutter, browser, database, SSH, Docker, Git, deployment,
publication, or acceptance action was run by this worker.

Fresh bounded checks from this worker directory:

- `python -m py_compile prepare_lotr_release.py test_prepare_lotr_release.py` exited 0.
- `python -B -m unittest -v test_prepare_lotr_release.py` exited 0: 15 cases
  passed. They include actual runtime/public/snapshot schema validation,
  135/4064/266 target-count computation and actual closed-browser receipt
  validation, plus synthetic mutations of an unchanged question, the retained
  `lotr-rk-95` key, its exact fourth retained `opt-5`, the snapshot bundle,
  an old Reader object, an old catalog row, catalog count and a tampered raw
  source pin while catalog/Reader inputs remain unchanged. All nine declared
  Root source-asset pins are compared against files below the resolved repo
  root; unsafe/escaping paths fail closed.
- `python -B prepare_lotr_release.py --pins ..\\root-validator-pins.json
  --prior-archive C:\\ap\\quiz_master\\.run\\screen_song_package_20261014\\package-v1\\quiz-2026.10.14-screen-song-6866608.tar.gz
  --baseline-cache C:\\ap\\quiz_master\\.run\\lotr_browser_20261014\\baseline-runtime-bundles.json`
  exited 0 with `VALIDATED_NOT_PREPARED` and counts `135/4064/266`.

SHA-256:

- `prepare_lotr_release.py`: `01accfae38ab81af218be8d5639d4cbaf9270af2c37a81ca78f938a04f573808`
- `test_prepare_lotr_release.py`: `a1c989127a4f575c6c9f83aa88079f08cbf73665e6f80633e5fadaeabe76828b`

Remaining gates are Root-provided real pins, independent controller review,
actual local browser proof, copied-DB rehearsal/rollback, and all release gates
listed in `RELEASE_PACKET_EN.md`.
