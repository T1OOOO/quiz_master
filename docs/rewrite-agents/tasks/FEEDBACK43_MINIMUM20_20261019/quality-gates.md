# Minimum20 integration verification (in progress)

The user selected related-topic merging plus additions to standalone quizzes. The local catalog has 105 visible banks, 4520 question slots and 56 legacy aliases. Twenty-three semantic pools and 38 new questions have separate exact-draft independent acceptance receipts. This is not a fresh factual certification of the entire legacy corpus; the legacy cat/dog quality follow-up remains `quiz_master-rplv`.

Verified after the alias-client correction:

- `flutter analyze`: no issues (6.6 seconds).
- `flutter test`: 280 passed (68 seconds).
- Article builder: 11 unit tests passed; `build.py --check` accepted 305 articles and original review hashes. There are 186 historical and 55 derived question references (241 total).
- Local SQLite HTTP candidate: all 105 banks / 4520 slots, 56 aliases, 38 imported questions graded both correctly and incorrectly with server receipts/history, 57 eligible difficulty starts, 363 short difficulty bands rejected. Article verification was explicitly skipped locally because runtime `/app` source hashes require the actual Linux candidate image.

Independent Google source review accepted the alias-routing and CLI guard corrections. Full Go `go test ./... -count=1` passed, including the expanded 20-question difficulty and taxonomy fixtures. The full Flutter rerun also passed. Actual Linux candidate verification remains required before publication. Production remains Helm69 / Deployment67, with 42 of43 original reports resolved. Original report26 stays open until the exact deployed minimum20 outcome passes independent and mobile verification.

No release70 build or publication has occurred. ImageFS capacity recovery is separately planned and reviewed before any next image operation. All current/rollback images, PVC, current backups and feedback are retained.
