$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell7 required'}
$r=Get-Content -Raw -LiteralPath 'C:/ap/quiz_master/.run/reader303_release_20261015/published-browser/identities-private.json'|ConvertFrom-Json
$row=@($r.rows|Where-Object{$_.pid -eq 55564 -and $_.name -eq 'agent-browser-win32-x64.exe'})
if($row.Count -ne 1){throw 'Captured named daemon required'};$row=$row[0]
$owner=[int](Get-Content -Raw -LiteralPath 'C:/Users/Alexey_Matvienko/.agent-browser/namespaces/quiz-master/run/reader303-published.pid').Trim()
if($owner -ne $row.pid){throw 'Named session owner differs'}
$p=Get-CimInstance Win32_Process -Filter 'ProcessId=55564';$n=[Diagnostics.Process]::GetProcessById(55564)
if($n.HasExited){throw 'Already exited; do not kill'}
if($p.Name -ne $row.name -or [string]$p.CommandLine -ne $row.command -or [string]$p.CreationDate.ToUniversalTime().Ticks -ne $row.cim_ticks -or [string]$n.StartTime.ToUniversalTime().Ticks -ne $row.native_ticks){throw 'Exact original identity differs; do not kill'}
$n.Kill();if(-not $n.WaitForExit(10000)){throw 'Owned daemon not quiescent'}
@{actual_exit=0;pid=55564;session='reader303-published';namespace='quiz-master';named_pidfile_verified=$true;full_command_verified=$true;cim_ticks_compared_only_to_cim_ticks=$true;native_ticks_compared_only_to_native_ticks=$true;native_has_exited=$n.HasExited;other_processes_changed=$false}|ConvertTo-Json|Set-Content -LiteralPath 'C:/ap/quiz_master/docs/rewrite-agents/tasks/READER303_RELEASE_20261015/published-browser/exact-daemon-cleanup.json' -Encoding utf8
Write-Output 'Exact captured named daemon stopped; no other process targeted'
