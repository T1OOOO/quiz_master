$ErrorActionPreference = 'Stop'
$quizChecked = @(2044,2568,6264,22040,26252,27900,29248,29836,33748,38724,41148,41284,41948,43840,44464,51260,51820)
foreach ($quizPid in $quizChecked) {
 if (Get-Process -Id $quizPid -ErrorAction SilentlyContinue) { throw "Captured owned PID remains or was reused; inspect identity before any action: $quizPid" }
}
$quizListeners = @(Get-NetTCPConnection -LocalPort 19090,19093 -State Listen -ErrorAction SilentlyContinue)
if ($quizListeners.Count -ne 0) { throw 'QA ports still have listeners; preserve unrelated resources' }
Write-Output 'PASS: captured owned PIDs absent;19090/19093 have0listeners. No process changed by this check.'
