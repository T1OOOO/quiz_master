# Article-only 244 Reader package producer handoff

## Scope and source

`prepare_article_package.py` is a new, inert package producer cloned from the
independently reviewed canonical-config producer
`../CACHE_POLICY_3RX_20261013/prepare_next_package.py`.

Source SHA-256: `ef9c75c1e5f8cb9f62479283059f264a3132ec54bf9bbcdb068d383c40051ed8`.
The new producer does not build, deploy, import, run a rehearsal, or modify
source assets. It requires a later frozen integration commit plus independently
created production and QA Flutter directories. Root owns those inputs and all
execution gates.

The output build name is `quiz-2026.10.13-article-only-<commit7>`. The prior
V8 archive, its archive SHA guard, baseline image
`docker.io/library/quiz-master@sha256:fa00bc8e559ec5a02ed62903f7ed91c00540f11de0a16b0cddc5b15717f5317f`,
canonical Nginx hash
`e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc`, API
hash, PVC, cutover, archive, checksum, frozen-Git-byte, and copied-web guards
are retained from that source producer.

## Intended narrow delta

The frozen Reader asset must contain 244 accepted records while the catalog
remains 131 packs and 4044 questions. Version metadata, cutover output, and the
preparation result state `question_articles: 244`.

The immutable V8 template input has 234 Reader records; it is not the reviewed
242-record Reader baseline and this producer does not assert otherwise. The
separate Reader preparer already proved that its deterministic 244-record output
preserves the prior 242 rows. This producer hard-pins the frozen source Reader
bytes to SHA-256
`98f69869f0188cdc92ecd93c4fc7d269a71800bcb2263a25fb060721cf21c433` before
any asset copy, then requires exactly 244 accepted records and exactly these two
Home Alone refs:

- `question:q-ha1-p1-1` → `home-alone-1-part-1/q-ha1-p1-1` → `b0f0047c659e193d6790f6cc209cb1135650cab8f8a2f716fda3c20d0a6e787f`
- `question:q-ha1-p1-2` → `home-alone-1-part-1/q-ha1-p1-2` → `0c4a99cddbb490c34f4918bac8f7ed1588b50acbd1ed6378fc8212ed5bf6005d`

Those hashes come from the immutable published runtime bundle, not the older
Git canonical metadata. The accepted editorial/source draft input is
`../HOME_ALONE_ARTICLES_20261013/writer-v3.json`, SHA-256
`b734f5c0b06d29d1607b6d62098ee85c854953e960ce47b4b80b96268292c7ff`; its
independent V3 evidence is `independent-review-v3.json`. The old native article
task cannot be formally resubmitted, so this producer records no replacement
formal article-Hub acceptance.

The producer captures the immutable 25-question Home Alone bundle and its
runtime-cache entry before any staging mutation. It later requires byte-for-byte
unchanged bundle content and an unchanged cache value that remains equal to that
bundle. This adds an output-preservation guard; it does not alter questions,
answers, or grading.

## Rehearsal patch contract

The old V8-template anchors must exist exactly once. The existing People
assertion is still patched from 24 to 28. Separately, the Home Alone Reader
branch changes from zero references to exactly the two IDs/hashes above and
checks the two hashes against the live catalog. All other packs retain their
existing full Reader-to-live binding equality. The surrounding loop still
compares all 25 Home Alone questions to the staged canonical bundle and grades
every question through its private grading key.

The source producer starts from the older V8 archive template. The inspected
`.run/culture_next7_release_root_20261013/package-v2/.../rehearse.py` is evidence
of a previously patched package and was not used as the expected old-template
anchor.

## Remaining gates and limitations

Root must run the planned positive and negative fixture checks against this
inert producer before any integration. Independent different-provider review of
the preparation evidence remains required. Fresh Flutter/API, copied-DB
rehearsal, image, Helm, browser, rollback, authorization, and published-runtime
verification are separate gates. No compilation, package execution, deployment,
publication, or schema acceptance is claimed here.
