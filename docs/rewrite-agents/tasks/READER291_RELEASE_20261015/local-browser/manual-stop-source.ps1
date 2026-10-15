$ErrorActionPreference = 'Stop'
$quizWork = 'C:/ap/quiz_master/.run/reader291_release_20261015'
$quizCaptured = Get-Content "$quizWork/browser-owned-processes.json" -Raw | ConvertFrom-Json
$quizInfo = Get-Content "$quizWork/browser-session-info.json" -Raw | ConvertFrom-Json
if ($quizInfo.data.session -ne 'reader291-local-mixed' -or $quizInfo.data.namespace -ne 'quiz-master') { throw 'Wrong owned session' }
$quizRoot = @($quizCaptured | Where-Object { $_.ProcessId -eq $quizInfo.data.pid })
if ($quizRoot.Count -ne 1) { throw 'Missing captured daemon identity' }
$quizProcesses = @(Get-CimInstance Win32_Process)
$quizCurrentRoot = @($quizProcesses | Where-Object { $_.ProcessId -eq $quizRoot[0].ProcessId })
if ($quizRoot[0].ProcessId -is [array]) { throw 'Captured daemon was not a scalar identity' }
$quizSavedTime = ([datetimeoffset]$quizRoot[0].CreationDate).UtcDateTime
if ($quizCurrentRoot.Count -ne 1 -or $quizCurrentRoot[0].Name -ne $quizRoot[0].Name -or $quizCurrentRoot[0].CommandLine -ne $quizRoot[0].CommandLine -or $quizCurrentRoot[0].CreationDate.ToUniversalTime() -ne $quizSavedTime) { throw 'Owned daemon identity changed' }
$quizPids = @($quizRoot[0].ProcessId)
do {
    $quizMore = @($quizProcesses | Where-Object { $_.ParentProcessId -in $quizPids -and $_.ProcessId -notin $quizPids })
    $quizPids += @($quizMore.ProcessId)
} while ($quizMore.Count -gt 0)
$quizOwned = @($quizProcesses | Where-Object { $_.ProcessId -in $quizPids })
if (@($quizOwned | Where-Object { $_.Name -notin @('agent-browser-win32-x64.exe','chrome.exe') }).Count -ne 0) { throw 'Unexpected descendant process type' }
$quizOwned | Select-Object ProcessId,ParentProcessId,Name,CreationDate,CommandLine | ConvertTo-Json -Depth 3 | Set-Content "$quizWork/browser-cleanup-owned-identities.json"
foreach ($quizIdentity in @($quizOwned | Sort-Object ProcessId -Descending)) {
    $quizLive = Get-CimInstance Win32_Process -Filter "ProcessId = $($quizIdentity.ProcessId)"
    if ($quizLive) {
        if ($quizLive.CreationDate -ne $quizIdentity.CreationDate -or $quizLive.CommandLine -ne $quizIdentity.CommandLine) { throw 'Process identity changed before stop' }
        Stop-Process -Id $quizIdentity.ProcessId -ErrorAction Stop
    }
}
foreach ($quizIdentity in $quizOwned) {
    if (Get-Process -Id $quizIdentity.ProcessId -ErrorAction SilentlyContinue) { throw 'Owned process still present or PID reused; inspect' }
}
if (@(Get-NetTCPConnection -LocalPort 19090,19093 -State Listen -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Owned QA listener remains' }
[pscustomobject]@{ actual_exit = 0; method = 'Official named close failed twice; stopped only same-creation-time descendants of captured official-session daemon'; session = 'reader291-local-mixed'; namespace = 'quiz-master'; captured_daemon = $quizRoot[0].ProcessId; checked_processes = $quizPids; captured_identities_absent = $true; foreign_processes_changed = $false; ports_closed = @(19090,19093) } | ConvertTo-Json -Depth 3 | Set-Content "$quizWork/browser-fallback-cleanup.json"
Write-Output "PASS: bounded owned browser tree stopped and verified; QA ports closed."
