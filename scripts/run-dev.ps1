param(
    [string]$ServerPort = "8090",
    [string]$AuthPort = "8092",
    [string]$StoragePort = "8093",
    [string]$AuthDbPath = ".data/auth.db",
    [string]$StorageDbPath = ".data/storage.db",
    [string]$Device = "chrome",
    [string]$WebPort = "8091",
    [string]$AuthApiToken = "dev-auth-token",
    [string]$StorageApiToken = "dev-storage-token"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$serverBaseUrl = "http://localhost:$ServerPort"

& "$repoRoot\scripts\run-servers.ps1" `
    -ServerPort $ServerPort `
    -AuthPort $AuthPort `
    -StoragePort $StoragePort `
    -AuthDbPath $AuthDbPath `
    -StorageDbPath $StorageDbPath `
    -AuthApiToken $AuthApiToken `
    -StorageApiToken $StorageApiToken

Start-Sleep -Seconds 3

try {
    & "$repoRoot\scripts\run-client.ps1" `
        -ServerBaseUrl $serverBaseUrl `
        -ApiBaseUrl "$serverBaseUrl/api" `
        -AuthApiBaseUrl "$serverBaseUrl/api" `
        -QuizApiBaseUrl "$serverBaseUrl/api" `
        -Device $Device `
        -WebPort $WebPort
}
finally {
    & "$repoRoot\scripts\stop-servers.ps1" | Out-Null
}
