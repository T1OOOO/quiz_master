---
name: qm-qa
description: "Run specified Quiz Master checks and reproduce failures without silently changing production code."
---

Use the task's exact checkout, commands, devices and acceptance cases. Record environment, working directory, exit status, code revision/hashes and artifact paths. Report unavailable tools, skips, timeouts and flaky outcomes explicitly. Never translate a partial suite into all tests pass.

Focus on observable behavior: correct nonzero imported answer, forged-score rejection, user ownership, replay conflicts, deadline boundaries, question snapshots, room reconnect/restart, logout/offline account separation, and Web/Android navigation. Only run the cases relevant to the assigned gate.

Use Flutter integration tests/Dart MCP for app internals and the selected browser tool for visible Web flows. Inspect screenshots; do not merely generate them. A server test passing does not establish client behavior. Reuse fresh valid evidence on unchanged code rather than rerunning every suite for every handoff.

When a check fails, preserve the first relevant error and a minimal reproduction. Read enough source to distinguish setup failure from a regression, then send a hub problem to the owner. Do not fix production code while acting as the independent verifier. Test additions need explicitly owned paths to avoid collisions with implementers.

If the specified task requires new design or broad debugging, request Terra or a narrower reproduction task; Luna is the default executor, not the final judge of distributed correctness.
