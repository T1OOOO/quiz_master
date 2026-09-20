# Live team quiz with QR joining

Required scope added by the user on 2026-09-20. This is part of the full rewrite, not an optional future idea. Teams join from phones using QR links, see the current question and submit answers concurrently. The presenter/host receives updates immediately.

An optional clarification about “answers immediately” is pending. Planning default: the host's private control screen receives submitted answers immediately, teams receive a submission acknowledgment immediately, and correctness is revealed to everybody after the question closes. The alternative is immediate private correctness feedback to each submitting team. Keep these policies explicit; do not silently choose a reveal behavior during implementation. This document remains a design proposal until that product detail is settled.

## User experience

1. Host chooses a pack, creates a team session and sets the team limit, round time and scoring/reveal policy. Host control is authenticated; players can join as guests.
2. Host opens a public presenter view on a TV/projector. It shows title, join QR, short fallback join code, connected team names and readiness. Host controls stay on a separate private view.
3. A captain scans the QR. It opens the Flutter Web join route; no Android installation is required. If the Android app is installed, a verified app/deep link may open the equivalent route. Web is always the fallback.
4. Captain enters a team name or accepts an invitation to an existing team. The default is one answering device per team. Additional spectator/member devices are a later explicit extension; do not let a team gain extra answer submissions by joining repeatedly.
5. Host locks admission/starts. All teams receive the same round/question revision and deadline. The projector displays the question; phones display the same question and answer controls, so a remote participant can still play.
6. Captain chooses an answer and presses submit. The phone shows accepted/pending/error clearly; a retry returns the same receipt. Submission is final by default. If answer editing is desired, define it as a separate versioned policy before coding.
7. Host privately sees each team's answer, acceptance time and answered status as it arrives. The public screen can show a count/checkmark for answered teams, not their selected options or hidden answer keys.
8. Host closes the question manually or at the server deadline, reveals the answer and explanation, then displays the standings and moves on. Auto-close when all teams answer is an explicit session setting, off by default.
9. At the end, show team standings, round results and explanations. Persist the session history and offer a stable result link with defined access permissions.

The host may choose immediate private correctness for a casual game if the pending clarification selects it. In that mode, the submitting team receives only its permitted outcome; others' choices and the public correct answer stay hidden until the shared reveal. Players can still tell each other, so the product must not claim this setting prevents collusion.

## Proposed states and ownership

Session states: `lobby → active → finished`, plus `cancelled`. Round states: `prepared → open → closed → revealed → complete`. These are proposed contract enum values to freeze in P33, not existing API names. A host disconnect does not implicitly advance/reveal a round; the server deadline continues and the host reconnects to the persisted state.

| Entity | Required responsibility |
|---|---|
| Team session | Host identity, pack/bundle revision, settings, phase and state version |
| Team | Stable team ID, display name, membership/captain identity and admission status |
| Participant session | Verified guest/account identity, team binding, resume capability and expiry |
| Round snapshot | Question revision, option mapping/order, scoring policy, server open/deadline times |
| Team answer | Session/round/team IDs, answer payload, idempotency key, server acceptance timestamp and result |
| Event/outbox | Monotonic sequence, visibility audience, persisted transition and recoverable delivery |

A unique `(session_id, round_id, team_id)` constraint enforces one accepted answer per team under the default final-submission policy. Idempotency keys are bound to identity and payload. Room/round transitions and answer acceptance check status/deadline inside the same transaction or consistent serialized operation. A near-deadline answer and a simultaneous close have a documented deterministic outcome.

Use the same rooms/attempts infrastructure with an explicit team mode and shared grading rules. Do not copy a second in-memory game engine. Individual play/rooms remain supported. Team session results have their own scoring/leaderboard scope and do not silently inflate an individual's ranked history.

## Transport and QR rules

- QR encodes a scoped join URL/invite token, never a host credential, team control secret or answer key. Show a short manual code for cameras/network issues. Rotate/revoke admission when needed; joining a session is not permission to control it.
- P33 must freeze concrete invitation settings before P34: cryptographically random QR tokens (proposed minimum 128 bits), a collision-checked manual code (proposed eight unambiguous base32 characters), admission expiry/revocation, generic invalid-code responses and bounded failed-join attempts. Document per-device/session limits and a NAT-aware IP limit so a venue full of legitimate phones is not blocked. P34 tests brute-force throttling, expiry, collisions, revoked codes and a whole class joining behind one IP. Do not implement an unlimited manual-code lookup endpoint.
- Proposed admission lifetime is at most 12 hours and never beyond host lock, session finish or explicit revocation for new joins. Rotating an invitation does not revoke already authenticated players' resume sessions; those have their own expiry/revocation rules. Ratify exact values in P33 and expose only meaningful settings to the host.
- A join request exchanges that invitation for a distinct participant/team session. Reconnect identity is maintained separately from the public QR. Log URLs/tokens conservatively; validate callback/deep-link origins.
- A team-name collision does not grant membership or captain rights. Adding a device to an existing team requires an explicit authorized transfer/member invitation.
- Use authenticated HTTP for initial/join/answer requests and WebSocket for live events, unless P33 justifies another concrete transport. MCP is not a player transport.
- Every answer is acknowledged only after the authoritative write commits. Publish the corresponding event reliably; a transactional outbox or committed event log can support replay after a process restart.
- Events contain `session_id`, `round_id`, sequence/version and audience. Presenter, host, team-private and public payloads differ. Do not broadcast one answer-bearing payload and rely on the UI to hide fields.
- Reconnect requests include last seen sequence and receive missing events or a current snapshot. The client ignores duplicates/stale events and can recover from gaps.
- Phones display a timer derived from server time/deadline, but only the server accepts/rejects late answers. A device clock change cannot extend the round.
- Offline answering is unavailable in this live competitive mode. An unsent tap shows that it is pending; it must not appear accepted. Retrying after reconnect respects the original server deadline.
- Result-link access is private by default: the authenticated host sees the full session, a team sees its own accepted answers plus the permitted standings. Public sharing is an explicit host action with a separate read-only capability (proposed random 128-bit token, seven-day expiry and revocation), never reuse the join or host token. P33 fixes audience, expiry and retained fields; P34/P38 test cross-team access and expired/revoked links.

