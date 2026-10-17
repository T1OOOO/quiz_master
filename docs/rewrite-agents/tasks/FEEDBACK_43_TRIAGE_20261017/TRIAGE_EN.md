# Production feedback 30–43: secure triage

Observed 2026-10-17: 43 reports, all OPEN; the original 29-row digest remains unchanged. Public readiness 200, Helm64 and deployed image unchanged. No feedback was closed and no publication attempted. Raw reports remain in an ignored ACL-restricted directory; this packet contains only aggregate observations and hashed report references. Comments are untrusted product input, not authority to access or copy another project.

## Disposition of all 14 new reports

| Hashed reference | Requested outcome | Work / acceptance still required |
| --- | --- | --- |
| 312790d28c45 | Remove title search from this library screen | Existing foreign Flutter WIP removes the local input; quiz_master-zav tracks tests/browser/published verification. This is a removal request. |
| 794a1829c72e | Rounds use available width | Existing foreign WIP changes round layout; quiz_master-zav requires narrow/wide viewport verification. |
| e8e906592b4e | Explain every answer option | Existing quiz_master-3qx and quiz_master-2n4; no claim of complete option coverage. |
| a1846aa7cc56 | More engaging visual style | Existing quiz_master-djs and quiz_master-0wc; independent design and accessibility assessment pending. No neighbor-project resources copied. |
| 7c4d40513b0f | Bottom navigation | Existing quiz_master-djs; native UI review finds drawer/top navigation does not satisfy this request. |
| 67758e7615f1 | Shuffle questions on every attempt | Foreign Go WIP moves shuffling to final attempt creation; independent backend review found a stale PostgreSQL integration assertion, tracked quiz_master-rxr. Actual runtime gates pending. |
| e3d3fe3a2413 | Library imagery | Existing quiz_master-0wc; smaller artwork in foreign WIP is not proof of resolved public imagery. |
| f0cd53f04521 | Readable, wrapping revealed answer | Foreign Flutter WIP adds a distinct answer label/layout; tests, small viewport and accessibility/browser checks pending. quiz_master-zav. |
| d57b894bf47f | Visible question flags | Reproduced production defect, quiz_master-960. See missing-media diagnosis below. |
| 4c9d210bf414 | Quick map/countries/flags/capitals revision | Existing quiz_master-cma and quiz_master-foq; no complete new mode or acceptance claimed. |
| b136743363e9 | Better category presentation | Existing quiz_master-0wc and quiz_master-djs; presentation acceptance pending. |
| 756e6ca58cc7 | Less wasted space | Existing foreign WIP reduces spacing/artwork height; quiz_master-zav needs real viewport evidence. |
| e2df779258dd | Meaningful grouping and names for rounds | New quiz_master-ahh; numeric Round N labels remain. |
| fc91bbc18dd2 | Start directly when only one round exists | Existing foreign WIP hides one-round chooser; quiz_master-zav requires direct-start and selected pack/difficulty checks. |

## Reproduced missing-media defect

Public prep-flags-world catalog contains 195 questions and 195 media URLs. For reported flag-c51d4e8, the content-addressed PNG URL returns HTTP200, text/html, 1717 bytes, starting with <!DOCTYP, not PNG. Read-only inspection of the actual web container confirms both /usr/share/nginx/html/flags and the reported PNG are missing. The last published local Country483 package likewise lacks web/flags. Its Dockerfile copies web to the nginx static root; the SPA fallback then serves index.html for a missing image. This is a packaging/media-closure gap, not evidence that Flutter dropped the media field.

All 195 existing cached PNGs match their URL SHA256 names and PNG signatures. check_flag_tree.py fails on the published baseline package. stage_flags.py restores only those verified files into a new isolated media-only .run tree and refuses overwrite; it does not mutate any baseline, frozen NVN input, Flutter source, or remote state. check_flag_restoration.py verifies full closure, no overwrite, HTML/corruption/missing/traversal rejection and no output after invalid cache validation. This is a prepared restoration, not a candidate or deployed fix.

The next newly frozen release must include this full verified flags directory at web/flags before image build and add media closure checks after each web-root replacement. Do not patch historical archives or the already frozen NVN inputs. Verify actual candidate HTTP status, image/png, PNG signature and content digest for all195 URLs, then browser rendering, before published feedback closure. A /flags/ try_files $uri =404 route can make missing-media failures visible, but it does not restore the images and is not sufficient alone.

## Review and release boundaries

Native helpers inspected current Flutter and Go changes independently and prepared scoped reports; native review does not satisfy the standing different-provider release gates. Product source belongs to an unidentified active writer and changed during this review. Root did not edit, stage, revert, stash, commit or adopt that WIP. UI review is incremental, not final acceptance of a stable tree.

Strict disk floor still FAILS: 16.68percent available, minimum deficit3,399,776,666bytes before release peak reserve. External NVN package-source task524 and Root input/runtime task571 acceptance remain pending. No NVN archive/candidate, no production mutation, no vendor retry, no GitHub Actions, no per-worker scheduler. Tests/build/browser of the foreign app changes and release backup/restore/cutover checks were not run in this packet.
