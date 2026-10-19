# Feedback implementation validation

Candidate source: `849e67056e55dc731e557c90016a27bbefacb2b6`.
Build: `quiz-2026.10.19-feedback-849e6705`.

- Clean sparse checkout: Flutter analyzer clean, all 250 Flutter tests passed.
- `go test ./next/server/...` passed. No claim of live PostgreSQL integration.
- Linux AMD64 API and Flutter release web build succeeded.
- API SHA-256: `95bca76bdf4bc8ad3dd74be44aae0cc936444fb86e74339ef793c825b74aa0f6`.
- JavaScript SHA-256: `f8e96ba51b7d3e6eceb9dbe67dd259db470d86041162af5f035bb5c4fd6baf11`.
- All 195 packaged flag PNGs match their canonical content-addressed hashes.
- All 13 compiled sections passed mobile browser practice: explore, choose a
  fact, answer incorrectly, retry, answer correctly, inspect 1/1 result.
  See `browser-results.json`. Chrome viewport was 390 × 844 with Flutter
  accessibility enabled; this is not a physical Android device check.
- A country-contour regression first failed against the former implementation,
  then passed with the polygon/hole containment correction. Targeted map tests
  and the subsequent full suite passed.
- Actual different-provider UI reviews accepted the corrected organ search,
  symbol layout, compact flags and contour changes. See review receipts.

Publication was a separate gate from these source checks. Its baseline was Helm
65; reports stayed OPEN until published bytes and behavior were verified. The
completed publication is recorded in `STATUS_EN.md` and the public receipts.
The binding release runbook requires at least 20% available space on
the k3s filesystem, copied-database HTTP grading, digest-pinned images, reviewed
preparation and a fresh backup immediately before publication.

Historical offload is reversible: an ACL-protected local archive retains all
old files, with per-file size and SHA-256 verification before removing any
server original. The current and preceding two releases, their images and
backups remain on the server. No other project's resources are eligible.
