$ErrorActionPreference='Stop'
$quizChecked=@(2028,9112,10192,11328,11608,13676,16596,18532,27536,30368,33800,34032,49204,50732,51500)
foreach ($quizPid in $quizChecked) { if (Get-Process -Id $quizPid -ErrorAction SilentlyContinue) { throw 'Captured PID remains or reused; inspect before action' } }
if (@(Get-NetTCPConnection -LocalPort 19090,19093 -State Listen -ErrorAction SilentlyContinue).Count -gt 0) { throw 'QA ports occupied' }
Write-Output 'PASS: captured owned PIDs absent;19090/19093 have0listeners. No process changed.'
