$ErrorActionPreference = 'Stop'
$quizPidPath = 'C:/Users/Alexey_Matvienko/.agent-browser/namespaces/quiz-master/run/actors-published-mixed.pid'
$quizDaemonPid = [int](Get-Content -LiteralPath $quizPidPath -Raw).Trim()
$quizProcesses = @(Get-CimInstance Win32_Process)
$quizDaemon = $quizProcesses | Where-Object ProcessId -EQ $quizDaemonPid
if ($quizDaemon.Name -ne 'agent-browser-win32-x64.exe') { throw 'Owned session pidfile does not name the browser daemon' }
$quizOwned = @($quizDaemon)
$quizFrontier = @($quizDaemonPid)
while ($quizFrontier.Count -gt 0) {
 $quizChildren = @($quizProcesses | Where-Object { $_.ParentProcessId -in $quizFrontier })
 $quizOwned += $quizChildren
 $quizFrontier = @($quizChildren | ForEach-Object ProcessId)
}
$quizChrome = @($quizOwned | Where-Object { $_.Name -eq 'chrome.exe' -and $_.ParentProcessId -eq $quizDaemonPid })
if ($quizChrome.Count -ne 1 -or $quizChrome[0].CommandLine -notlike '*agent-browser-chrome-*') { throw 'Expected one owned private Chrome root' }
$quizOwned | Select-Object ProcessId,ParentProcessId,Name,CreationDate,CommandLine | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath C:/ap/quiz_master/.run/actor_articles_20261015/published-browser-owned-processes.json -Encoding utf8
Write-Output "Captured only named reader06 browser daemon and descendants: $($quizOwned.Count) processes"
