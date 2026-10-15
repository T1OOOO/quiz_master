$ErrorActionPreference='Stop'
$quizCaptured = Get-Content -LiteralPath C:/ap/quiz_master/.run/actor_articles_20261015/published-browser-owned-processes.json -Raw | ConvertFrom-Json
$quizStillOwned = @()
$quizReused = @()
foreach ($quizEntry in $quizCaptured) {
 $quizNow = Get-CimInstance Win32_Process -Filter "ProcessId=$($quizEntry.ProcessId)"
 if ($null -eq $quizNow) { continue }
 if ($quizNow.Name -eq $quizEntry.Name -and $quizNow.CreationDate -eq [datetime]$quizEntry.CreationDate -and $quizNow.CommandLine -eq $quizEntry.CommandLine) { $quizStillOwned += $quizEntry.ProcessId } else { $quizReused += $quizEntry.ProcessId }
}
if ($quizStillOwned.Count -gt 0) { throw "Captured browser identities still running: $quizStillOwned" }
@{actual_exit=0;captured_browser_identities_absent=$true;checked=$quizCaptured.Count;reused_pids_preserved=$quizReused;foreign_processes_changed=$false;session='actors-published-mixed';method='Read-only native PID/name/creation/command-line check after official close; no process stop.'} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath C:/ap/quiz_master/docs/rewrite-agents/tasks/ACTOR_ARTICLES_20261015/published-browser/cleanup.json -Encoding utf8
Write-Output 'PASS: captured browser identities absent; reused PIDs preserved.'
