# P07 Android container attempt

Command, from `C:\ap\quiz_master`:

```text
docker buildx imagetools inspect ghcr.io/cirruslabs/flutter:3.47.1
```

Result: exit 1, `ERROR: ghcr.io/cirruslabs/flutter:3.47.1: not found`.

This was the bounded metadata diagnosis for the requested isolated Flutter 3.47.1 Android container. No host SDK component was installed, no Android device was used, and no APK build or artifact hash is claimed. P06 remains open for a real debug-APK smoke on an approved pinned Android-ready Flutter 3.47.1 toolchain.

## Reviewer candidate inspection

The reviewer-provided `plugfox/flutter:3.47.1-android@sha256:ab6a413e3f43f86e2036aae9a7781e7ee8de5090b04283f8f069718d3ef1afb2` resolves from Docker Hub to an OCI index with an explicit linux/amd64 manifest (`sha256:516a8a54c84b9ebd0b05cab2e122d58b85e5c00100495af8b47508cf4282d1d7`) and linux/arm64 manifest. That establishes digest/address and target architecture only; it does not establish the image's Flutter/Android/JDK contents or provenance.

The bounded `docker pull` of that exact digest began but did not complete or create a local image after more than 90 seconds. The one exact pull process was then stopped; no container was run. Consequently its contents could not be inspected, it is not accepted for P07 use, and no APK attempt was authorized from an unverified image. No host SDK component was installed.
