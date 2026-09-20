# P33 live-team v1 policy decisions

Status: accepted lead input for the P33 contract task. These decisions freeze the first contract version; implementation still requires P34–P38 acceptance.

## Reveal, answers and scoring

- The host's private control stream receives each committed team answer and acceptance time immediately. The submitting team receives a committed receipt immediately. Neither the team nor the public presenter receives correctness before the round closes.
- Correctness, the correct answer and the explanation are shared only after the host or server closes the round and the host reveals it. Live-team v1 has no immediate-private-correctness option; adding one requires a versioned policy amendment.
- One captain device may answer for each team. Submission is final; same-key/same-payload replays the receipt, while a different payload or a second accepted answer conflicts. Host-authorized captain transfer revokes the old captain's write authority but does not alter an already accepted answer.
- Scoring reuses `scoring/v1`: one point for correct single choice, exact-set multiple choice, explicit normalized-text variants and no speed bonus. Ties remain ties.

## Admission and identity

- Admission closes when the session starts. There is no late join, pause or resume-timer behavior in v1. Auto-close when all teams answer is a session setting and defaults to false.
- A QR invitation contains a random 128-bit token encoded as 32 lowercase hexadecimal characters. The manual code is eight collision-checked Crockford Base32 characters excluding I, L, O and U. Neither is a host, team or resume credential.
- An invitation expires at the earliest of 12 hours, admission lock/session start, session finish, explicit revocation or rotation. Rotation does not revoke existing participant resume sessions.
- Join failures use a generic response. Per session, a device may make 10 failed manual-code attempts per 10 minutes; a public IP may make 300 join attempts per 10 minutes so a venue NAT is not treated as one player. Successful joins are still bounded by 50 teams per session and one captain credential per team. Rate-limit storage and exact HTTP status belong to P34 but cannot weaken these limits silently.
- Participant/captain resume credentials are separate random 256-bit tokens, revocable, and expire at session finish or after 24 hours, whichever comes first. Team-name equality never grants membership. Existing-team access and captain transfer require host authorization.

## Concurrency, transport and access

- Authenticated HTTP handles create/join/control/answer operations; WebSocket carries live events and reconnect replay. MCP is not a player transport.
- Answer acceptance and close serialize on the persisted round. An answer commits only while the round is open and the server/database acceptance time is not after the deadline. A manual close that serializes first rejects a racing answer; an answer that serializes first remains accepted. A unique `(session_id, round_id, team_id)` constraint prevents double scoring.
- Every accepted mutation advances persisted room version/event sequence and writes a replayable event in the same transaction or transactional outbox. Reconnect supplies the last seen sequence and receives contiguous missing events or an audience-filtered snapshot. Clients discard duplicates/stale versions and request a snapshot on a gap.
- Presenter, host-private, team-private and shared-reveal payloads are distinct closed types. Presenter events may expose team readiness/answered counts, never selected answers, grading or credentials. Host-private arrival events may expose the submitting team's answer but not the private grading key. Team receipts expose only that team's committed receipt and no correctness. Reveal payloads may expose the display answer and explanation after close.
- Full results are private to the authenticated host. A team can read its own accepted answers, receipts and permitted standings, never another team's raw answers. Explicit public sharing uses a separate random 128-bit read-only token, expires after seven days, is revocable, and exposes final standings plus revealed questions/explanations but no raw team answers or credentials.

## Capacity target

The first measured target is 50 concurrent teams per session. P38 must document hardware/network and demonstrate no lost accepted answers with p95 committed acknowledgment and host update within one second. This is a target, not a current performance claim.
