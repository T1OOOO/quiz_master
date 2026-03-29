param(
    [string]$Port = "8093",
    [string]$DbDriver = "sqlite",
    [string]$DbDsn = "",
    [string]$DbPath = ".data/storage.db",
    [string]$QuizzesDir = "quizzes",
    [string]$StorageApiToken = "dev-storage-token",
    [switch]$Detach
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$runDir = Join-Path $repoRoot ".run"
$pidFile = Join-Path $runDir "storage.pid"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$env:PORT = $Port
$env:DB_DRIVER = $DbDriver
$env:DB_DSN = $DbDsn
$env:DB_PATH = $DbPath
$env:QUIZZES_DIR = $QuizzesDir
$env:STORAGE_API_TOKEN = $StorageApiToken
$env:ENV = "development"

if ($Detach) {
    $proc = Start-Process go -ArgumentList "run", "./cmd/storage" -WorkingDirectory $repoRoot -PassThru
    Set-Content -Path $pidFile -Value $proc.Id
    Write-Output "storage started on port $Port (pid=$($proc.Id))"
    exit 0
}

Set-Content -Path $pidFile -Value $PID
try {
    go run ./cmd/storage
}
finally {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
