# live-team-contract/v1

Separately versioned extension of accepted `quiz-contract/v1` for a live team
session. It reuses the base stable IDs, revision object, typed answers and
`scoring/v1`; it does not re-specify grading.

`schemas/live-team.schema.json` defines persisted session, invitation,
participant identity, pinned round, answer/receipt, replay and result-access
records. `schemas/live-events.schema.json` defines audience-specific event
payloads. `fixtures/positive.json` is deliberately representative rather than
an implementation API transcript. `fixtures/negative.json` is executable
adversarial coverage. Each negative case has a closed, typed operation input
and an `expected_error` identifier. Schema mutations carry a target, path,
closed mutation (`set` or `remove`) and validator; admission, authorization,
answer/close, result-access and replay cases carry their complete typed state
and command inputs.

The policy is fixed: 50 teams, one captain/final answer, shared reveal only
after close, no late join or timer pause, 128-bit QR/public-share credentials,
256-bit resume credentials, and the server/database time is authoritative.
The invite's 32 lowercase hexadecimal characters are a 128-bit random token;
the manual code has exactly eight Crockford Base32 characters excluding I, L,
O and U. Join failures are generic. An invitation expires at the earliest of
12 hours, lock/start, finish, revocation, or rotation. Public result shares
expire in seven days and are independently revocable.

Run from `C:\ap\quiz_master`:

```powershell
python -B next/contracts/live-team-contract/v1/check_contract.py --write-summary
```

The checker loads `../quiz-contract/v1/summary.json` and refuses any base
contract other than content hash
`5cc3275eb90dc71d58a5dc5d42be0fece52b727ead2bdf6ad9e7727a30df5f4e`.
`live-policy.schema.json` makes the admission/rate-limit, credential lifetime,
captain-transfer, idempotency, replay and public-retention rules executable.
The same operation validators are exercised with accepted inputs before the
negative cases. A negative counts only when its raised identifier equals its
declared `expected_error`; incidental rejection fails the check. The checker
also removes/adds fields to prove all ten operation inputs are closed and
replaces every non-`operation` fixture value with `IRRELEVANT`. The poisoned
inputs must not reproduce the 33 intended-error results; the deterministic
summary records the exact-match set and observation hash.
The checker is intentionally standard-library only and is an executable
contract, not a production JSON-Schema validator, transaction test,
cryptographic generator, rate limiter, WebSocket implementation or load
measurement. Those proofs are owned by P34, P35 and P38.
