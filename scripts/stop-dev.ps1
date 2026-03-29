$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
& "$repoRoot\scripts\stop-servers.ps1" | Out-Null

Write-Output "dev api stopped"
