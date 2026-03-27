param(
    [ValidateSet("init", "reset", "path")]
    [string]$Action = "init",
    [string]$DbPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$args = @("./cmd/dbtool", "-action", $Action)
if ($DbPath -ne "") {
    $args += @("-db", $DbPath)
}

go run $args
