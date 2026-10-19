# BELIEFS_A0IZ implementation evidence

Bead: quiz_master-a0iz. Feature branch codex/quiz-v2. No main merge or production deployment.

- Quizipedia entries: Greek gods; Religions and traditions. RU/EN relationship graph, manual pan/pinch/zoom/fit/reset, accessible searchable buttons, node facts, source/version-scoped relationships and source links. Selecting nodes preserves the camera. Full Greek graph has 21 nodes; religion reference has nine representative traditions. Coverage is explicitly selective.
- Reviewed asset: 30 nodes, 32 edges, 20 questions (11 Greek, nine religion). Greek rounds sample ten; religion rounds clearly state nine. Local unranked checking and finite mistakes review preserve the original score.
- Country map layer and practice: Pew affiliation estimates for 2020, published 2025; 200 matched countries/territories. Seven broad categories including unaffiliated and combined other religions. No inference of official state religion. Channel Islands aggregate deliberately not assigned separately to Jersey/Guernsey; missing estimates remain missing. Rounded ties do not generate a unique-largest-category question.
- Source fact review accepts canonical SHA256 94859807508313190bc035a2b5c3e01f60a7c80d3435fca89ecb586cd8216969; independent Codex code review approves. Raw Pew archive and country-code input pinned with reproducible importer. Rerun produced identical country asset SHA256 bd13d464c47786b5d874add7ea18bb751c485322ea685c492a9d22556d97cb7b.
- Verification: focused 17/17; full Flutter suite 189/189. Browser then exposed dark-theme edge-label contrast; corrected theme colors, followed by six graph/parser/UI checks passing and clean fresh Flutter analysis. Release web build and named-browser evidence recorded alongside this handoff. Existing CupertinoIcons font warning is unrelated and did not fail web compilation.
- Runtime: started own Flutter web-server on8787, connected Dart Tooling Daemon, hot reload succeeded against connected browser; get_runtime_errors reported no errors. This is Web evidence, not Android hardware verification.
- Screenshots at390x844 cover graph, religion quiz and country layer. Static preview8788 serves build/web. Browser text evidence country-browser.txt includes affiliation breakdown and source links.

External review gate: quiz_master-4z58. Managed Claude and official direct CLI could not authenticate (OAuth session expired and could not be refreshed). Different-provider review remains unaccepted before main merge/deployment. Independent Codex code/factual review is not claimed as different-provider acceptance. Hub child task task-32811a91c6c040c3877fa17cf59dce58 is REWORK with truthful authentication evidence.

Shared checkout has unrelated work. Only explicit atlas/task files are committed; legacy mobile deletions, main/discovery/localization/backend/study changes belong to peers.

Hub root submission was refused with `child results not accepted` because the different-provider child remains REWORK. Root task is intentionally not represented as accepted; implementation evidence and authentication follow-up remain available. No review gate was bypassed.

Clean sparse worktree at implementation commit4357d734: `git pull --rebase origin codex/quiz-v2` reported HEAD up to date; offline dependency resolution and21 atlas/navigation/parser/camera tests passed. Re-running the importer in this clean checkout left the production country asset unchanged. Final isolated build evidence is isolated-build.log.
