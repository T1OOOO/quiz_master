[CmdletBinding()]
param(
  [string]$ProjectName = "qm-p07-$([guid]::NewGuid().ToString('N').Substring(0, 12))"
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\\..')).Path
$compose = Join-Path $PSScriptRoot 'compose.yml'
$logs = Join-Path $PSScriptRoot 'validation-logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$started = Get-Date

function Invoke-Recorded([string]$Name, [scriptblock]$Command) {
  $path = Join-Path $logs "$Name.txt"
  "cwd=$root" | Set-Content -Path $path
  "started=$((Get-Date).ToString('o'))" | Add-Content -Path $path
  try {
    & $Command *>&1 | Tee-Object -FilePath $path -Append
    "exit=0" | Add-Content -Path $path
  } catch {
    $_ | Out-String | Tee-Object -FilePath $path -Append
    "exit=1" | Add-Content -Path $path
    throw
  }
}

Push-Location $root
try {
  $dockerfiles = Get-ChildItem (Join-Path $root 'next/infra') -Recurse -Filter Dockerfile
  $badFrom = $dockerfiles | Select-String '^FROM\s+(?!.*@sha256:[0-9a-f]{64})'
  $badImages = Select-String -Path $compose '^\s*image:\s+(?!.*@sha256:[0-9a-f]{64})'
  $workflow = Join-Path $root '.github/workflows/quiz-v2-ci.yml'
  $badActions = Select-String -Path $workflow '^\s*uses:\s+(?!.*@[0-9a-f]{40}\s*$)'
  if ($badFrom -or $badImages -or $badActions) { throw 'immutable pin check failed' }
  Invoke-Recorded '01-pins-and-config' { docker compose --project-name $ProjectName -f $compose config }
  Invoke-Recorded '02-build' { docker compose --project-name $ProjectName -f $compose build --pull }
  Invoke-Recorded '03-up' { docker compose --project-name $ProjectName -f $compose up --wait }
  $port = (docker compose --project-name $ProjectName -f $compose port api 8080).Trim().Split(':')[-1]
  Invoke-Recorded '04-live' { Invoke-WebRequest "http://127.0.0.1:$port/health/live" -UseBasicParsing }
  Invoke-Recorded '05-ready' { Invoke-WebRequest "http://127.0.0.1:$port/health/ready" -UseBasicParsing }
  Invoke-Recorded '06-logs' { docker compose --project-name $ProjectName -f $compose logs --no-color }
} finally {
  Invoke-Recorded '07-down' { docker compose --project-name $ProjectName -f $compose down --volumes --remove-orphans }
  Invoke-Recorded '08-cleanup-proof' { docker volume ls --filter "label=com.docker.compose.project=$ProjectName" }
  Pop-Location
  "project=$ProjectName" | Set-Content (Join-Path $logs 'run.txt')
  "duration=$(((Get-Date) - $started).TotalSeconds.ToString('F3'))s" | Add-Content (Join-Path $logs 'run.txt')
}
