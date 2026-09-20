---
name: qm-live-quiz
description: Implement or verify Quiz Master's live multi-team mode with QR joining, presenter screens and real-time answers.
---

Read the assigned P33–P39 contract/packet and the relevant part of LIVE_TEAM_QUIZ_EN.md. This supplements the backend, Flutter or QA role skill only for live team tasks.

QR joins a session, not host privileges. Issue a separate participant/team identity. A team-name match is not authorization. Default one captain/answering device per team; changing that rule requires an agreed contract. QR opens Web without installation and optionally the Android app through an equivalent deep link.

Separate public presenter, private host and team-private payloads. Host sees answer arrivals immediately; public correctness follows the explicitly agreed reveal policy. The initial planning default is shared reveal after close while the user clarification is pending. Do not silently turn receipt into correctness feedback or broadcast hidden keys.

Pin the round's content/scoring revision. Transactional acceptance checks team identity, round state, server deadline, unique team answer and idempotency payload. A committed answer receives a receipt; retries cannot double score. Persist events/state for reconnect and restart, with sequence/gap/duplicate handling. Client time and offline taps cannot create accepted answers.

Share the game's grading/room foundations instead of creating another engine. Test simultaneous teams, multiple devices for one team, answer-versus-close races, refresh, host disconnect, server restart and unauthorized control. Frontend checks include real QR scanning, manual code fallback, mobile layouts and projector visibility. Use approved target/hardware for load claims; never report a proposed latency goal as a measurement.
