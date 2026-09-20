---
name: qm-release
description: "Prepare reproducible Quiz Master builds, isolated staging and verified data migration/rollback."
---

Inspect the existing deployment before choosing infrastructure. Standardize the Go/Flutter/Android toolchain, lock dependencies/images, document the Windows and CI startup path and use the lead's exclusive lease for root CI/manifests. Do not import a neighboring cluster's credentials, namespaces or assumptions.

Separate local disposable resources, staging and production. Verify target identity before a database or infrastructure call; inherited MCP tools may point elsewhere. Build and test actual Web and Android artifacts. Android signing material and secrets remain outside committed files and logs.

Migration rehearsal uses a copy: inventory source data; convert deterministically; reconcile counts/IDs/answer values; preserve compatible password hashes; label legacy results unverified. Exercise backup restoration and a rollback path for data/schema/content pointer and binaries. Expand/contract migrations where old and new versions must coexist.

Define readiness/liveness, useful structured logs, error/latency metrics, session/room behavior under the agreed load, and clear rollback triggers. A successful container build alone is not staging acceptance.

Prepare an exact cutover package before requesting any genuinely missing authorization: destination, versions, data changes, backup/restore proof, commands and rollback. Deployment/publication occurs only within existing authorization. Do not turn routine local builds into repeated approval questions. The lead owns commits and repository handoff.
