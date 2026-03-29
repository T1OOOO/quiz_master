param(
    [string]$Port = "8092",
    [string]$DbDriver = "sqlite",
    [string]$DbDsn = "",
    [string]$DbPath = ".data/auth.db",
    [string]$JwtSecret = "dev-secret",
    [string]$AuthApiToken = "dev-auth-token",
    [string]$StorageApiUrl = "http://localhost:8093",
    [string]$StorageApiToken = "dev-storage-token",
    [switch]$Detach
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$runDir = Join-Path $repoRoot ".run"
$pidFile = Join-Path $runDir "auth.pid"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$env:PORT = $Port
$env:DB_DRIVER = $DbDriver
$env:DB_DSN = $DbDsn
$env:DB_PATH = $DbPath
$env:JWT_SECRET = $JwtSecret
$env:AUTH_API_TOKEN = $AuthApiToken
$env:STORAGE_API_URL = $StorageApiUrl
$env:STORAGE_API_TOKEN = $StorageApiToken
$env:ENV = "development"

if ($Detach) {
    $proc = Start-Process go -ArgumentList "run", "./cmd/auth" -WorkingDirectory $repoRoot -PassThru
    Set-Content -Path $pidFile -Value $proc.Id
    Write-Output "auth started on port $Port (pid=$($proc.Id))"
    exit 0
}

Set-Content -Path $pidFile -Value $PID
try {
    go run ./cmd/auth
}
finally {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
