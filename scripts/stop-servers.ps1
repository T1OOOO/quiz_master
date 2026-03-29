$ErrorActionPreference = "SilentlyContinue"
$repoRoot = Split-Path -Parent $PSScriptRoot

& "$repoRoot\scripts\stop-auth.ps1" | Out-Null
& "$repoRoot\scripts\stop-storage.ps1" | Out-Null
& "$repoRoot\scripts\stop-server.ps1" | Out-Null

Write-Output "all backend services stopped"
