$ErrorActionPreference = 'Stop'
$quizChecked = @(7368,7900,11508,27100,29964,30076,33336,36816,41408,42068,42752,43848,45732,48068)
foreach ($quizPid in $quizChecked) { if (Get-Process -Id $quizPid -ErrorAction SilentlyContinue) { throw 'Captured PID remains or reused; inspect before action' } }
if (@(Get-NetTCPConnection -LocalPort 19090,19093 -State Listen -ErrorAction SilentlyContinue).Count -gt 0) { throw 'QA ports occupied' }
Write-Output 'PASS: captured owned PIDs absent;19090/19093 have0listeners. No process changed by this check.'
