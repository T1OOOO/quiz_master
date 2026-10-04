# Flutter study library

The Flutter client loads the reviewed study catalog through `studyModulesProvider`. The library uses responsive cards with a fixed, text-scale-tolerant extent. Article pages render the Markdown, a navigable contents list, bounded resource images, objectives, linked sources, and readable links to related quizzes.

The local practice session selects and shuffles up to 20 questions and shuffles each answer list while retaining stable option IDs. It is explicitly unranked and does not call the API. Correct answers show centered feedback and advance after one second; pausing cancels the timer and reveals the explanation and its cited sources. Incorrect answers show the same centered overlay and wait for manual continuation. Retry, return-to-article, route changes, and disposal clear session timers appropriately.

Feedback disables background answers, focus and semantics, includes a nondismissible modal barrier, and focuses Pause/Continue. Lifecycle suspension and catalog refresh pause rather than silently advancing; route changes cannot advance a hidden page.

`test/study_test.dart` has 14 passing cases covering real bundled assets, dedicated cover images, article contrast, answer mapping, timers, keyboard feedback, lifecycle/catalog pause, exact 20-question scoring/retry, navigation, sources, missing images, and narrow large-text layout. The full app suite passes 69 tests; analyzer reports no issues. Independent changed-scope review approves requirements and quality. Android device acceptance is not claimed.
