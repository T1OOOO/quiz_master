# Cinema, music, actors and singers — 2026-10-11

User request: add more interesting questions with source links and miniarticles.
Beads: `quiz_master-o7y`. Lead owns integration and release; helpers own only
their assigned packets or reports. No GitHub Actions. Quiz Master's user override
removes resource-queue waiting; other projects and the shared broker are untouched.

1. Author two packs of ten questions, four plausible options per question,
   explanations, estimated difficulty 1–10 and private proposed tags. Write a
   distinct 100–200-word Russian article per question with two relevant primary
   source links actually opened by an author/reviewer.
2. Independently check facts, uniqueness of the correct choice, distractors,
   meaningful article content and exact current packet hashes. Gemini supplies a
   separate provider's text/evidence review; its supplied-evidence review must not
   be represented as independent URL fetching.
3. Import through quizctl, validate canonical drafts/bundles, compare every
   private grading option ID against the editorial index, bind articles to exact
   question revisions and export only accepted articles. Preserve all existing
   126 public catalog entries and 162 accepted local articles.
4. Run content/reader gates and Flutter checks/build. Package the exact committed
   source, keep private grading/editorial keys out of client assets, and rehearse
   fresh production backup restoration, migration preservation and rollback.
5. Publish within existing authorization, verify public artifact hashes and
   browse a new question/article on mobile. Close the task only after publication
   verification. Keep real feedback open until individually verified.

Initial review rejected all ten cinema articles as repeated generic templates
and found an explanation incorrectly naming Hayao Miyazaki as an award category.
The inherited music packet was also rejected as too short and generic. Neither
initial packet was imported or published; fresh authors own the replacements.

Baseline: production `quiz-2026.10.10-articles-3ec0a33`, 126 packs / 3958 questions /
160 published articles. Two separately accepted local planet articles will travel
with this release; the private planet question pack remains unserved. Broader
corpus review and coverage work is tracked separately and is not claimed complete.
