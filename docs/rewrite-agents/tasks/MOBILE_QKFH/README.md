# Quizipedia mobile usability, fact practice and publication

Source: `2e28262c3758418d510cf332fb6ae38fd99ee529`.
Published build: `quiz-2026.10.19-mobile-2e28262c`.
URL: https://quiz.kotopedia.org/#/quizipedia

## Delivered

- One source-linked, local practice bank for **12,146 facts in 13 sections**:
  countries, constellations, endocrine system, landmarks, music, organs/glands,
  Greek gods, religions, food, brands, history, works and people.
- Section/topic/search filters, individual fact checks, canonical answer IDs,
  correct-answer feedback, source buttons, missed-question retry and subsequent
  unseen rounds. Existing specialised quizzes remain available.
- Country-map touch gesture verification and a usable minimum map height;
  constellation label collision handling and larger controls; responsive belief
  graph with readable captions, collision suppression, complete Fit and manual
  camera preservation on selection.
- Narrow brand filters, a reserved feedback footer outside learning content,
  dark footer background, and Russian labels/qualifiers/source captions.

The bank extracts existing card facts. It does not claim exhaustive world
coverage or an independent primary-source recheck of every existing assertion.
Source checked dates are context rather than standalone trivia questions.

## Evidence

- Clean committed-source `flutter analyze --no-pub`: **No issues**.
- Clean committed-source `flutter test --no-pub`: **239/239 pass**.
- Release Web build succeeds with the public API URL and exact build identity.
  The pre-existing Cupertino font-family warning remains; no new dependency or
  asset was introduced for it.
- Phone widgets cover 320px at 1.5× Russian text; country-map tests execute a
  two-finger pinch and pan. The complete graph Fit regression was RED before
  the fix and GREEN after it. Focused belief graph checks pass 6/6.
- Local 360×780 Chromium phone-emulation browser checks cover all 13 sections:
  wrong answer → correct answer/source → retry → score 1/1. The published
  replay also passes **13/13**, recorded under `published/` and in
  `published-browser-summary.json`; all screenshots are 360×780. Final browser
  runtime errors are empty.
- Actual independent Antigravity review found and drove repairs. Final model,
  mobile graph, Fit/collision and publication-controller verdicts are ACCEPT;
  original REVISE reports are retained. Reviews are read-only and do not claim
  to have run root's tests. Native Hub review deliverable is ACCEPTED; root has
  not fabricated independent-provider callbacks on implementation tasks.

## Publication

`publication.log` completed with exit 0. Helm revision **65** is deployed with
one ready replica; both containers use the fresh frontend-only image tag.
The imported containerd descriptor is
`sha256:1ffef43227a8e9b667bccf9b9b50c61865126b5f1fe09b369b7c5f4e6fd87eea`.
The original API bytes and nginx configuration are preserved. Public JS SHA-256:
`c5909ab4926f6178bb57975a2a4a45a38c6a0b93dfbb5fbe581abc907bb2f49c`.

`public-assets.json` records **20 read-only checks**: exact bytes for version,
JS, index, bootstrap and all 14 packaged Quizipedia JSON assets, plus both
health endpoints. `deployment-receipt.json` confirms the unchanged PVC, all
**43 original feedback reports** unchanged, a private 0600 consistent SQLite
backup with integrity `ok`, and a restore-proof copy with integrity `ok`.
No schema, API or canonical quiz-content migration occurred.

The first invocation stopped safely at the initial Helm-revision guard. The
separate Deployment/Helm counters were reconciled and independently reviewed;
see `revision-reconciliation.md`. The rollback target is actual Helm revision
64, whose values and secret references were reused.

## Device limits

No physical phone was connected. The owned read-only Android emulator booted,
but automatic approval review rejected opening the page (`blocked by policy`),
and no workaround was attempted. A separate actual native debug-APK build
failed in host Gradle with `Unable to establish loopback connection`.
Native Android and physical-device acceptance remain **NOT VERIFIED**, tracked
in **quiz_master-0fq3**. Web publication and browser-emulation evidence do not
substitute for that acceptance.

## Handoff and cleanup

The shared preview on port 8788 serves the same final build. The owned debug
Flutter runner, phone-browser session and temporary verification worktree were
closed/removed. The old unreferenced candidate package under `.run/` remains:
automatic approval review rejected its recursive cleanup (`blocked by policy`)
and no alternate deletion was attempted. The final immutable local package and
private server backup/release evidence remain available for recovery.

Raw terminal and patch captures intentionally retain their original whitespace;
the application source passes its normal whitespace checks. Native Android
follow-up is open; no physical-device, native APK or all-primary-facts review
acceptance is claimed.
