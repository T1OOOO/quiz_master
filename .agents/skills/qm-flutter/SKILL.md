---
name: qm-flutter
description: "Implement and verify the shared Flutter Web and Android Quiz Master client."
---

Use the chosen Riverpod/Freezed/Dio/Go Router/Drift stack. Keep widgets focused on presentation and repositories/notifiers responsible for data/state. Do not add GetIt or a second state framework because a borrowed skill uses it. Version-specific APIs must match the locked packages.

Reuse QuestionCard, ExplanationPanel and PackTile for play, review and editing. Support 4–6 options, single/multi/text answers, loading/error/empty states, text scaling, keyboard focus, screen reader labels and light/dark themes. RU/EN strings live in localization resources. Web links/history and Android back/lifecycle are separate acceptance cases.

Submit answers and display server outcomes. Offline practice is visibly unranked. Drift caches and pending operations are user/device scoped; logout and guest merge must not replay another user's writes. Web offline acceptance includes loading the app shell after a network loss/reload, not only SQLite data in an already open tab.

Use Dart/Flutter MCP for analysis, runtime errors and widget inspection when available. Hot reload/restart the actual running target after UI changes. Verify screenshots on relevant sizes and Android, with widget/integration tests for behavior. Browser automation may not expose Flutter canvas internals reliably; use Flutter-aware tools and test semantics rather than guessing DOM selectors.

Only the owner runs dependency updates/codegen. Full builds are scheduled by the lead. A web screenshot is not an Android test; a debug build is not a release-signing check.
