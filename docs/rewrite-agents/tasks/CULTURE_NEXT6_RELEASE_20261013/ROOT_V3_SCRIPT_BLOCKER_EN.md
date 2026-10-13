# V3 cannot upload or prepare

Root independently verified archive4a4f839a3b19aa059dfa460bfb07e373bafd73d064687b9bb7b9af1d07c9c588,296members/295checksums, accepted234Reader rows,230old objects and four new exact bindings. This is artifact integrity, not script correctness or release acceptance.

Actual cutover.sh still uses the prior b9296af production JavaScript hash b2a176e337c4cf970deee7dbffbb0f4ecb49f3d59584da9af1a8b2974a9b5085 in both its local web/main.dart.js check and built image /usr/share/nginx/html/main.dart.js check. The fresh correct next/apps/quiz_app production build hashes to7fe815841d43e057042aa76e18508c8648fb59111cb941ac8c36bd30cdee331b, confirmed by Root. The current V3 script therefore fails its active cutover gates. Preserve V3 archive and script unchanged as failure evidence. No upload/prepare/deployment authorized before correction and independent review.

The packager's initial root legacy Flutter builds are also preserved and excluded. Its later correct-app production/QA builds and compiler-output supplement are the relevant artifacts. catalog_gate.qa_output in rawworker evidence mistakenly labels the production folder; package.qa_build.output and qa_output_packaging correctly identify qa-web-next, and a separate supplement records the correction. This metadata issue doesn't explain the stale active cutover hashes.

Root's own first V3 integrity harness assumed tar members lacked a build-directory prefix and canonical DTOs used id instead of quiz_id/question_id. Both harness assumptions were corrected before Root's passing integrity result; neither is a product defect.
