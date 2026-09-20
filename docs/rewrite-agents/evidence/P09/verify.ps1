param([Parameter(Mandatory=$true)][string]$DatabaseURL,[switch]$ResumeContent)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
Set-Location $root
$checks=[System.Collections.Generic.List[object]]::new()
if($ResumeContent){foreach($check in (Get-Content -Raw (Join-Path $PSScriptRoot 'checks.json')|ConvertFrom-Json)){$checks.Add($check)}}
function Run-Check([string]$Name,[string]$Program,[string[]]$Arguments,[int]$Expected=0) {
 $watch=[System.Diagnostics.Stopwatch]::StartNew()
 $ErrorActionPreference='Continue'
 $output=(& $Program @Arguments 2>&1 | Out-String)
 $exit=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 $watch.Stop()
 $passes=0
 foreach($line in ($output -split "`n")){if($line.StartsWith('{')){try{$event=$line|ConvertFrom-Json;if($event.Action -eq 'pass' -and $event.Test){$passes++}}catch{}}}
 $checks.Add([ordered]@{name=$Name;command=(@($Program)+$Arguments);cwd=$root;duration_seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);exit=$exit;expected_exit=$Expected;test_pass_events=$passes;output=$output})
 [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'checks.json'),($checks|ConvertTo-Json -Depth 12))
 Write-Output "$Name : exit=$exit duration=$([Math]::Round($watch.Elapsed.TotalSeconds,3))s test_pass_events=$passes"
 if($exit -ne $Expected){throw "$Name failed; see checks.json"}
}
$env:QM_TEST_DATABASE_URL=$DatabaseURL
$env:QM_P09_RESPONSE_CAPTURE=Join-Path $PSScriptRoot 'public-responses.json'
if(-not $ResumeContent){
Run-Check 'full-go-suite' 'go' @('test','-p=1','-count=1','-json','./...')
Run-Check 'server-vet' 'go' @('vet','-p=1','./next/server/...')
Run-Check 'postgres-foundation' 'go' @('test','-p=1','-count=1','-json','-tags','integration','./next/server/internal/migrate','./next/server/internal/identity','./next/server/internal/store')
Run-Check 'postgres-attempts-http-e2e' 'go' @('test','-p=1','-count=1','-json','-tags','integration','./next/server/internal/attempts','./next/server/internal/httpapi')
Run-Check 'accepted-contract' 'python' @('-B','next/contracts/quiz-contract/v1/check_contract.py')
}
Run-Check 'accepted-p08-independent-verifier' 'python' @('-B','docs/rewrite-agents/evidence/P09/verify_content.py')
Run-Check 'race-runner-capability' 'go' @('env','CGO_ENABLED')
$files=@(Get-ChildItem next/server/internal/attempts -File -Recurse)
$files+=@(Get-Item next/server/internal/migrate/migrations/0002_attempts.sql,next/server/internal/migrate/runner.go,next/server/internal/migrate/runner_integration_test.go,next/server/internal/identity/service_integration_test.go)
foreach($directory in @('next/server/internal/config','next/server/internal/httpapi','next/server/cmd/api')){$files+=@(Get-ChildItem $directory -File -Recurse)}
$hashes=[ordered]@{}
foreach($file in ($files|Sort-Object FullName)){$relative=$file.FullName.Substring($root.Length+1).Replace('\','/');$hashes[$relative]=(Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'source-hashes.json'),($hashes|ConvertTo-Json -Depth 5))
Remove-Item Env:QM_TEST_DATABASE_URL
Remove-Item Env:QM_P09_RESPONSE_CAPTURE
