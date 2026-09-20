# P09 observed RED → GREEN evidence

All commands ran sequentially from `C:\ap\quiz_master`; no Flutter commands ran.

| Test-first increment | Observed RED | Observed GREEN |
|---|---|---|
| Participant conversion, typed validation/scoring, canonical digest, snapshot permutation, duration/config | `go test -p=1 ./next/server/internal/attempts ./next/server/internal/config` exited 1: missing attempt functions/types and config fields (2.5399416s). | Same command exited 0 (4.312527s including formatting). Both packages passed. |
| PostgreSQL service lifecycle | `go test -p=1 -tags integration ./next/server/internal/attempts` exited 1: missing Options/Service/NewService (3.343885s). | Real PostgreSQL run passed after the timestamp correction below (6.3980383s including formatting/reset). |
| Strict HTTP and non-leaking errors/auth routes | `go test -p=1 ./next/server/internal/httpapi` exited 1: missing decodeAttemptJSON/writeAttemptError/AttemptRoutes (3.0329921s). | Same command exited 0 (5.0637883s including formatting). |
| API mounting preserves health | `go test -p=1 ./next/server/cmd/api` exited 1: newServer did not accept the attempt handler (3.2421s). | API/http unit tests and real bearer e2e passed after route/startup integration. |
| Development bundle default restricted to local listener | `go test -p=1 ./next/server/internal/config` exited 1: `TestNonlocalListenRequiresExplicitControlledBundle` reported silent development content selection (2.7977705s). | Config and attempts packages passed after requiring an explicit path for non-loopback listeners (6.2492933s including formatting). |

First real PostgreSQL lifecycle run failed two comparisons (`validation_ownership_replay_and_restart`, `concurrent_answer_and_finish`). Investigation traced the difference to pgx timestamp locations: initial values used UTC, read values used the driver's local location. UTC normalization at the history-read boundary fixed both without changing the instants or weakening assertions. The next lifecycle run passed. This was one substantive fix cycle.

Additional executable coverage verifies deadline-after-row-lock, different-key answer races, simultaneous answer/finish, persisted multiple-choice partial/exact sets and normalized Unicode text, raw bundle fail-closed loading, actual P04 response schemas, source/manifest independent scoring, and token/private-marker scans.

Final constraint inspection found PostgreSQL CHECK's three-valued NULL behavior needed an explicit guard. A new real-DB test ran RED with `go test -p=1 -count=1 -tags integration ./next/server/internal/attempts -run TestPostgresAttemptLifecycle/finished_row_requires_timestamp_and_history`: exit 1, 4.8232627s, `accepted finished row without finished_at`. Migration 0002 now explicitly requires non-NULL finished_at and finish_history in the finished state. The disposable public schema was reset, the modified migration applied from scratch and all final gates rerun; their current GREEN evidence replaces the earlier gate run in checks.json.

The first evidence wrapper invocation reached passing Go/unit/vet/PostgreSQL/P04 gates, then Windows PowerShell 5 argument handling broke an inline Python verification command. A standalone read-only helper removed the quoting boundary; P08 verification then passed. No accepted P08 evidence was rewritten. The final wrapper uses that helper and records native failures without terminating before their exit can be captured.

Disposable PostgreSQL startup initially hit a Windows reserved fixed port (55439). The exact not-started container was inspected/removed; retry with Docker-assigned loopback port succeeded at 64594. No shared resources were modified. Final gates are in `checks.json`; container and cleanup evidence is in `database.json`.
