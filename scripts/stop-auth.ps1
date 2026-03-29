$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot ".run\auth.pid"

if (!(Test-Path $pidFile)) {
    Write-Output "auth is not running"
    exit 0
}

$processIdValue = Get-Content $pidFile | Select-Object -First 1
if ($processIdValue) {
    Stop-Process -Id ([int]$processIdValue) -Force -ErrorAction SilentlyContinue
}
Remove-Item $pidFile -ErrorAction SilentlyContinue
Write-Output "auth stopped"
