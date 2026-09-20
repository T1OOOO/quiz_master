# P06 remote Android debug-build evidence

- Draft pull request: `https://github.com/T1OOOO/quiz_master/pull/1`
- Workflow/run: `Quiz v2 CI`, run `35523769763`
- Android job: `106112259701`, conclusion `success`, duration `4m22s`
- Head branch/commit: `codex/quiz-v2` / `210e848194604395cb12916e3449fcbea3dec8e4`
- Runner/toolchain: GitHub `ubuntu-24.04`, Temurin `17.0.17`, Flutter `3.47.1`
- Build command: `flutter build apk --debug`
- Artifact: `quiz-v2-debug-apk-13070c3f509afc55da4d37e75bc8649f4968e504`, artifact ID `10609308099`
- Artifact archive size/digest: `74,418,836` bytes / `sha256:f4a2e00a63e4fb9a356fbe45a5f52fe99cfe85485f0583084f1d1eb7bfb03d80`
- Extracted `app-debug.apk`: `154,866,738` bytes
- APK SHA-256: `9024d7f12908563e90a4a0c587450b45ad86ed1942b0db728e3350e86994996b`
- The independently computed local SHA-256 exactly matched the workflow-produced `SHA256SUMS.txt` entry.
- The temporary local download contained only `app-debug.apk`, `app-debug.apk.sha1`, and `SHA256SUMS.txt`; all three and the exact temporary directory were deleted after verification. The remote Actions artifact remains available under its retention policy.

This proves a real debug APK build for the reviewed P06 application on the pinned remote toolchain. It does not prove installation/device behavior, release signing, store readiness, or release-mode behavior. The same workflow run had separate Go/Flutter CI portability failures; those do not invalidate the successful Android job and are tracked for correction before P11.
