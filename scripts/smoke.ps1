param(
    [string]$ServerBaseUrl = "http://localhost:8090",
    [string]$AuthBaseUrl = "http://localhost:8092",
    [string]$StorageBaseUrl = "http://localhost:8093"
)

$ErrorActionPreference = "Stop"

function Test-Endpoint([string]$url) {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "unexpected status $($response.StatusCode) for $url"
    }
    Write-Host "OK" $url
}

Test-Endpoint "$ServerBaseUrl/healthz"
Test-Endpoint "$ServerBaseUrl/readyz"
Test-Endpoint "$ServerBaseUrl/metrics"
Test-Endpoint "$ServerBaseUrl/api/quizzes"
Test-Endpoint "$AuthBaseUrl/healthz"
Test-Endpoint "$AuthBaseUrl/readyz"
Test-Endpoint "$AuthBaseUrl/metrics"
Test-Endpoint "$AuthBaseUrl/api/leaderboard"
Test-Endpoint "$StorageBaseUrl/healthz"
Test-Endpoint "$StorageBaseUrl/readyz"
Test-Endpoint "$StorageBaseUrl/metrics"
Test-Endpoint "$StorageBaseUrl/api/storage/stats"
