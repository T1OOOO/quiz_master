# Next7 V4 integration evidence

Input `writer-v4.json` SHA-256 is `4a3922eefcc2be9d0cf1faf33d84a6aa6debfd8c3f9434708f4f894299d54082`. The independently reviewed V4 record is `claude-v4-review.json` (`ACCEPTED`, CLI exit 0, eight accepted items).

The two People legacy sources received only `025`–`028` for each pack, with answer indexes cinema `2,1,3,0` and music `0,1,3,2`. Canonical draft/bundle/manifest files were rebuilt using the existing quizctl import/validate/build representation, with the production `/app/quizzes/...` source URI restored before deterministic rehashing. This preserves the pre-existing published People question identities while adding exactly eight new identities.

Eight separately stored Reader provenance records bind the approved articles to the resulting exact public question revisions. The Reader exporter produced 242 accepted articles. The Flutter Reader regression test asserts that count and each new exact binding.

Scoped evidence: quizctl validated both new 28-question canonical drafts and bundles; `python study/question_articles/build.py --check` passed; `flutter test test/question_articles_test.dart` passed (6 tests). This is an integration handoff, not a publication, deployment, whole-bank factual certification, or full application-gate claim.
