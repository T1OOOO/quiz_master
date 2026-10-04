# Reader implementation review — 2026-10-04

Scope: `study/build.py`, `study/reader.html`, `study/check_reader.py`, and the
local-reader contract in `study/README.md`; no content facts reviewed.  Target
snapshot: Git `10436f501fe8b08ba74776e5e3b44aa8afa6d065` with the scoped files
untracked.  SHA-256: `build.py` `6BFA5D1C7E0C12E068009D717C89EA5AFECB97F69D88D36BB12014A36055BF20`,
`reader.html` `EFB77DD4EB1E6DC3F2B643D5FCDD2FAD0C816C4EDB8F9F96EA2B155CE419172B`,
`check_reader.py` `76104EB2AD5C4A669D44DF202919E5C86044EFFC6E906CD990CC2F9B0E396C59`,
and `README.md` `0B604766B01944CB40682ECA69BF2F35105731B49B7C0108D78B22527B4420E2`.

## Verdicts

- **Requirements compliance: REQUEST CHANGES.** The local, warm responsive
  article/TOC reader and 20-question unranked self-check model are implemented,
  and keyed answers intentionally stay in the local generated material rather
  than a ranked server flow.  However malformed fragment URLs blank the reader,
  generation integrity can silently be skipped, and automatic progression loses
  keyboard focus.
- **Code quality: REQUEST CHANGES.** The code is compact, bounded (four modules
  / 80 questions), dependency-free, and the Markdown renderer correctly escapes
  raw HTML and restricts link schemes.  Its validation and focus-management
  boundaries need the small corrections below before acceptance.

## Required findings

1. **`study/reader.html:36` — malformed URL fragment aborts the whole reader.**
   Trigger: open `site/index.html#%E0%A4%A` (or change the hash to `%`).
   `decodeURIComponent` throws `URIError`; because it is unguarded both at
   startup and in `hashchange`, `home()`/`article()` are never reached and the
   main region stays empty.  Independent reproduction: Node reports `URIError`
   for both strings, matching the JavaScript primitive used here.  Smallest fix:
   route fragments through a `try/catch` decoder which falls back to `home()`
   (or an empty ID), and call that single router for initial load and
   `hashchange`.  Add a malformed-hash regression check.

2. **`study/build.py:97-137,166` — the documented `--check` contract relies on
   `assert`, so `python -O study/build.py --check` removes every structural and
   rendered-parity check.**  This command still prints `PASS` for the normal
   tree but would not enforce the advertised IDs, question count, blind boundary,
   or stale-output comparison.  The README promises these validations at
   `study/README.md:16`.  Smallest fix: replace build/input assertions with an
   always-on `require(condition, message)` that raises a normal validation
   exception; cover at least one invalid fixture or monkeypatched invalid input
   under `-O`.

3. **`study/build.py:143-145` — a missing payload marker in `reader.html` is
   accepted as a successful build.**  `str.replace` simply returns the template
   unchanged if `/*__STUDY_PAYLOAD__*/[]` is edited out; `--write` then emits a
   reader with `modules` still empty and subsequent `--check` agrees with it.
   Smallest fix: require that this exact marker occurs once before replacement,
   and add a failure test for a markerless/duplicated template.

4. **`study/reader.html:30-32,35` — correct-answer auto-advance destroys the
   focused Pause button and leaves no focus target in the next question.**  The
   modal initially traps focus correctly, but after the one-second timer
   `showQuestion()` replaces `main.innerHTML`; `previousFocus` is assigned and
   never used.  Keyboard/screen-reader users can lose their place after the
   required automatic advance.  Smallest fix: give the next question heading a
   programmatic focus target (`tabindex="-1"`) and focus it after rendering (or
   focus the first answer); add a timer-path focus assertion.  The supplied
   browser evidence explicitly says its zero axe checks are not an accessibility
   pass.

## Verified behavior and evidence

- Fresh local commands at `C:/ap/quiz_master`:
  `python study/build.py --check` → `PASS: 4 modules / 80 questions ...`;
  `python study/check_reader.py` → `Ran 3 tests ... OK`.
- An independent deterministic permutation invariant over all four loaded
  modules passed: 80 local questions and every answer maps to the original
  keyed option after options are permuted.
- `check_reader.py` covers raw-script escaping, rejected `javascript:` links,
  safe article image/table rendering, and `</script>` payload escaping.  Manual
  source review confirms escaped text/attributes and only `http(s)`/fragment
  Markdown links are rendered.  No renderer-XSS finding.
- `study/reviews/browser-evidence.md` (author-provided, not re-run by this
  reviewer) records a real local-file browser smoke run: all 80 mappings and
  explanations, wrong-answer wait, pause, 19/20 state, 1-second auto-advance,
  normal navigation, 390-pixel mobile width, and four loaded hero images.  Its
  DOM smoke script does not independently cover malformed hashes, repeated
  activation/double-clicks, or keyboard focus; normal rapid answer activation is
  nevertheless synchronously guarded by disabling every answer at
  `reader.html:31` before feedback is exposed.
- Performance is bounded in this local artifact: four cards and one 20-option
  question set are rendered at a time; no network fetch, ranking, server DTO, or
  unbounded loop was found.

## Remaining risk

No content factual verdict, production/Flutter publication, or accessibility
conformance is claimed.  Re-review the changed reader/build/check scope after
the four required corrections and their targeted tests.
