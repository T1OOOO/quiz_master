# Rehearsal readiness boundary

The first rehearsal preserved the live deployment and completed fresh SQLite
backup/restore and the new grading checks, but failed before publication while
starting the previous API for rollback. Its ten-second polling loop terminated
the still-running process at the startup boundary. The API log was empty.

An isolated probe copied the rehearsal database, started only our rollback
process as uid10001, and checked readiness and the LOTR catalog. Both endpoints
became HTTP200 at elapsed10 seconds; the probe then terminated and waited for
its own process. No production database or deployment was changed.

The rehearsal now uses a sixty-second monotonic deadline, retaining readiness
failure and old-API rollback as mandatory gates. The corrected scripts receive
another actual Gemini static review and a complete fresh-backup rehearsal.
The original failed release/archive were retained under the owned
`failed-readiness-quiz-2026.10.11-encore-317b339-20261010T231811Z` prefix.
Application/API code and the checked web assets remain unchanged.
