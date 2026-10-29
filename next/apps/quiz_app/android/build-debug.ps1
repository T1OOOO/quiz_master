param(
    [Parameter(Mandatory)] [string] $JavaHome,
    [Parameter(Mandatory)] [string] $SdkRoot
)
$ErrorActionPreference = 'Stop'
$JavaHome = (Resolve-Path $JavaHome).Path
$SdkRoot = (Resolve-Path $SdkRoot).Path
if (!(Test-Path (Join-Path $JavaHome 'bin/java.exe'))) { throw "JDK not found: $JavaHome" }
if (!(Test-Path (Join-Path $SdkRoot 'ndk/28.2.13676358/source.properties'))) { throw "Android NDK 28.2.13676358 not found in $SdkRoot" }
$socketDir = Join-Path $PSScriptRoot '../../../../.run/jdk-sockets'
New-Item -ItemType Directory -Force $socketDir | Out-Null
$socketDir = (Resolve-Path $socketDir).Path.Replace('\', '/')
$localProperties = Join-Path $PSScriptRoot 'local.properties'
$existed = Test-Path $localProperties
$original = if ($existed) { [IO.File]::ReadAllBytes($localProperties) } else { [byte[]]@() }
$oldJava = $env:JAVA_HOME
$oldAndroid = $env:ANDROID_HOME
$oldSdk = $env:ANDROID_SDK_ROOT
$oldOptions = $env:JAVA_TOOL_OPTIONS
try {
    $escapedSdk = -join ($SdkRoot.ToCharArray() | ForEach-Object {
        $code = [int]$_
        if ($code -lt 32 -or $code -gt 126) { '\u{0:X4}' -f $code }
        elseif ('\:=#! '.Contains([string]$_)) { '\' + $_ }
        else { [string]$_ }
    })
    $contents = if ($existed) { [Text.Encoding]::GetEncoding(28591).GetString($original) } else { "" }
    if ($contents -match '(?m)^sdk\.dir=') {
        $contents = [regex]::Replace($contents, '(?m)^sdk\.dir=[^\r\n]*', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "sdk.dir=$escapedSdk" })
    } else {
        if ($contents.Length -gt 0 -and !$contents.EndsWith("`n") -and !$contents.EndsWith("`r")) { $contents += "`n" }
        $contents += "sdk.dir=$escapedSdk`n"
    }
    [IO.File]::WriteAllBytes($localProperties, [Text.Encoding]::GetEncoding(28591).GetBytes($contents))
    $env:JAVA_HOME = $JavaHome
    $env:ANDROID_HOME = $SdkRoot
    $env:ANDROID_SDK_ROOT = $SdkRoot
    $env:JAVA_TOOL_OPTIONS = "$oldOptions `"-Djdk.net.unixdomain.tmpdir=$socketDir`"".Trim()
    Push-Location (Join-Path $PSScriptRoot '..')
    try { & flutter build apk --debug; $result = $LASTEXITCODE } finally { Pop-Location }
} finally {
    if ($existed) { [IO.File]::WriteAllBytes($localProperties, $original) } else { Remove-Item -LiteralPath $localProperties -ErrorAction SilentlyContinue }
    $env:JAVA_HOME = $oldJava
    $env:ANDROID_HOME = $oldAndroid
    $env:ANDROID_SDK_ROOT = $oldSdk
    $env:JAVA_TOOL_OPTIONS = $oldOptions
}
exit $result
