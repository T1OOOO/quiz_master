param(
    [ValidateSet("auth", "storage")]
    [string]$Service = "storage",
    [string]$DbDriver = "",
    [string]$DbPath = "",
    [string]$DbDsn = "",
    [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Get-DefaultDbPath([string]$serviceName) {
    switch ($serviceName) {
        "auth" { return ".data/auth.db" }
        default { return ".data/storage.db" }
    }
}

if ($DbDriver -eq "") {
    switch ($Service) {
        "auth" { $DbDriver = if ($env:AUTH_DB_DRIVER) { $env:AUTH_DB_DRIVER } else { "sqlite" } }
        "storage" { $DbDriver = if ($env:STORAGE_DB_DRIVER) { $env:STORAGE_DB_DRIVER } else { "sqlite" } }
    }
}

if ($DbPath -eq "") {
    switch ($Service) {
        "auth" { $DbPath = if ($env:AUTH_DB_PATH) { $env:AUTH_DB_PATH } else { Get-DefaultDbPath $Service } }
        "storage" { $DbPath = if ($env:STORAGE_DB_PATH) { $env:STORAGE_DB_PATH } else { Get-DefaultDbPath $Service } }
    }
}

if ($DbDsn -eq "") {
    switch ($Service) {
        "auth" { $DbDsn = $env:AUTH_DB_DSN }
        "storage" { $DbDsn = $env:STORAGE_DB_DSN }
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ($Output -eq "") {
    $ext = if ($DbDriver -eq "postgres") { "sql" } else { "db" }
    $Output = Join-Path ".backup" "$Service-$stamp.$ext"
}

$outputDir = Split-Path -Parent $Output
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

switch ($DbDriver) {
    "postgres" {
        if ($DbDsn -eq "") {
            throw "DbDsn is required for postgres backups"
        }
        & pg_dump --dbname=$DbDsn --file=$Output --format=plain --no-owner --no-privileges
    }
    default {
        if (-not (Test-Path $DbPath)) {
            throw "SQLite database not found: $DbPath"
        }
        Copy-Item -LiteralPath $DbPath -Destination $Output -Force
    }
}

Write-Host "Backup created:" $Output
