$ErrorActionPreference = 'Stop'
Write-Output ('UTC: ' + (Get-Date).ToUniversalTime().ToString('o'))
Write-Output 'Named owned browser session: library-09b19cc-local-mixed; namespace quiz-master'
foreach ($quizCheckedPid in @(37584,49136)) {
  Write-Output ("Native tasklist query: PID eq " + $quizCheckedPid)
  & tasklist.exe /FI ("PID eq " + $quizCheckedPid) /FO CSV
  if ($LASTEXITCODE -ne 0) { throw 'Native tasklist query failed' }
  if (Get-Process -Id $quizCheckedPid -ErrorAction SilentlyContinue) { throw 'Expected previous owned process PID still exists; inspect identity, never stop a replacement' }
}
Write-Output 'Native TCP listener query: local ports 19090,19093'
$quizListeners = @(Get-NetTCPConnection -LocalPort 19090,19093 -State Listen -ErrorAction SilentlyContinue)
$quizListeners | Select-Object LocalAddress,LocalPort,State,OwningProcess | Format-Table -AutoSize
if ($quizListeners.Count -ne 0) { throw 'QA ports have listeners; do not alter foreign resources' }
Write-Output 'Observed native listener count: 0'
Write-Output 'PASS: queried PIDs absent and QA ports have no TCP listeners; no process or resource was changed'
