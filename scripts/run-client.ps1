param(
    [string]$ServerBaseUrl = "http://localhost:8090",
    [string]$ApiBaseUrl = "http://localhost:8090/api",
    [string]$AuthApiBaseUrl = "http://localhost:8090/api",
    [string]$QuizApiBaseUrl = "http://localhost:8090/api",
    [string]$Device = "chrome",
    [string]$WebPort = "8091"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot "flutter"
Set-Location $flutterRoot

flutter pub get
$flutterArgs = @(
    "run",
    "-d", $Device,
    "--dart-define=SERVER_BASE_URL=$ServerBaseUrl",
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=AUTH_API_BASE_URL=$AuthApiBaseUrl",
    "--dart-define=QUIZ_API_BASE_URL=$QuizApiBaseUrl"
)

if ($Device -in @("chrome", "edge", "web-server")) {
    $flutterArgs += @("--web-port", $WebPort)
}

& flutter @flutterArgs
