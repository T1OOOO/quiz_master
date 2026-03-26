param(
    [string]$Port = "8090",
    [string]$DbPath = ".data/quiz_master.db",
    [string]$JwtSecret = "dev-secret",
    [switch]$InitDb,
    [switch]$Detach
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$runDir = Join-Path $repoRoot ".run"
$pidFile = Join-Path $runDir "api.pid"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

if ($InitDb) {
    & "$repoRoot\scripts\db.ps1" -Action init -DbPath $DbPath
}

$env:PORT = $Port
$env:DB_PATH = $DbPath
$env:JWT_SECRET = $JwtSecret
$env:ENV = "development"
$env:QUIZZES_DIR = "quizzes"

if ($Detach) {
    $proc = Start-Process go -ArgumentList "run", "./cmd/api" -WorkingDirectory $repoRoot -PassThru
    Set-Content -Path $pidFile -Value $proc.Id
    Write-Output "api started on port $Port (pid=$($proc.Id))"
    exit 0
}

Set-Content -Path $pidFile -Value $($PID)
try {
    go run ./cmd/api
}
finally {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
