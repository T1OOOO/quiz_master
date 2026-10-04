# Independent code review — actual Claude CLI reports

Provider CLI ran in plan mode, tools empty, strict empty MCP, no persistence. Requested alias haiku; actual model is taken from returned modelUsage.

## code-review

Actual model metadata: {"claude-sonnet-5": {"inputTokens": 2, "outputTokens": 12161, "cacheReadInputTokens": 3397, "cacheCreationInputTokens": 20391, "webSearchRequests": 0, "costUSD": 0.2038574, "contextWindow": 1000000, "maxOutputTokens": 64000, "thinkingTokens": 10873, "canonicalModel": "claude-sonnet-5", "provider": "firstParty", "costBasis": "list"}}

I reviewed the provided diff and files directly from the pasted content (no tools needed, since the full code and context were already supplied). Here's the review.

## Verdict: **APPROVE**

### Scope confirmed
Production code (`main.go`, `types.go`, the `content` package pipeline) is unchanged. The only changes are:
- A new standalone verification/import script, `integrate.py`.
- A count/ID bump in `catalog_test.go` (118→126 packs, 3878→3958 questions, + presence checks for the 8 new `theme-*` IDs).

### Chain-of-custody checks (the core of this review)

**Accepted-input hash pinning** — `accepted()` re-hashes `candidate.json`/`key.json` and compares against `input-sha256.json` recorded at review time. This correctly prevents a post-review file swap: whatever the human reviewers signed off on (`review.json` verdict `accept`, `blind.json` presence) is byte-identical to what gets imported.

**Option-to-answer mapping integrity** — this is the strongest part of the script. The chain is verified transitively through the whole pipeline:
- `[o['text'] for o in q['options']] == original['options']` — option order/text untouched by import.
- `[o['canonical_id'] for o in mapping['options']] == [o['option_id'] for o in q['options']]` — manifest's option mapping matches draft's actual IDs, in order.
- `q['grading']['correct_option_id'] == q['options'][original['correct_answer']]['option_id']` — the source key's `correct_answer` index lands on the exact same option that the draft/manifest/bundle agree is "option N".

Because these are independent equality assertions chained together rather than one blind trust point, any reordering or off-by-one in the pipeline would fail loudly rather than silently miscompute — including the zip-by-position pairing of `expected`/`draft`/`manifest`, which is self-correcting since a position mismatch would immediately trip the `question_id == source_id == canonical_id == qid` check.

**Private grading boundary** — verified at two levels: the published bundle question is asserted to contain none of `grading`/`correct_answer`/`explanation` (and this is also structurally guaranteed by `PublicQuestion` in `types.go` having no such fields), and `bundle['private_grading'][qid] == q['grading']` ties the private side back to the draft correctly. `catalog.json` is checked to expose only the 5 allowed metadata keys, matching the existing production invariant.

**Go test change** — minimal, consistent with the existing pattern; just updates expected totals and adds presence checks for the 8 new IDs. No new assertions logic beyond what the existing test already enforced.

### Required findings
None.

### Optional findings
1. No explicit check that `key.json`'s `distractors`/`correct_answer` text content actually corresponds to `candidate.json`'s `options` (only counts/types are checked). This gap is covered by the upstream human review + hash-pinning, but a cheap `set(k['distractors']) | {chosen correct text} == set(q['options'])` assertion would remove reliance on that external step.
2. The 80-question duplicate-ID check (`all_ids`) only dedupes within this batch, not against the pre-existing ~3878 questions in the rest of the corpus. Appears low-risk since grading is scoped per-bundle (`private_grading[qid]` is per-quiz, not global), but worth a one-line comment if global question-ID uniqueness is ever assumed elsewhere.
3. `hashes[p.name]` raises `KeyError` rather than a clean `assert` if an entry is missing from `input-sha256.json` — cosmetic only.

None of the optional items block merge; they're hardening suggestions for a script whose job is exactly the kind of belt-and-suspenders checking it's already doing well.

## code-review-final

Actual model metadata: {"claude-sonnet-5": {"inputTokens": 2, "outputTokens": 9386, "cacheReadInputTokens": 8518, "cacheCreationInputTokens": 15092, "webSearchRequests": 0, "costUSD": 0.1559356, "contextWindow": 1000000, "maxOutputTokens": 64000, "thinkingTokens": 8343, "canonicalModel": "claude-sonnet-5", "provider": "firstParty", "costBasis": "list"}}

## Review: source_sha256 fix + .gitattributes

**Verdict: APPROVE**

### What I checked

**Hash computation fix (`integrate.py` verify vs `canonical.go`/`import.go`)**

- Go's `SourceSHA256` is `hashBytes(canonicalSourceBytes(b))` where `b` is the raw file bytes from `os.ReadFile`, and `canonicalSourceBytes` does exactly: `\r\n → \n`, then `\r → \n`, nothing else (no reserialization, no BOM stripping).
- Python's new verifier does: `path.read_bytes().replace(b'\r\n', b'\n').replace(b'\r', b'\n')` — identical two-pass, left-to-right, non-overlapping replacement semantics in the same order. For any byte sequence (including edge cases like `\n\r`) both produce bit-identical output to each other.
- This is a real fix: the old approach (reserialize sorted JSON) would never have matched quizctl's actual byte-preserving behavior, since the assembled files use `indent=2`, insertion-ordered keys, and `ensure_ascii=False` — not sorted/compact canonical JSON. The new check hashes the real on-disk bytes the same way quizctl does, so it's actually verifying what will be imported, not a reconstruction.
- `source_path`/`canonical_quiz_id` cross-checks are unchanged and still correctly tie the hash to the same file identified in the manifest.

**`.gitattributes` (`-text` on `*.candidate.json` / `*.key.json`)**

- Scoped correctly: the file lives in `docs/rewrite-agents/tasks/THEMATIC80/`, so the patterns only apply under that subtree (franchises/screen-games candidate+key files), not repo-wide.
- This protects exactly the integrity check that needs raw, unnormalized bytes: `hashes[p.name] == hashlib.sha256(p.read_bytes()).hexdigest()` against `input-sha256.json` pinned by reviewers. Without `-text`, a checkout with different `core.autocrlf`/line-ending settings could silently flip bytes and break that check (or worse, silently change reviewed content). `-text` is the standard, sufficient mechanism to disable that normalization — no need for also setting `binary`.
- It does *not* apply to the assembled source quiz files (`quizzes/Cinema/Thematic80/*.json`), which is correct — those are allowed to vary in line endings across checkouts because the CRLF-normalizing hash check above already accounts for that.
- No production Go code touched, confirmed by reading `canonical.go`/`import.go` — the fix is entirely in the task-local Python verifier and a task-local `.gitattributes`.

**Security/robustness:** no path traversal (all paths built from a hardcoded `PACKS` dict), no untrusted input, no injection surface. Redundant `utf8.Valid` check in `canonicalSourceBytes` (already checked in `decodeJSON`) is harmless duplication, not a defect.

No required changes.
