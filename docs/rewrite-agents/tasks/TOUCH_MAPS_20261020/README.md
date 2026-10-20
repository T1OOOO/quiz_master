# Touch interactions across the atlases

Application source: `b5863403a7ef6b638f2674704dcb39b4c9c0bfad`.
Candidate: `quiz-2026.10.20-touch-b5863403`.

## Changes

Native touch in Flutter Web accessibility mode previously synthesized the centre of spatial canvases. A tap on Betelgeuse selected Mintaka. Spatial canvases now retain physical tap coordinates; named accessible controls remain available. Vertical dragging in nested maps now holds the parent page still for the duration of map contacts, including multiple fingers and cancellation. Normal page scrolling resumes after release. This covers sky, legacy visual practice, water practice, organs and beliefs. Country map selection still leaves camera movement under the user's control.

## Source verification

- 318 Flutter tests passed; analyzer reports no issues; release Web build passed.
- Regression tests failed first for centre-tap semantics and unwanted 45px parent scrolling, then passed for tap coordinates, actual scene movement, multi-touch release/cancellation, and restored parent scrolling.
- Local Pixel5 browser emulation: 393×851, DPR2.75, Android user agent, five touch points/coarse pointer. Native CDP touch selected Betelgeuse at the visible position, pinched and panned the scene while parent scroll stayed at zero; an outside drag scrolled the page after release. Anatomy pinch/pan was checked visually too.
- No physical Android device was connected. Browser emulation is not a physical-device result.
- Independent Google source acceptance: `source-review.md`; controller/archive acceptance: `controller-review.md`.

## Release invariants

All published images, physical backups, live PVC and original feedback rows are retained. The exact six redundant release75 staging inputs were copied to a restricted local archive and checked before removal. Plan and review bind the exact paths, lengths and hash. The full frozen local package remains available.

Disposable full SQLite restores/rehearsal use a candidate-owned 256MiB tmpfs after checking memory reserve, host, PVC and node pressure. The physical backup remains on disk. Full integrity/SHA/real HTTP grading proofs are recorded before normal unmount; the temporary filesystem ends before PREPARED and before Helm publication. Capture independently restores the physical backup into in-memory SQLite. Disk thresholds, GC policies and runtime API bytes are unchanged.

Published: Helm76 / Deployment74. Exact public asset bytes and health checks passed. `postpublish-state.json` confirms ready containers, unchanged PVC and full backup restoration. `public-mobile-checks.json` records partial mobile acceptance: sky gestures/photos passed, anatomy semantic overlays and long checked-answer scrolling need follow-up. No feedback reports were resolved on the basis of this partial check.

## Remaining feedback

Eight new screenshots were read privately: country thumbnail; unclear map layers; only six anatomy image markers; map loading; repeated explicit menu focus; visible neighbour names; long checked-answer scrolling; country labels while a previous selection is off-screen. Server statuses remain open until each result is checked. Raw report IDs, contexts, screenshots and backup data stay outside Git.
