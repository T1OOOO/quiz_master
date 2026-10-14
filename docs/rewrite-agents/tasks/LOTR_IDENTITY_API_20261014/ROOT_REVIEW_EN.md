# Root review of the owned backend checkpoint

Correctness: strict metadata validation is added before option/key construction. The existing answer index is checked and resolves through the same option ID used in manifest mapping. Revision defaults1 and positional long-ID fallback are unchanged when fields are absent. Actual negative cases reject malformed values; actual fixture compares98 complete non-target question and manifest objects at an identical source URI. No broader loader change is claimed.

Readability and architecture: two optional input fields reuse existing integer/nonblank/idPattern helpers. No new dependencies, framework, generic overlay loader or API endpoint was added. The separate identity regression keeps the import extension bounded. The raw contract fields are editor metadata, not visible answer hints.

Security: authoritative private grading remains in controlled bundles; errors expose only existing code/path, not answer keys. Full SQLite tests retain early/foreign disclosure guards, exact selected score/history and restart behavior for every source pack.

Performance: small per-question validation array/map with at most6 options; no network/storage loop or new indexing path. Existing defaults have equivalent complexity.

Evidence: worker actual targeted RED1/GREEN0 and content/quizctl0; Root actual full Go RED due stale unrelated selected-pack count; only three fixed fixture expectations updated to actual135/4064/135; Root full SQLite0 and subsequent complete local Go suite0. Exact outputs/hashes are saved. Official Claude50 independently accepted the importer source/test pair; the Root fixture needs its own independent review. Reviews are static, not invented repeated test runs.

Scope and limits: real production is untouched. Raw identity fields, regenerated source metadata, a new Linux API binary and exact candidate-image API/Reader checks are still required. An importer test passing locally does not approve a release. The actual-fixture test must construct an absent-metadata temporary baseline before the upcoming corpus change, as documented in NEXT_STAGES_EN.md. All unrelated working-tree files remain outside this checkpoint.
