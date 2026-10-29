# Windows Android debug build

Install Flutter and provide a JDK 21 and Android SDK containing NDK
`28.2.13676358`. The SDK also needs the Android platform and build tools used
by the project. The local `.run` tools below are specific to this checkout and
are ignored by Git; a fresh checkout needs its own installations.

From the repository root, this command was verified for this checkout:

```powershell
./next/apps/quiz_app/android/build-debug.ps1 `
  -JavaHome .run/jdk21/jdk-21.0.12.1+1 `
  -SdkRoot .run/android-sdk
```

Pass other JDK and SDK paths as needed. The script uses `.run/jdk-sockets` for
JDK sockets, temporarily points `local.properties` at the supplied SDK, and
restores its original contents when the build exits. Avoid running another build
against the same `local.properties` concurrently.

The debug APK is written to
`next/apps/quiz_app/build/app/outputs/flutter-apk/app-debug.apk`. Building does
not install it on a device.
