# Independent media-QA evidence review

Reviewed packet: `FLAGS_BROWSER_20261017`.

## Verdict

`accepted_for_media_qa_only`.

The saved Chromium 152 result proves that the isolated loopback check decoded 195 distinct content-addressed PNGs. Each request had HTTP 200, `image/png`, a SHA-256 matching its filename digest, and positive decoded dimensions. The result lists 195 unique URLs and 195 unique digests, with minimum dimensions 320 × 126. Fetches were bounded to eight concurrent requests.

The two negative controls worked: an HTML response was rejected by MIME validation and an absent PNG was rejected with HTTP 404. The fresh public catalog receipt returned HTTP 200, contains 195 questions, and states that the exact question-revision/media set and raw snapshot SHA match the set used by the browser run.

I verified every hash in `review-inputs.json`. `browser-raw.json` records exit code 0 and a successful Chromium evaluation; its nested result is semantically identical to `browser-result.json`. The saved sample screenshot visibly displays the `Media QA: 195 / 195 PNG decoded` heading and twelve loaded flag images. The saved reported Norway flag image is visibly decoded, with the expected Norwegian design.

The browser-check script constrains the proof to an isolated local static server. Its assertions cover catalog cardinality, one correctly shaped HTTPS content-addressed URI per question, unique digests, HTTP status, MIME, SHA-256, `createImageBitmap` decoding, positive dimensions, and the two negative controls. The run notes record cleanup: the owned server exited with code 0, no listener remained on its loopback port, and the named browser session closed successfully.

## Limits

This evidence does not verify Flutter rendering, application navigation, nginx or container delivery, a deployed endpoint, feedback resolution, release readiness, external acceptance, or publication. It is only acceptance of the saved isolated Chromium asset-decode evidence.
