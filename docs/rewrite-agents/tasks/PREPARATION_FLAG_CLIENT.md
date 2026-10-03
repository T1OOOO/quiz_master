# Flag question images — quiz_master-8k1.6

Base824eefd, C:/ap/quiz_master, label flutter-flags-oct3.
Not alone; preserve other changes. No children/git/production/deploy.
Read qm-work-packet/qm-flutter/agent-hub-coordination/test-driven-development.
Own only next/apps/quiz_app/lib/** and next/apps/quiz_app/test/**.
Do not edit assets/catalog.json, pubspec/lockfile, server or contracts.
Read exact schema next/contracts/quiz-contract/v1/schemas/public-question.schema.json.

Implement the smallest support for existing optional question media array:
[{uri: 'https://quiz.kotopedia.org/flags/xx.gif',kind:'image',alt:'Флаг страны'}].
Existing schema v1 already supports media uri/kind/alt. Lead extends importer
separately; do not add a new wire shape, dependency, media framework or option
image support. DTO retains question media; const defaults preserve old callers.
Unknown/private fields remain rejected; don't weaken closed parsing.

Known drops: api_models.dart Media has no fields and PublicQuestion discards
validated media; journey_pages.dart reconstructed PublicQuestion for shuffled
optionOrder drops everything not explicitly copied. Trace ALL constructors and
consumers and fix this shared path, not only gallery. Attempt snapshots contain
IDs/revision/options, not a second embedded body: media comes from pinned catalog.

QuestionCard in main.dart renders bounded native Image.network for kind=image,
BoxFit.contain (never crop national flag), neutral non-answer alt. Reserve stable
space so async image load/error never shifts options. Error/loading accessible
states; unsupported kinds must not be fetched as images. Keep current warm UI,
feedback-overlay-only and auto-next1s untouched. Ordinary text quizzes unchanged.
Flag question stem is short; all4options must fit1262x576 and390x640. No indefinite
spinner on failure. HTTP/security boundaries remain as strict as current contract;
do not silently rewrite a non-image media entry into image. Bounded validation
handles malformed URLs without executing/fetching unsafe schemes.

TDD real decoder→actual QuizPage/reorder→QuestionCard image test, old code RED
(assert missingimage, not compileerror). Test loading/error and responsive4choices
with decoded flagfixture; no real network in widgettests (small image fake through
existing test helpers if available). Preserve grading/correctID and shuffled
option order. Main controls browser+release; don't launchbrowser/buildrelease.
Run scoped tests/full Flutter suite/analyze only with own granted host heavy
lease and notify lead beforehand (globalheavy1). If blocked, give runnablechecks
forlead, don'tclaimPASS. Return READY/files/evidence/hashes; freeze/release.
