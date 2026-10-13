# Reviewed runtime Reader status correction

Root corrected exactly four already fact-reviewed and binding-reviewed runtime article statuses from draft to accepted. All other fields and all230 preexisting article objects are unchanged. Original study draft/review provenance stays unchanged. The fail-closed Dart decoder remains intact.

The native author added a real packaged asset regression but its initial asset load stalled inside Flutter fake async; no native RED result was obtained. Root wrapped the real rootBundle load in tester.runAsync, then obtained actual RED exit1/FormatException 'unreviewed article' before the status correction. After the correction Root's full Flutter run passed121 tests (29.63s) and analyzer passed (14.81s). See reader-root-gates.json and reader-browser-blocker/root-red.txt. Independent Claude review and fresh build/actual Reader UI/publication gates are separate, pending at this checkpoint.

An additional Python reader check using the unrelated dirty study/check_reader.py failed7-test suite at its foreign expected10 modules versus actual6. Root preserved the foreign file. The HEAD version of that test expects the unchanged six released modules and passed all7 when executed against the current data. The first isolated harness invocation registered no test module and ran0/exit5; the corrected __main__ registration ran7/exit0. None of these outcomes certifies the unrelated unfinished ten-module expansion. No Go runtime changed; previous Go gates remain scoped evidence.

Production remains Helm44; both b9296af V1/V2 release archives remain blocked and immutable. A new pushed repair commit, new builds and full release gates are required before server upload. No real feedback records were closed or submitted by the browser checks.
