# Final exact capacity packet review

Review submitted native tasksf36dd269 (fixture setup close),81499535 (three owned
read-only SQLite connection closes), and Root111cc888 (exact packet and corrected
atlas paths). Source72e165 was accepted for local scope only; its original
production script29cde was never run and must not be used.

The final production cleanup script is6be3e396697dab7966718148c61ee780a50c81f66e83d41354ddbb9f19b606eb.
It inherits the exact29alias/185preserved/52states/32protected plan and guards,
changing only three SQLite read-only connection contexts to explicit closing:
one house keeper integrity check and two reused preflight contexts. Process
checks still inspect our own PID. All legacy source/input bytes remain unchanged.

Root's actual first14-case Linux test failed on a fixture connection left open.
The later16-case test passed15 but hit a fixture helper parameter named uri,
which collided with uri=True. Both failed logs remain. Root's tiny fixture-v3
changes only that helper parameter/reference; it changes no production code.
The corrected exact e8ddaddd script actually passed all16 Linux cases, including
real two-group original-leak refusal/closed-house success and both exact preflight
read-only context expressions against temporary SQLite files. No production data
or alias cleanup was used. Do not claim the reviewer witnessed live SSH.

Root additionally caught an atlas path mismatch: the immutable package Dockerfile
copies web to /usr/share/nginx/html, not /app/web. The current immutable Reader303
image stateless read-only probe actually confirmed both atlas files there and
/app/web absent. A small Root composition changes exactly two path literals per
future preparation/collector script. Two local tests pass, syntax and embedded
Python compile checks pass. Old artifacts and metadata remain immutable; new
atlas-v2 contracts explicitly supersede only the legacy image-path assumption.
An actual new candidate is still absent and untested.

Review the full frozen execution-review-inputs.json manifest, full source and
actual receipts. Rerun bounded portable suites and atlas tests, inspect exact
rendered scripts and real Linux logs. Do not run SSH/network/Docker/Helm/browser/
Flutter/Git mutations/shared cleanup or children. Temporary local test files are
permitted. Independently choose accept/rework with concrete findings and full
manifest SHA/actual test exits/limitations in genuine Hub callbacks, notes below
1800characters. No fake or dictated verdicts.

Only accepted exact cleanup may stream the execution-plan.json command/script.
Capture full output and actual exit, preserve all185fullprivatekeepers/backups,
all52states, all32protectedresources, loaded image identities and healthy63/PVC/
HTTPS/full29OPEN feedback, with actual final strict20percent+1GiB. This reserve
still does not certify a later build peak. No private SQLite bytes leave host.

After actual cleanup, independently review its recorded outcome before the
corrected future resume-preparation-v2.sh runs. That future script retains old
failed prepare.log and uses a fresh nonce-bound resume log, unchanged fullcutover,
strict preflights and corrected stateless atlas gate. Actual collector rendering
requires actual run/image/durable hashes. Publication requires its own exact
execution review and public atlas/browser verification;483/feedback remain open.
