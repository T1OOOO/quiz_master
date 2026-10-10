# Published culture encore batch

Published build `quiz-2026.10.11-encore-317b339`, application source commit
`317b3392dce5f2e2233e617d26ef0d31ba09d5e8`, Helm revision 30, October 11, 2026.
Adds ten cinema and ten music questions, twenty question-linked miniarticles,
and forty source links. Published totals: 130 packs, 3998 questions, 202 articles.

Authoring, independent native source checks, and actual Antigravity Gemini CLI
reviews are archived here with exact packet hashes. Gemini's content reviews
used supplied source evidence; they did not independently fetch the sources.
All twenty independent answers match the private keys. Distractors and article
wording were revised before acceptance. Existing catalog entries and articles
were preserved. Harry Potter's local distractor was reconciled to the already
published approved value, without changing its answer or live content.

Go content/catalog gates, four reader tests, Flutter analysis, 114 Flutter tests,
and the release web build passed; see GATES.md and archived logs. On a fresh
SQLite backup copy, all twenty new answers graded correctly, old table rows
were preserved, and the previous API passed rollback readiness. An initial
ten-second rollback readiness deadline was too short; READINESS_FIX.md records
the probe and correction. A fresh full rehearsal and Gemini script review
passed before the successful publication. The prior failed archive is retained.

The live deployment is available 1/1, with the new pod
`quiz-master-6c95f4c9bd-qqm6n` running 2/2 with zero restarts at verification.
Fresh pre-cutover backup:
`/opt/quiz-master/backups/quiz-2026.10.11-encore-317b339-cutover-20261010T232231Z.sqlite`.
Copy-rehearsal counts changed from `[88,88,655,229,14485,949]` to
`[88,88,655,359,14485,949]`; only the expected 130 bundle records were added.

Public verification fetched the actual version, JavaScript, catalog and article
assets, checked exact staged hashes, and validated 75 live question-to-article
bindings including all twenty additions. Public question DTOs contained no
private grading fields. See public-verification.json and package.json.

Browser checks used our isolated session on the published site. Both new packs
rendered choices; selecting an answer opened feedback and the article action.
Cinema's Spike Lee article and music's Vogue article opened and scrolled to two
source links each. Clicking the first links opened the expected BFI film and
Madonna Vogue pages. Both article tabs were checked at 360x640: DOM scroll width
equalled viewport width and there were no browser page errors. The music tab
initially opened at the browser default width; it was explicitly resized and
rechecked at 360x640. The final music question screenshot shows all four options
within the viewport. Screenshots were visually inspected; the browser session
and its tabs were then closed. No real feedback was submitted or resolved.

Read-only post-release feedback count remained 26 total, all 26 OPEN; latest
2026-10-07T08:19:08.506876077Z. This batch does not resolve earlier UX feedback.
All 69 unrelated workspace files matched their pre-existing hashes.

Deployed image:
`docker.io/library/quiz-master@sha256:3e9402747c700298eb756b927c7f028894ed5d3ed7efb9a83ca48b0f82a35636`.
Exact image was saved with Docker to
`/var/lib/rancher/k3s/agent/images/quiz-master-317b339-3e94.tar`, 73736704 bytes,
SHA256 `62f9e5e526a810cb503eb438fcf8b6ef3941e0b60226498ecd7b2dffb49ead21`.
The previous image archive remains intact. The unrelated stale pods were not
modified. The label-specific pod query in retained-image.txt returned no rows;
the subsequent explicit deployment/all-pods query confirmed the new ready pod.

Limits: no physical Android device test, full existing-bank factual audit, or
cache-loss server restart drill was performed in this batch. Those broader
tasks remain open. No GitHub Actions were run.
