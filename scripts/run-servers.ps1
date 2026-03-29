param(
    [string]$ServerPort = "8090",
    [string]$AuthPort = "8092",
    [string]$StoragePort = "8093",
    [string]$AuthDbDriver = "sqlite",
    [string]$AuthDbDsn = "",
    [string]$AuthDbPath = ".data/auth.db",
    [string]$StorageDbDriver = "sqlite",
    [string]$StorageDbDsn = "",
    [string]$StorageDbPath = ".data/storage.db",
    [string]$JwtSecret = "dev-secret",
    [string]$AuthApiToken = "dev-auth-token",
    [string]$StorageApiToken = "dev-storage-token"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ($StorageDbDriver -eq "sqlite") {
    & "$repoRoot\scripts\db.ps1" -Action init -DbPath $StorageDbPath
}
& "$repoRoot\scripts\run-storage.ps1" -Port $StoragePort -DbDriver $StorageDbDriver -DbDsn $StorageDbDsn -DbPath $StorageDbPath -StorageApiToken $StorageApiToken -Detach
& "$repoRoot\scripts\run-auth.ps1" -Port $AuthPort -DbDriver $AuthDbDriver -DbDsn $AuthDbDsn -DbPath $AuthDbPath -JwtSecret $JwtSecret -AuthApiToken $AuthApiToken -StorageApiUrl "http://localhost:$StoragePort" -StorageApiToken $StorageApiToken -Detach
& "$repoRoot\scripts\run-server.ps1" -Port $ServerPort -JwtSecret $JwtSecret -AuthApiUrl "http://localhost:$AuthPort" -AuthApiToken $AuthApiToken -StorageApiUrl "http://localhost:$StoragePort" -StorageApiToken $StorageApiToken -Detach

Write-Output "all backend services started: server=$ServerPort auth=$AuthPort storage=$StoragePort"
