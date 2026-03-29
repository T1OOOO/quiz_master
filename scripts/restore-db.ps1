param(
    [ValidateSet("auth", "storage")]
    [string]$Service = "storage",
    [string]$DbDriver = "",
    [string]$DbPath = "",
    [string]$DbDsn = "",
    [Parameter(Mandatory = $true)]
    [string]$Input
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path $Input)) {
    throw "Input backup not found: $Input"
}

if ($DbDriver -eq "") {
    switch ($Service) {
        "auth" { $DbDriver = if ($env:AUTH_DB_DRIVER) { $env:AUTH_DB_DRIVER } else { "sqlite" } }
        "storage" { $DbDriver = if ($env:STORAGE_DB_DRIVER) { $env:STORAGE_DB_DRIVER } else { "sqlite" } }
    }
}

if ($DbPath -eq "") {
    switch ($Service) {
        "auth" { $DbPath = if ($env:AUTH_DB_PATH) { $env:AUTH_DB_PATH } else { ".data/auth.db" } }
        "storage" { $DbPath = if ($env:STORAGE_DB_PATH) { $env:STORAGE_DB_PATH } else { ".data/storage.db" } }
    }
}

if ($DbDsn -eq "") {
    switch ($Service) {
        "auth" { $DbDsn = $env:AUTH_DB_DSN }
        "storage" { $DbDsn = $env:STORAGE_DB_DSN }
    }
}

switch ($DbDriver) {
    "postgres" {
        if ($DbDsn -eq "") {
            throw "DbDsn is required for postgres restore"
        }
        Get-Content -LiteralPath $Input | & psql $DbDsn
    }
    default {
        $targetDir = Split-Path -Parent $DbPath
        if ($targetDir -and -not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $Input -Destination $DbPath -Force
    }
}

Write-Host "Restore complete for" $Service