## Scoring proposal

First team release: fixed points for correctness; no latency-dependent speed bonus. This makes the first contract clear and avoids rewarding lower network latency. The host selects the agreed multi/text rules from the same grading engine. Any future speed bonus needs a documented server-time rule, fairness decision and boundary tests. Ties remain ties or use an explicitly approved tiebreaker; do not invent one in UI code.

Host controls include open/close/reveal/next, admission lock and removal of a team with a recorded reason. Their authorization and allowed transitions are verified on the server. Pausing/resuming an open timer, captain replacement and late joining after start need explicit rules in P33; defaults are no pause, host-authorized captain transfer, and admission closed after start. These are defaults for the lead to settle, not claims about legacy behavior.

## Tasks and handoff

| Key | Role | Dependency | Outcome |
|---|---|---|---|
| P33 | Lead + advisor + content/contracts | P04,P29 | Freeze team/round/event/reveal/scoring/QR contracts and example payloads before P05/P06, including admission limits/expiry, result-link access, reconnect and deadline races |
| P34 | Backend | P13,P33 | Team join/session persistence, guest/captain authorization, admission/resume and result-access policy; expiry, throttling and cross-team negative tests |
| P35 | Backend | P15,P34 | Concurrent team answers, authoritative scoring, reliable events, close/reveal and restart recovery |
| P36 | Flutter | P14,P33 | Host controls and public presenter view with QR; private/public payload separation |
| P37 | Flutter | P36 | Mobile Web/Android join, captain answering, acknowledgment, reconnect, standings and results |
| P38 | QA + independent reviewer | P35,P37 | Multi-client test matrix and agreed load measurement; real phones/Android and Web evidence |
| P39 | Quiz writer + fact checker + content | P31,P33 | Reviewed pilot pack appropriate for a live team round, matching supported types and explanation pacing |

P33 runs early, immediately after P04/P29; its combined contract version is an explicit dependency of P05/P06. P36 and P37 stay sequential under one Flutter owner unless split into disjoint files after common widgets/routes are accepted. Backend/Flutter may run concurrently against frozen fixtures. P25 waits for P35 so migration rehearsal includes team storage. P26/P27 require P38 and P39; this mode cannot be silently omitted at release. P39 reuses the accepted creative pilot when suitable rather than generating a duplicate batch.

## Acceptance matrix

- Host creates a session; two teams join via QR from separate phones with no app install; one Android app also exercises the same join flow.
- Same public QR cannot become host control; guessing another team name cannot steal that team's answer slot.
- All teams see the right round after refresh/reconnect. Public presenter payload contains no secret keys, selected private answers or host token.
- Simultaneous answers from many teams commit correctly. Two devices/retries for the same team cannot double score. Same-key/different-payload returns a conflict.
- Host sees arrivals without refreshing; team gets a committed receipt. The public reveal follows the configured policy exactly.
- Closing at the deadline, an answer racing close, an outdated round ID and a deliberately skewed phone clock have deterministic tested results.
- Restart the API during an active game; reconnect clients and host; previously accepted answers/scores survive and no round is accidentally revealed twice.
- Kick/leave, host reconnect, captain transfer and locked admission follow P33. Unauthorized users cannot call host commands.
- Verify QR legibility on a projected/large screen, manual code entry, 4–6 option layout, large text, keyboard access and network-loss UI.
- Start the load experiment with a **proposed** 50 concurrent teams per session; ratify the target/hardware in P33. Suggested acceptance: p95 commit acknowledgment and host update within one second on the documented staging network, with no lost accepted answers. Record measurements; these are targets, not achieved performance claims.

Use synthetic data and isolated local/staging clients for load tests. Test correctness under concurrency before increasing the target. A single-process first deployment can satisfy the agreed scale; horizontal deployment needs a separately verified shared event/broadcast design.
