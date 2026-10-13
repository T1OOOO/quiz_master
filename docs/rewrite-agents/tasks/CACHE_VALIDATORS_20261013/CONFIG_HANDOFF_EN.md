# Cache validator config handoff

Source copied exactly from:

`.run/culture_next7_release_root_20261013/package-v2/quiz-2026.10.13-culture-e437661/nginx.conf`

Target:

`next/infra/production/nginx.conf`

The target preserves the published configuration and adds only one explanatory comment plus these two server-context directives immediately before the existing `Cache-Control` header:

```nginx
etag off;
if_modified_since off;
```

The comment explains that normalized package mtimes require these validators to avoid stale conditional responses. No API, proxy, security-header, limit, or other behavior was changed. Runtime conditional-request checks were not run by this handoff; Root owns those checks.

## Evidence

- Source revision: `e437661`.
- Source and target were compared as UTF-8 text; target uses LF line endings.
- Fresh target SHA-256 and scoped diff evidence are supplied in the agent-hub READY submission.
