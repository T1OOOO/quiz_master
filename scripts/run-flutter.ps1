param(
    [string]$ServerBaseUrl = "http://localhost:8090",
    [string]$ApiBaseUrl = "http://localhost:8090/api",
    [string]$AuthApiBaseUrl = "http://localhost:8092/api",
    [string]$QuizApiBaseUrl = "http://localhost:8090/api",
    [string]$Device = "chrome",
    [string]$WebPort = "8091"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

& "$repoRoot\scripts\run-client.ps1" `
    -ServerBaseUrl $ServerBaseUrl `
    -ApiBaseUrl $ApiBaseUrl `
    -AuthApiBaseUrl $AuthApiBaseUrl `
    -QuizApiBaseUrl $QuizApiBaseUrl `
    -Device $Device `
    -WebPort $WebPort
