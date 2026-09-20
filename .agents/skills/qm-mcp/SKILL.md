---
name: qm-mcp
description: "Build Quiz Master's project MCP adapter over validated content and editor capabilities."
---

Use the current official TypeScript SDK and protocol docs; lock a compatible released version after a minimal handshake/tool-call smoke test. Do not hand-write a new JSON-RPC implementation. Reuse the existing agent-hub separately; it has its own tested transport and is not this content server.

Design narrow, paginated tools/resources: catalog search, card read, draft create/update, validate, bundle build/diff, and explicitly authorized publication. Return concise typed results with actionable errors. CLI, editor and MCP call the same validators/domain services. No arbitrary shell command, unrestricted path write or generic SQL tool in the product server.

Use draft revision/hash preconditions to detect conflicting edits, stable IDs and idempotent mutations. Canonicalize paths and keep writes within the assigned content workspace. Respect author/editor/player scopes. The creative writer can draft and validate; it cannot publish. Fact checker reads and comments; private answers are never exposed to player tools.

Test initialization/tool discovery, invalid arguments, version conflicts, authorization, path escape attempts, content parity and interrupted publication on disposable data. Keep protocol stdout clean for stdio; diagnostics go to stderr. Tool descriptions are context cost: small output limits and useful filters beat returning an entire pack by default.

Read mcp-builder upstream only when design detail is needed. Do not inherit its suggested runtime choices when they contradict the approved Quiz contract.
