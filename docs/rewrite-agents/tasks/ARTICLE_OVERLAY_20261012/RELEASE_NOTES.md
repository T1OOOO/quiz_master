# Reader overlay fix

Published quiz-2026.10.12-reader-4207ef5, source4207ef5e10f6bdd2b0a66d0a0d4d33251046b46b, Helm40. A shared article sheet now opens above the shell feedback overlay; the feedback button no longer covers article text and returns after closing the reader. One production line changed, covering quiz/results, study and Quizipedia article callers without new state, dependencies or callbacks.

The nested Navigator regression failed on the old layering and passed after the fix. Full116Flutter tests and analyzer passed, including Close and simulated systemBack feedback restoration. A native explorer/package helper and actual Claude code/static/prepared execution reviews were used. Fresh isolated QA and production web builds, backup restoration,116-question copy rehearsal, old-row preservation and oldAPI rollback passed. Atomic Helm consumed the reviewed immutable image; no GitHub Actions ran.

Exact public version/JS/catalog/reader and97revision bindings passed. Both People packs completed16/16 through the390x844 browser on fresh production JS. Four reader screenshots expose unobstructed body text, modal semantics exclude global feedback, and feedback opens again after Close. No report was submitted during feedback restoration checks.

Content remains131packs/4020questions/218articles, with byte-identical API/content/catalog/reader/taxonomy carryover. Existing PVC and26open real feedback reports are preserved; deployment Ready with no node pressures. Physical Android/screen reader and full-bank fact audit remain follow-ups. Disk95% used is tracked in5ux for safe cleanup of confirmed owned old rehearsal copies; backups/images/current/rollback/other projects remain protected.
