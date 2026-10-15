# SQLite lifetime finding from actual Linux tests

The independently accepted v1 source remains immutable. Its first actual Linux
fixture run returned1:13cases passed, one failed when the process-use guard saw
the fixture's own SQLite handle after a connection context exited. The isolated
same-runtime diagnosis returned0 and measured one open handle for context-only,
zero after explicit close. No production database or alias cleanup was used.

Root then reproduced the broader interaction using two temporary house groups:
the unchanged house integrity connection triggers the same guard before unlink;
adding an explicit closing context preserves the guard and lets both temporary
aliases be removed while both full keepers remain. The reused preflight has two
more read-only SQLite contexts that must also close before the next process check.
No own-PID exemption or suppressed process guard is acceptable.

Fixture-only taskf36 is frozen. New bounded task814995 owns adapter-v2, reusing the
accepted v1 core with exactly these three read-only connection lifetime fixes and
real temporary integration coverage. Old38 inputs, old29cde deletion script,
plan/protection files and all failures remain unchanged. The old deletion script
was never executed against production and must not be used for cleanup.

Root will inspect and run the corrected isolated tests under the standing test
authorization, then submit actual results and the exact new source/script packet
for genuine different-provider review before any production alias unlink.
Root task111cc remains RUNNING, with no exact execution approval or publication.
