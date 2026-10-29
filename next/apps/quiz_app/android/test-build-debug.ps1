param([Parameter(Mandatory)] [string] $JavaHome)
$ErrorActionPreference = 'Stop'
$JavaHome = (Resolve-Path $JavaHome).Path
$root = Join-Path ([IO.Path]::GetTempPath()) ('android-wrapper-test-' + [guid]::NewGuid())
$android = Join-Path $root 'next/apps/quiz_app/android'
$bin = Join-Path $root 'bin'
$sdk = Join-Path $root 'sdk-кириллица'
New-Item -ItemType Directory -Force $android, $bin, "$sdk/ndk/28.2.13676358" | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'build-debug.ps1') $android
Set-Content "$sdk/ndk/28.2.13676358/source.properties" 'Pkg.Revision=28.2.13676358'
Set-Content -Encoding ascii "$bin/flutter.bat" '@copy /y android\local.properties "%WRAPPER_CAPTURE%" >nul
@exit /b 7'
$local = Join-Path $android 'local.properties'
$oldPath = $env:PATH
$oldCapture = $env:WRAPPER_CAPTURE
$oldExpected = $env:WRAPPER_EXPECTED
$names = @('JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'JAVA_TOOL_OPTIONS')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:PATH = "$bin;$oldPath"
    $env:WRAPPER_CAPTURE = Join-Path $root 'captured.properties'
    $env:WRAPPER_EXPECTED = $sdk
    $env:JAVA_HOME = 'original-java'
    $env:ANDROID_HOME = 'original-android'
    $env:ANDROID_SDK_ROOT = 'original-sdk'
    $env:JAVA_TOOL_OPTIONS = '-Dwrapper.test=original'
    $expected = @{}
    foreach ($name in $names) { $expected[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
    $original = [byte[]](0x6e,0x6f,0x74,0x65,0x3d,0xe9,0x0d,0x0a,0x73,0x64,0x6b,0x2e,0x64,0x69,0x72,0x3d,0x6f,0x6c,0x64,0x0d,0x0a)
    [IO.File]::WriteAllBytes($local, $original)
    & (Join-Path $android 'build-debug.ps1') -JavaHome $JavaHome -SdkRoot $sdk
    if ($LASTEXITCODE -ne 7) { throw 'Build failure was not propagated' }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($local)) -ne [Convert]::ToBase64String($original)) { throw 'Original bytes were not restored' }
    foreach ($name in $names) { if ([Environment]::GetEnvironmentVariable($name, 'Process') -cne $expected[$name]) { throw "$name was not restored after failure" } }
    $check = @'
import java.nio.file.*;
import java.util.*;
class Check {
    public static void main(String[] args) throws Exception {
        Properties p = new Properties();
        try (var in = Files.newInputStream(Path.of(args[0]))) { p.load(in); }
        if (!p.getProperty("sdk.dir").equals(System.getenv("WRAPPER_EXPECTED")) || !p.getProperty("note").equals("\u00e9")) throw new AssertionError(p);
    }
}
'@
    [IO.File]::WriteAllText((Join-Path $root 'Check.java'), $check)
    & (Join-Path $JavaHome 'bin/java.exe') (Join-Path $root 'Check.java') $env:WRAPPER_CAPTURE
    if ($LASTEXITCODE -ne 0) { throw 'Java Properties did not read the expected values' }
    Remove-Item -LiteralPath $local
    Set-Content -Encoding ascii "$bin/flutter.bat" '@copy /y android\local.properties "%WRAPPER_CAPTURE%" >nul
@exit /b 0'
    & (Join-Path $android 'build-debug.ps1') -JavaHome $JavaHome -SdkRoot $sdk
    if ($LASTEXITCODE -ne 0) { throw 'Successful build was not propagated' }
    if (Test-Path -LiteralPath $local) { throw 'Initially absent local.properties was not removed' }
    foreach ($name in $names) { if ([Environment]::GetEnvironmentVariable($name, 'Process') -cne $expected[$name]) { throw "$name was not restored after success" } }
    Write-Output 'Unicode properties, failure and success, file and environment restoration verified.'
} finally {
    $env:PATH = $oldPath
    $env:WRAPPER_CAPTURE = $oldCapture
    $env:WRAPPER_EXPECTED = $oldExpected
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
    Remove-Item -LiteralPath $root -Recurse -Force
}
