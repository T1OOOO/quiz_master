# Local browser evidence — 2026-10-04

Scope: generated `study/site/index.html`, opened as a local file in an isolated `quiz-study-0oj` agent-browser session. This is not a production test or Flutter deployment.

- Desktop screenshot inspected: warm parchment background, illustrated cards, header/home button. Native browser clicks opened geography and started its practice round.
- A script exercised all 80 questions: shuffled-option mapping equals the original keyed answer; explanations match; modal appears; wrong answer waits; pause clears the correct-answer timer; each 20-question round scores 19/20 for one deliberately wrong answer. Correct auto-advance observed after 1.2 seconds, with a one-second configured delay.
- Mobile viewport 390×844: inspected screenshot, root scroll width equals 390 pixels (no horizontal page overflow), all four hero images loaded with nonzero natural width.
- Geography article at 390×844: eight section headings, root scroll width 390; inspected the horizontally scrolling TOC and article screenshot.
- Screenshots are local generated evidence in ignored `study/site/`: home-desktop.png, question-desktop.png, home-mobile.png, article-mobile.png.
- An axe invocation on file:// reported zero checks performed; it is NOT an accessibility PASS. Keyboard and modal behavior still need the independent reader review.

## Reader review corrections

The independent code reviewer requested four corrections. Regression tests were first observed failing: invalid module IDs under optimized Python escaped validation; a missing/duplicated template payload marker did not fail; malformed hashes caused a routing error; the next question did not receive keyboard focus. All four were then corrected.

Fresh checks after corrections: `python study/check_reader.py` and `python -O study/check_reader.py` each ran five tests successfully; `python -O study/build.py --check` validated four modules/80 questions; the browser smoke repeated all 80 cases and asserted heading focus after the one-second transition; `browser_routes.js` checked two malformed hashes and fallback to home. The script extracted from `reader.html` passed `node --check`. These are local scoped checks, not a full Flutter/backend suite.

Reproduce after `python study/build.py --write`:

```powershell
agent-browser --session quiz-study-check open file:///C:/ap/quiz_master/study/site/index.html
Get-Content study/browser_smoke.js -Raw | agent-browser --session quiz-study-check eval --stdin
Get-Content study/browser_routes.js -Raw | agent-browser --session quiz-study-check eval --stdin
agent-browser --session quiz-study-check close
```

The script uses DOM button clicks and internal state assertions. It checks application logic, not physical mouse/touch hit testing. Native UI clicks were separately used for article/practice navigation.
