param(
    [string]$Port = "8090",
    [string]$DbPath = ".data/quiz_master.db",
    [string]$Device = "chrome",
    [string]$WebPort = "8091",
    [switch]$Detach
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$runDir = Join-Path $repoRoot ".run"
$pidFile = Join-Path $runDir "dev-api.pid"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$serverBaseUrl = "http://localhost:$Port"
$apiScript = Join-Path $repoRoot "scripts\run-api.ps1"
$clientScript = Join-Path $repoRoot "scripts\run-client.ps1"

$apiProcess = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $apiScript,
    "-Port", $Port,
    "-DbPath", $DbPath,
    "-InitDb",
    "-Detach"
) -PassThru

Set-Content -Path $pidFile -Value $apiProcess.Id
Start-Sleep -Seconds 3

if ($Detach) {
    Write-Output "dev api started on $serverBaseUrl (pid=$($apiProcess.Id)); run client separately"
    exit 0
}

try {
    & $clientScript -ServerBaseUrl $serverBaseUrl -ApiBaseUrl "$serverBaseUrl/api" -Device $Device -WebPort $WebPort
}
finally {
    if ($apiProcess -and !$apiProcess.HasExited) {
        Stop-Process -Id $apiProcess.Id -Force
    }
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
