# quiz_master-91v: search-input investigation remains open

Root used an owned official Chrome DevTools browser at 390×844 with mobile touch, enabled Flutter accessibility, clicked the empty catalog search, and called keyboard `type_text("Кино")`. The rendered query and URL became `ино`. After clearing with Control+A/Backspace, isolated ASCII `press_key("t")` and `press_key("e")`, and a single Cyrillic `type_text("К")`, each left an empty query while the semantics textbox UID was recreated. The screenshot confirms the empty visible field. Direct Cyrillic `press_key` is unsupported by the browser driver and was rejected before application input; that rejection is not product evidence.

A separately offered read-only explorer inspected the current `next/apps/quiz_app` source. Its Hub session was `session-2ced27efac5b42128d6a151876008f61`, submitted task `task-4ad526b024804a8cba86255d3a8624f4`. It reports:

- `next/apps/quiz_app/lib/discovery.dart:128-133`: a late-final editing controller seeded from the initial query, with conditional synchronization in `didUpdateWidget`.
- `next/apps/quiz_app/lib/discovery.dart:224-240`: stable `catalog-search` key and `onChanged` updating the route through `context.replace`.
- `next/apps/quiz_app/lib/main.dart:136-145`: route query passed back into the discovery page.

The explorer found no deterministic first-character reset in the application code. It considers a semantics/input-target handoff in the accessibility/browser driver more likely. This is an inference from source and browser behavior, not instrumented proof that Dart's `onChanged` was never called and not a certification of ordinary mobile typing. No code change is justified by this evidence alone.

Next step: use a trusted pointer/keyboard path focused on the actual Flutter editing target, with the accessibility proxy disabled, and compare it with the existing probes. Preserve this uncertainty rather than changing the controller speculatively. The owned page/browser SDK were closed with actual wrapper exit zero. No feedback was submitted and production code/image were unchanged.
