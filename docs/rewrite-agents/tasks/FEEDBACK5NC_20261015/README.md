# Feedback5nc bounded result fix

Baseline source2c66ca16 and actual productionHelm61/Reader291. Floating global feedback was positioned over scrollable result explanations. Result feedback now sits in the normal result action flow and reuses the existing guarded capture/dialog implementation; the floating control is suppressed only on completed quiz pages (`/` and `/quiz/...`). Other screens keep their global control; no shared question viewport reduction, API, privacy, grading or source/options/keys changes.

Observed red: the existing actual25question API flow found a floating button on results. Initial green run exercised the new dialog but then tapped History before the post-scroll frame; adding test pumps after ensureVisible fixed that harness timing. Final regression0, all33feedback/widget checks0 (including6phoneanswers and textscale),7article checks0 with8new exactpublicbindings/299count. DartMCP scopedanalysis returned No errors.

Actual browser361x738 used a strictly local1question Go fixture preserving cinema-oct3-020 public question/options/privatekey/revision. The subset overall quiz revision was recomputed after Go correctly rejected the initial stale20questionrevision. A fresh Flutterdebug app was hot-restarted through discovered DTD; real UI submitted an intentional wronganswer, read the new020article through its two source cards, finished with score0, opened/cancelled inline result feedback, and navigated to History with global feedback restored. Root viewed result/footer screenshots; no overlap in actual result, browser/Dart errors empty. Browser initial navigation/officialclose failures are preserved in proof; native captured-identity cleanup is separate.

New article integration299 is separate task72e and owner report; its first author provenance was corrected from task.author to actual article-writer task.assignee767 before independent review. All291existing articleobjects and questionbytes preserved.

Foreign `study/check_reader.py` already changes expected modules6to10 while published/catalogsource still6. This file was preserved; its worktree check fails. The unmodified tracked HEAD checker ran7checks successfully against current6module generated data. Neither result claims4new study modules are delivered.

Source review and fresh release/staging/capacity gates remain separate. No299/5nc production publication, full-bank fact certification, signedAndroid or physicalscreenreader claim. All29productionfeedback remainOPEN with unchanged rowhash;5nc must stayopen until actual publication and verification.
