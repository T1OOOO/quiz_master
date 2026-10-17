# Flag restoration review

**Reviewer:** feedback43-flag-review-20261017
**Mode:** read-only native review
**Reviewed:** 2026-10-17

## Source freeze

| File | SHA-256 |
| --- | --- |
| `stage_flags.py` | `D9C30EA49E6729AA7480E019A56B95735587A7DE8526925C159149BF74215EBC` |
| `check_flag_tree.py` | `879B7CE33A31EC8A34D37CD6E004153EAD167AE619016FB5A315202EDC49BE28` |
| `check_flag_restoration.py` | `F75431C623D527DBBD71C345A098A5F02E59CD7C5182A50371CAD09DE11FC69A` |
| `flag-red-check.json` | `9C87C3F00EF09F05AECB5CB05B947443FF105A80EB7DD9A772092FE5C95C84D7` |
| `flag-green-check.json` | `6A7EBC71EF7436C811EF3FD284255F56F8540D69FA21E938EE50345AF2D13657` |
| `flag-restoration-checks.json` | `7B5C485335DD4D194D6F1D1DBAD2769ED4E372C40325D819D233E225404D7BDD` |
| `flag-webroot-observation.json` | `B33638A17CFBAAF797EEB82BC57DDEAD8F43CCC0E0688AF5A0F29A1E28726C95` |
| `.run/feedback_triage_20261017_0443/flag-http.json` | `A19C9F00031FE40C22734076FEACC9087868BA5D494EFD71CD50753196F520BD` |

## Findings

No actionable overwrite, traversal, or validation defect was found in the inspected current scripts.

- `stage()` refuses an existing fixed staging target before it can copy a file. It validates the entire cache before it creates that target, then creates a new `flags` directory with `exist_ok=False`.
- `check()` accepts only filenames matching 64 lowercase hexadecimal characters followed by `.png`; it reads each requested file, checks the PNG signature, and compares the SHA-256 digest to that filename. This constrains catalog-derived paths and detects altered cached bytes.
- The required unique closure is exactly 195 names. The final validation is run over the copied target, so the result is evidence about staged copies rather than cache existence alone.
- The target is under the explicitly isolated `.run/feedback_triage_20261017_0443/restored-web/flags` path. Neither script contains release, webroot replacement, container, HTTP, or repository mutation logic.
- If a copy fails after target creation, the target is intentionally retained and a later call fails rather than overwriting it. That leaves an incomplete tree for inspection, which is consistent with the no-overwrite safety policy.
- `check_flag_restoration.py` is an offline disposable regression harness. By inspection, it changes `stage_flags` module globals only after importing it, creates all temporary state beneath the assigned ignored work area, and actually exercises no-overwrite, HTML, missing-file, traversal, and invalid-cache/no-output branches. It does not invoke a network, browser, container, or release command.

## Receipt assessment

The red receipt establishes the previous published package lacked a requested PNG. The green receipt establishes only an isolated 195-image static-media closure. The permitted HTTP observation reports `200 text/html`, not PNG bytes, for a representative production URL; the webroot observation reports the flags directory and reported PNG missing. These receipts support an unresolved deployment/runtime defect, not a production repair.

## Verdicts

- **Requirements compliance:** accepted for the narrow offline staging/checking behavior by source and receipt review.
- **Code quality:** acceptable for the bounded media-only staging operation; fail-closed checks and no-overwrite behavior are appropriate.
- **Release/runtime:** not accepted. Root must finish its final checks and any separate deployment work must establish PNG-serving production evidence.

## Checks not run

No scripts, tests, build, browser, container, or HTTP requests were executed by this reviewer. Its recorded six-case offline receipt was inspected; no private feedback data was read.
