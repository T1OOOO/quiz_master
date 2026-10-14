# Reader-only release successor

`prepare_reader_release.py` makes a new, local output root from the immutable
Helm53 baseline. It requires SHA-256-bound build, source-review, browser-proof,
prior-Reader, and successor-Reader records. The production Web directory is
copied into the staged archive only after its recorded `main.dart.js` hash is
verified; the QA directory is evidence only.

The controller preserves every baseline non-Web byte except the Reader source,
the regenerated checksum manifest, and the cutover/verifier wiring. It confirms
the unchanged 136-row/4084-question catalog, immutable API and Nginx hashes,
and exactly six Reader additions (272 articles; 153 total, 151 playable refs).
It copies the established runtime verifier into the stage and rewrites the
prepared cutover to run its copied-DB, HTTP DTO, grading, reveal, rollback,
cleanup, and port-release checks with the Reader-specific counts.

It only prepares an archive. It never builds, runs a container, opens a
browser, deploys, or publishes.

Root corrected the submitted implementation after real helper/archived-gate
checks exposed defects hidden by synthetic fixtures. `REPORT.json` now describes
the current pending review; the historical V3 submission is retained outside
this directory. The actual current producer and LF source acceptances are
recorded in the sibling review receipts; remote helper approval is separate.
The CLI requires `--pins`, `--prior-archive`, and a fresh
`--output-root`. Pins bind the actual build receipt, source acceptance, browser
proof, full Web tree manifest, archived prior Reader, and frozen Git assets.
The controller review reuses the existing `qm-lotr-package-controller-review/v1`
receipt contract and binds three current controller files and three house
dependencies by absolute path and SHA-256. The prepared shell remains
prepare-only; publication is a separate independently reviewed operation.

Run the pure boundary checks:

```powershell
python -B -m unittest -v test_reader_release.py
python -B -m py_compile prepare_reader_release.py verify_reader_candidate.py test_reader_release.py
```
