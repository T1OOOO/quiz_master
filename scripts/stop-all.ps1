$ErrorActionPreference = "SilentlyContinue"
$repoRoot = Split-Path -Parent $PSScriptRoot

& "$repoRoot\scripts\stop-dev.ps1" | Out-Null
& "$repoRoot\scripts\stop-api.ps1" | Out-Null
& "$repoRoot\scripts\stop-servers.ps1" | Out-Null

$runDir = Join-Path $repoRoot ".run"
if (Test-Path $runDir) {
    Get-ChildItem $runDir -Force | Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Output "all local services stopped"
