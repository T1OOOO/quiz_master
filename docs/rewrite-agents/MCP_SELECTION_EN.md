# MCP selection by role

Checked 2026-09-20. “Best” means the best fit among inspected sources for this repository and existing environment, not a benchmark winner. A callable tool is not proof that its configured target is the Quiz Master development environment. Confirm that target before connecting.

## Use the available capabilities firs

| Server/capability | Decision and roles | Availability / why |
|---|---|---|
| Existing **agent-hub** | Core for all roles; read-only reviewers may use lead relay | Actual local CLI verified and used. MCP tools are not loaded in this task; a configuration snippet is supplied. Same implementation handles both. No external account needed. |
| Official **Dart & Flutter MCP** | Core for Flutter and UI QA; conditional for live-quiz work | Already callable as dart_flutter. Analyzer, runtime and widget-aware inspection are directly useful for Flutter. Official entry point is `dart mcp-server`; check the supported installed Dart SDK. [Flutter documentation](https://docs.flutter.dev/ai/mcp-server) |
| **Chrome DevTools MCP** | Core for Web QA/debugging and presentation-screen diagnostics | Already callable. Use console/network/screenshots and performance evidence. Avoid a second browser server for the same task. Maintainer supports a slim mode; check its current exposed tools before changing a working setup. [Official repository](https://github.com/ChromeDevTools/chrome-devtools-mcp) |
| **content_toolkit** | Core helper for content, writer and fact checker | Already callable locally. Select JSON fields/Markdown sections, format and validate links without loading a whole corpus. Its syntax repair does not establish factual correctness or schema validity. Existing Language Learner-specific link rules must be adapted for Quiz. |
| **Quiz project MCP** | Required product deliverable for content/editorial/tools roles | Not implemented yet. Build via P23 using the official SDK and shared quizctl/domain validation. Expose small draft/search/validate/diff tools with explicit editorial privileges. [Official SDK](https://github.com/modelcontextprotocol/typescript-sdk), [server guide](https://modelcontextprotocol.io/docs/develop/build-server) |
| **PostgreSQL read-only tools** | Conditional for backend/release/reviewer | Already callable, but configured DB identity is unverified. Use only after verifying a Quiz dev/staging target and database-level read-only credentials. Schema/explain/reconciliation diagnostics; migrations run through the controlled migration command. No need to install an archived reference server. |
| **Git tools / CLI** | Lead integration; read-only history/diff for others | Already available. Direct local Git is sufficient. A worker's ability to call commit is not permission to change the shared index. |
| **OpenAI documentation MCP** | Lead when changing Codex models/configuration | Already callable. Use official docs for actual model IDs, agent configuration and supported settings instead of remembered older schemas. [Codex agents](https://developers.openai.com/codex/multi-agent) |
| **graphify** | Optional targeted architecture navigation | Already callable, but first verify which repository graph it serves and its freshness. Useful for a specific dependency path; do not build/crawl a huge graph merely to read a few files. |

## Add only for a demonstrated gap

| Candidate | Recommended use | Cost/requirements and fallback |
|---|---|---|
| **Context7** | Version-specific library documentation repeatedly needed by backend/Flutter/tools agents | Official remote endpoint `https://mcp.context7.com/mcp`; availability and authentication limits depend on the current service/client. It is not currently callable here. Built-in web plus official package docs is the fallback. [Official setup](https://context7.com/docs/resources/all-clients) |
| **GitHub's official MCP** | Lead/release need remote PR, Actions or repository metadata | Not currently callable here. Use the official server and minimal required read-only/tool scopes initially; follow its current authentication documentation. Local Git and existing GitHub CLI are sufficient where available. [Official repository](https://github.com/github/github-mcp-server) |
| **Playwright MCP or CLI skill** | Browser flow automation when the existing browser/DevTools path cannot satisfy it | Prefer a single browser automation path per task. Its maintainers describe CLI+skills as an option with lower context cost for coding agents. Flutter app internals still need Flutter-aware tools/tests. [Official repository](https://github.com/microsoft/playwright-mcp), [OpenAI Playwright skill](https://github.com/openai/skills/tree/main/skills/.curated/playwright) |

No extra search MCP is required for advisor/writer/fact checker: web search is already available. No new Redis, generic filesystem, generic shell, broad memory, cloud deployment or multiple browser MCP servers are justified by this plan. The team hub and recovery files already carry project coordination state. These decisions can change if a measured task needs a missing capability.

## Role sets

| Role | Start with | Load conditionally |
|---|---|---|
| Lead | Hub, local Git/Beads | OpenAI docs; GitHub remote CI/PR metadata |
| Content/contracts | Hub, content_toolkit, quizctl | Project MCP after P23; versioned schema docs |
| Backend | Hub, local Go/test tools | Verified Quiz read-only Postgres; Context7 for a specific package |
| Flutter | Hub, Dart/Flutter | Chrome DevTools for Web; Android tooling for real device/emulator |
| Tools | Hub, official MCP docs/SDK | Project MCP inspector/client smoke checks |
| QA | Hub, relevant native test tools | Dart/Flutter, one browser tool, verified read-only DB |
| Reviewer | Scoped diffs/contracts/test artifacts | Read-only source/db inspection; lead relay to hub |
| Release | Hub, local Git/build/container tools | Verified staging DB, GitHub Actions metadata |
| Mechanical | Hub, local scoped edits/checks | content_toolkit for exact JSON/Markdown work |
| Advisor | Hub, source/decision packet | Built-in web search, selected primary docs |
| Quiz writer | Hub, content_toolkit, source search | Project MCP draft/validate; optional image tool only for a specific media task |
| Fact checker | Hub, independent source search, candidate questions | Project MCP read/validate; no publish capability |

The list is an intended capability scope, not an enforced per-role MCP allowlist. Custom agents can inherit parent server settings. Verify the actual tool list and permissions in a fresh session; use supported tool filtering where available. Do not invent a configuration key or assume that an unused tool is inaccessible.

## Activation and verification

1. Reuse existing working server entries; avoid duplicate server names and duplicate browser sessions.
2. Merge the supplied hub block only; keep credentials and unrelated configuration intact. The supplied file deliberately does not auto-install optional servers or contain API keys.
3. Start a fresh task and check the actual tools. Call a harmless status/read against the intended project. For Dart, select the Quiz app root; for browser, confirm the exact local test URL; for database, establish host/database/environment identity first.
4. Record installed version, command and project scope in the P00 environment report. Pin newly introduced executable package versions after smoke testing rather than relying on floating latest in a reproducible build.
5. If a server is unavailable, use the documented CLI/official-doc fallback and report the missing capability. A planned server is not a connected one.

Web/Android QR play uses application HTTP/WebSocket endpoints and QR/deep-link support. **MCP is development/editorial tooling, not the player-to-game transport.** Players do not install MCP or sign in to an agent service.
