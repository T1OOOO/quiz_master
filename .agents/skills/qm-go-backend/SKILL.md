---
name: qm-go-backend
description: "Implement Quiz Master's Go APIs, PostgreSQL transactions, authoritative attempts and multiplayer state."
---

Consume the frozen HTTP/event/card contracts. Keep business rules independent of the HTTP framework. Use one PostgreSQL-backed service initially, explicit SQL and small module boundaries. Do not introduce interfaces or dependencies solely for hypothetical future services.

Score server-held attempt answers, never client totals. Pin question revision and option order. Enforce ownership at service/data boundaries. Use transactions plus uniqueness constraints for answer idempotency; define same-key/different-payload conflict. Deadline decisions use server time and a test clock. Do not expose answer keys through errors, logs or pre-reveal payloads.

Rooms use verified participant IDs, explicit phase transitions, host rights, sequence/version checks and a documented restart/reconnect policy. Test concurrent duplicates and host/participant edge cases. In-memory snapshots alone do not justify claims of restart durability or multi-instance support.

Wrap errors with actionable context; use errors.Is/As where relevant; log once at a meaningful boundary; propagate cancellation and close resources. Prefer standard library plus the chosen repository dependencies over mandatory testing/error frameworks.

Own migration order and checksums. Use disposable PostgreSQL integration tests for transaction/constraint behavior; table-driven tests for grading and normalization; race checks on a supported runner. Keep legacy history provenance and password compatibility. Flag unknown production assumptions instead of connecting to an inherited database target.
