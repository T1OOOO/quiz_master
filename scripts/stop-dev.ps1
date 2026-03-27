$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot ".run\dev-api.pid"

if (!(Test-Path $pidFile)) {
    Write-Output "dev api is not running"
    exit 0
}

$processIdValue = Get-Content $pidFile | Select-Object -First 1
if ($processIdValue) {
    Stop-Process -Id ([int]$processIdValue) -Force -ErrorAction SilentlyContinue
}
Remove-Item $pidFile -ErrorAction SilentlyContinue

$apiPidFile = Join-Path $repoRoot ".run\api.pid"
if (Test-Path $apiPidFile) {
    Remove-Item $apiPidFile -ErrorAction SilentlyContinue
}

Write-Output "dev api stopped"
