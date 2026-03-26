param(
    [string]$ServerBaseUrl = "http://localhost:8090",
    [string]$ApiBaseUrl = "http://localhost:8090/api",
    [string]$WebPort = "8091"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
& "$repoRoot\scripts\run-client.ps1" -ServerBaseUrl $ServerBaseUrl -ApiBaseUrl $ApiBaseUrl -Device "chrome" -WebPort $WebPort
