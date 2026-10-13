# Actual local Flutter browser gate: publication blocked

Root used the official isolated chrome-devtools-mcp headless browser with a real 390x844 mobile/touch viewport and the fresh b9296af QA build. Cinema was answered through all 24 items and finished with visible score 24. Result answer headings were visibly readable. Feedback was opened and cancelled without submitting.

The new question 23 reader link was absent. Investigation used actual UI snapshots, successful API feedback, matching question revision c53894526896b8cffe6777777cd8be05b3bf3b2213f7d0bec18c3561cff82b77, and the real packaged reader JSON. All four newly integrated Next6 articles have status=draft. QuestionArticle.fromJson deliberately rejects every unreviewed article; QuestionArticles.decode parses the complete catalog, so these four entries prevent all 234 Reader links from loading. This is a real integration defect, not a missing source, bad revision or browser timing explanation.

Root froze both V1 and V2 release artifacts. Neither may be uploaded or deployed. Facts and bindings have prior independent accepted review, but review status was not propagated into the runtime reader asset. Fix only the four reviewed statuses, retain fail-closed decoding, add a regression loading the real packaged asset, then rebuild and repeat the actual reader/UI and release gates against the new frozen commit.

Task-only harness failures are separate: media emulation reinitialized the page; an IPC response file had a transient Windows read lock. Neither is an application defect. Their traces are preserved in .run/culture_next6_browser_root_20261013/v2. Current valid dark result screenshot and light/dark feedback screenshots are in that directory. No claim of successful local new-reader flow, Music completion, both result themes, Android or full-bank factual review.

Root closed its page, requested STOP for its isolated MCP client (actual exit 0), and stopped its own API/proxy wrapper (actual exit 0). Windows API terminated with exit 1 and its cleanup probe proved port 18092 free. No shared browser, broker, other project process, resource lease or production deployment was changed.
